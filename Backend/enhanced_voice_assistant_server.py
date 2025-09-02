from flask import Flask, request, jsonify
from flask_cors import CORS
import pickle
import numpy as np
import re
import requests
import json
from tensorflow.keras.models import load_model
from tensorflow.keras.preprocessing.sequence import pad_sequences
from transformers import AutoTokenizer, AutoModelForCausalLM, pipeline
import spacy
import os
from decimal import Decimal

app = Flask(__name__)
CORS(app)  # Enable CORS for Flutter app

# Load intent classification model and preprocessors
print("Loading intent classification model...")
try:
    intent_model = load_model('Intent_classifier/intent_model.h5')
    
    with open('Intent_classifier/tokenizer.pkl', 'rb') as f:
        tokenizer = pickle.load(f)
    
    with open('Intent_classifier/label_encoder.pkl', 'rb') as f:
        label_encoder = pickle.load(f)
    
    with open('Intent_classifier/max_len.pkl', 'rb') as f:
        max_len = pickle.load(f)
    
    print("Intent classification model loaded successfully!")
    
except Exception as e:
    print(f"Error loading intent classification files: {e}")
    exit(1)

# Load GPT chatbot model
print("Loading GPT chatbot model...")
try:
    chatbot_model_path = "gpt/models/tiny_transformer_chatbot"
    chatbot_model = AutoModelForCausalLM.from_pretrained(chatbot_model_path)
    chatbot_tokenizer = AutoTokenizer.from_pretrained(chatbot_model_path)
    
    # Create text generation pipeline
    chatbot_generator = pipeline(
        "text-generation",
        model=chatbot_model,
        tokenizer=chatbot_tokenizer,
        max_length=128,
        pad_token_id=chatbot_tokenizer.eos_token_id,
    )
    
    print("GPT chatbot model loaded successfully!")
    
except Exception as e:
    print(f"Error loading GPT chatbot model: {e}")
    exit(1)

# Load NER model for entity extraction
print("Loading NER model...")
try:
    ner_model_path = os.path.join(os.path.dirname(__file__), 'keyword_ner_model')
    if os.path.exists(ner_model_path):
        nlp = spacy.load(ner_model_path)
        print("NER model loaded successfully!")
    else:
        print("NER model not found, using fallback entity extraction")
        nlp = None
except Exception as e:
    print(f"Error loading NER model: {e}")
    nlp = None

# Django backend configuration
DJANGO_BASE_URL = "http://localhost:8000/accounts"  # Adjust as needed

def preprocess_text(text):
    """Clean and preprocess text for prediction"""
    text = text.lower()
    text = re.sub(r'[^\w\s]', '', text)
    text = re.sub(r'\s+', ' ', text).strip()
    return text

def predict_intent(text):
    """Predict intent from text input"""
    try:
        clean_text = preprocess_text(text)
        sequence = tokenizer.texts_to_sequences([clean_text])
        padded_sequence = pad_sequences(sequence, maxlen=max_len, padding='post')
        
        prediction_probs = intent_model.predict(padded_sequence, verbose=0)
        predicted_class_index = np.argmax(prediction_probs, axis=1)[0]
        predicted_intent = label_encoder.inverse_transform([predicted_class_index])[0]
        confidence = float(prediction_probs[0][predicted_class_index])
        
        return predicted_intent, confidence
        
    except Exception as e:
        print(f"Error in intent prediction: {e}")
        return "error", 0.0

def extract_entities(text, intent):
    """Extract entities based on intent using multiple methods"""
    entities = {}
    text_lower = text.lower()
    
    if intent in ['transfer_money', 'request_money']:
        # Extract amount
        amount_pattern = r'(?:rs\.?|rupees?|₹)?\s*(\d+(?:\.\d{2})?)\s*(?:rs\.?|rupees?|₹)?'
        amount_match = re.search(amount_pattern, text_lower)
        if amount_match:
            entities['amount'] = float(amount_match.group(1))
        
        # Extract phone number
        phone_pattern = r'(?:phone\s+)?(?:number\s+)?(?:mobile\s+)?(\d{10}|\d{11}|\+91\d{10})'
        phone_match = re.search(phone_pattern, text_lower)
        if phone_match:
            phone = phone_match.group(1)
            if not phone.startswith('+91'):
                phone = '+91' + phone.lstrip('0')[-10:]  # Get last 10 digits
            entities['phone_number'] = phone
        
        # Extract UPI ID
        upi_pattern = r'([a-zA-Z0-9._-]+@[a-zA-Z]+)'
        upi_match = re.search(upi_pattern, text)
        if upi_match:
            entities['upi_id'] = upi_match.group(1)
        
        # Extract recipient name (words that could be names)
        name_patterns = [
            r'(?:to|send|pay|give)\s+([a-zA-Z]+(?:\s+[a-zA-Z]+)?)',
            r'([a-zA-Z]+)\s+(?:rs\.|rupees|₹|\d+)',
            r'(?:request\s+(?:from\s+)?|ask\s+)([a-zA-Z]+(?:\s+[a-zA-Z]+)?)'
        ]
        
        for pattern in name_patterns:
            name_match = re.search(pattern, text_lower)
            if name_match:
                potential_name = name_match.group(1).strip()
                # Filter out common words
                if potential_name not in ['money', 'cash', 'amount', 'payment', 'the', 'my', 'his', 'her']:
                    entities['recipient_name'] = potential_name.title()
                    break
    
    # Use NER model if available
    if nlp:
        doc = nlp(text)
        ner_entities = [ent.text for ent in doc.ents]
        if ner_entities:
            entities['ner_keywords'] = ner_entities
    
    return entities

def get_chatbot_response(prompt):
    """Get response from trained GPT chatbot"""
    try:
        full_prompt = f"User: {prompt.strip()}\nAssistant:"
        response = chatbot_generator(full_prompt, num_return_sequences=1)[0]["generated_text"]
        
        # Extract only the assistant's response
        response_lines = response.split('\n')
        assistant_response = ""
        found_assistant = False
        
        for line in response_lines:
            if found_assistant:
                if line.strip() == "" or line.strip().startswith("User:"):
                    break
                assistant_response += " " + line.strip()
            elif line.strip().startswith("Assistant:"):
                assistant_response = line.replace("Assistant:", "", 1).strip()
                found_assistant = True
        
        return assistant_response if assistant_response else "I'm here to help you with your UPI transactions!"
        
    except Exception as e:
        print(f"Error in chatbot response: {e}")
        return "I'm sorry, I'm having trouble processing that right now."

def call_django_api(endpoint, method='GET', data=None, params=None):
    """Make API calls to Django backend"""
    try:
        url = f"{DJANGO_BASE_URL}/{endpoint}/"
        
        if method == 'GET':
            response = requests.get(url, params=params)
        elif method == 'POST':
            response = requests.post(url, json=data)
        
        if response.status_code == 200:
            return response.json()
        else:
            return {"error": f"API call failed: {response.status_code}", "status": "error"}
            
    except Exception as e:
        return {"error": f"Connection error: {str(e)}", "status": "error"}

def process_transfer_money(entities, user_phone):
    """Process money transfer request"""
    if 'amount' not in entities:
        return {"error": "Amount not specified", "status": "error"}
    
    amount = entities['amount']
    
    # Check if UPI ID is provided
    if 'upi_id' in entities:
        data = {
            'senderPhone': user_phone,
            'receiverUpi': entities['upi_id'],
            'amount': amount
        }
        return call_django_api('sendMoneyId', method='POST', data=data)
    
    # Check if phone number is provided
    elif 'phone_number' in entities:
        data = {
            'senderPhone': user_phone,
            'receiverPhone': entities['phone_number'],
            'amount': amount
        }
        return call_django_api('sendMoneyPhone', method='POST', data=data)
    
    # If only name is provided, search for user
    elif 'recipient_name' in entities:
        # First try to find user by name (this would need additional Django endpoint)
        return {
            "error": f"Cannot find contact details for {entities['recipient_name']}. Please provide phone number or UPI ID.",
            "status": "error",
            "suggestion": f"Try saying: 'Send ₹{amount} to {entities['recipient_name']} at [phone number/UPI ID]'"
        }
    
    else:
        return {
            "error": "Recipient not specified. Please provide phone number or UPI ID.",
            "status": "error"
        }

def process_request_money(entities, user_phone):
    """Process money request"""
    if 'amount' not in entities:
        return {"error": "Amount not specified", "status": "error"}
    
    amount = entities['amount']
    message = f"Payment request for ₹{amount}"
    
    # Check if UPI ID is provided
    if 'upi_id' in entities:
        data = {
            'requesterPhone': user_phone,
            'requesteeUpi': entities['upi_id'],
            'amount': amount,
            'message': message
        }
        return call_django_api('createMoneyRequestByUpi', method='POST', data=data)
    
    # Check if phone number is provided
    elif 'phone_number' in entities:
        data = {
            'requesterPhone': user_phone,
            'requesteePhone': entities['phone_number'],
            'amount': amount,
            'message': message
        }
        return call_django_api('createMoneyRequest', method='POST', data=data)
    
    # If only name is provided
    elif 'recipient_name' in entities:
        return {
            "error": f"Cannot find contact details for {entities['recipient_name']}. Please provide phone number or UPI ID.",
            "status": "error",
            "suggestion": f"Try saying: 'Request ₹{amount} from {entities['recipient_name']} at [phone number/UPI ID]'"
        }
    
    else:
        return {
            "error": "Recipient not specified. Please provide phone number or UPI ID.",
            "status": "error"
        }

def process_check_balance(user_phone):
    """Process balance check request"""
    params = {'phoneNumber': user_phone}
    return call_django_api('getBalance', params=params)

@app.route('/')
def home():
    return jsonify({
        "message": "Enhanced Voice Assistant API is running!",
        "endpoints": {
            "/voice_command": "POST - Process complete voice commands",
            "/health": "GET - Check server health"
        }
    })

@app.route('/health')
def health():
    return jsonify({"status": "healthy", "message": "Enhanced Voice Assistant Server is running"})

@app.route('/voice_command', methods=['POST'])
def process_voice_command():
    """Main endpoint for processing voice commands"""
    try:
        data = request.json
        
        if not data or 'text' not in data:
            return jsonify({
                "error": "No text provided",
                "message": "Please send JSON with 'text' field"
            }), 400
        
        text = data['text']
        user_phone = data.get('userPhone', '+919999999999')  # Default for testing
        
        if not text or text.strip() == "":
            return jsonify({
                "error": "Empty text",
                "message": "Text cannot be empty"
            }), 400
        
        # Step 1: Intent Classification
        predicted_intent, confidence = predict_intent(text)
        
        response = {
            "input_text": text,
            "predicted_intent": predicted_intent,
            "confidence": round(confidence, 4),
            "status": "success"
        }
        
        # Step 2: Process based on intent
        if predicted_intent == 'transfer_money':
            # Extract entities and call Django backend
            entities = extract_entities(text, predicted_intent)
            django_response = process_transfer_money(entities, user_phone)
            
            response.update({
                "entities": entities,
                "django_response": django_response,
                "assistant_message": django_response.get('message', 'Transfer initiated') if django_response.get('status') == 'success' else django_response.get('error', 'Transfer failed')
            })
            
        elif predicted_intent == 'request_money':
            # Extract entities and call Django backend
            entities = extract_entities(text, predicted_intent)
            django_response = process_request_money(entities, user_phone)
            
            response.update({
                "entities": entities,
                "django_response": django_response,
                "assistant_message": django_response.get('message', 'Request sent') if django_response.get('status') == 'success' else django_response.get('error', 'Request failed')
            })
            
        elif predicted_intent == 'check_balance':
            # Call Django backend for balance
            django_response = process_check_balance(user_phone)
            
            if django_response.get('status') == 'success':
                balance = django_response.get('balance', '0')
                assistant_message = f"Your current balance is ₹{balance}"
            else:
                assistant_message = django_response.get('error', 'Unable to fetch balance')
            
            response.update({
                "django_response": django_response,
                "assistant_message": assistant_message
            })
            
        else:
            # For general/casual questions, use chatbot
            chatbot_response = get_chatbot_response(text)
            response.update({
                "assistant_message": chatbot_response,
                "source": "chatbot"
            })
        
        return jsonify(response)
        
    except Exception as e:
        return jsonify({
            "error": str(e),
            "status": "error"
        }), 500

# Legacy endpoints for backward compatibility
@app.route('/predict', methods=['POST'])
def predict():
    """Legacy intent prediction endpoint"""
    try:
        data = request.json
        if not data or 'text' not in data:
            return jsonify({"error": "No text provided"}), 400
        
        text = data['text']
        predicted_intent, confidence = predict_intent(text)
        entities = extract_entities(text, predicted_intent)
        
        return jsonify({
            "input_text": text,
            "predicted_intent": predicted_intent,
            "confidence": round(confidence, 4),
            "entities": entities,
            "status": "success"
        })
        
    except Exception as e:
        return jsonify({"error": str(e), "status": "error"}), 500

@app.route('/chatbot', methods=['POST'])
def chatbot():
    """Direct chatbot endpoint"""
    try:
        data = request.json
        if not data or 'text' not in data:
            return jsonify({"error": "No text provided"}), 400
        
        text = data['text']
        response = get_chatbot_response(text)
        
        return jsonify({
            "input_text": text,
            "response": response,
            "status": "success"
        })
        
    except Exception as e:
        return jsonify({"error": str(e), "status": "error"}), 500

if __name__ == '__main__':
    print("Starting Enhanced Voice Assistant Server...")
    print("Server will be available at: http://localhost:5002")
    print("Main endpoint: POST /voice_command")
    print("Legacy endpoints: POST /predict, POST /chatbot")
    app.run(host='0.0.0.0', port=5002, debug=True)
