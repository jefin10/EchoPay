from flask import Flask, request, jsonify
from flask_cors import CORS
import pickle
import numpy as np
import re
import requests
from tensorflow.keras.models import load_model
from tensorflow.keras.preprocessing.sequence import pad_sequences
from transformers import AutoTokenizer, AutoModelForCausalLM, pipeline
import spacy
import os

app = Flask(__name__)
CORS(app)  # Enable CORS for Flutter app

# Django backend configuration
DJANGO_BASE_URL = "http://172.16.192.54:8000/accounts"  # For physical device on same network

# Load intent classification model and preprocessors
print("Loading intent classification model...")
try:
    model = load_model('intent_model.h5')
    
    with open('tokenizer.pkl', 'rb') as f:
        tokenizer = pickle.load(f)
    
    with open('label_encoder.pkl', 'rb') as f:
        label_encoder = pickle.load(f)
    
    with open('max_len.pkl', 'rb') as f:
        max_len = pickle.load(f)
    
    print("Intent classification model loaded successfully!")
    
except Exception as e:
    print(f"Error loading intent classification files: {e}")
    exit(1)

# Load GPT chatbot model
print("Loading GPT chatbot model...")
try:
    chatbot_model_path = "../gpt/models/tiny_transformer_chatbot"
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
    print("Continuing without chatbot functionality...")
    chatbot_generator = None

# Load NER model for entity extraction
print("Loading NER model...")
try:
    ner_model_path = os.path.join(os.path.dirname(__file__), '../keyword_ner_model')
    if os.path.exists(ner_model_path):
        nlp = spacy.load(ner_model_path)
        print("NER model loaded successfully!")
    else:
        print("NER model not found, using fallback entity extraction")
        nlp = None
except Exception as e:
    print(f"Error loading NER model: {e}")
    nlp = None

def preprocess_text(text):
    """Clean and preprocess text for prediction"""
    text = text.lower()  # Convert to lowercase
    text = re.sub(r'[^\w\s]', '', text)  # Remove punctuation
    text = re.sub(r'\s+', ' ', text).strip()  # Remove extra spaces
    return text

def extract_entities(text, intent):
    """Extract entities based on intent using multiple methods"""
    entities = {}
    text_lower = text.lower()
    
    if intent in ['transfer_money', 'request_money']:
        # Extract amount
        amount_patterns = [
            r'(?:rs\.?|rupees?|₹)?\s*(\d+(?:\.\d{2})?)\s*(?:rs\.?|rupees?|₹)?',
            r'(\d+)\s*(?:rupees?|rs\.?|₹)',
            r'₹\s*(\d+(?:\.\d{2})?)',
            r'(\d+)\s+rupees?'
        ]
        
        for pattern in amount_patterns:
            amount_match = re.search(pattern, text_lower)
            if amount_match:
                entities['amount'] = float(amount_match.group(1))
                break
        
        # Extract phone number
        phone_patterns = [
            r'(?:phone\s+)?(?:number\s+)?(?:mobile\s+)?(\d{10}|\d{11})',
            r'(\+91\d{10})',
            r'(?:to\s+|from\s+)?(\d{10})',
            r'number\s+(\d{10})'
        ]
        
        for pattern in phone_patterns:
            phone_match = re.search(pattern, text)
            if phone_match:
                phone = phone_match.group(1)
                if not phone.startswith('+91'):
                    phone = '+91' + phone.lstrip('0')[-10:]  # Get last 10 digits
                entities['phone_number'] = phone
                break
        
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
                if potential_name not in ['money', 'cash', 'amount', 'payment', 'the', 'my', 'his', 'her', 'upi', 'via']:
                    entities['recipient_name'] = potential_name.title()
                    break
    
    # Use NER model if available for additional keywords
    if nlp:
        try:
            doc = nlp(text)
            ner_entities = [ent.text for ent in doc.ents]
            if ner_entities:
                entities['ner_keywords'] = ner_entities
        except:
            pass
    
    return entities

def get_chatbot_response(prompt):
    """Get response from trained GPT chatbot"""
    if not chatbot_generator:
        return "I'm here to help you with UPI transactions! You can send money, check balance, or request payments."
    
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
        return "I'm here to help you with UPI transactions! You can send money, check balance, or request payments."

def call_django_api(endpoint, method='GET', data=None, params=None):
    """Make API calls to Django backend"""
    try:
        url = f"{DJANGO_BASE_URL}/{endpoint}/"
        
        if method == 'GET':
            response = requests.get(url, params=params, timeout=10)
        elif method == 'POST':
            response = requests.post(url, json=data, timeout=10)
        
        if response.status_code == 200:
            return response.json()
        else:
            return {"error": f"API call failed: {response.status_code}", "status": "error"}
            
    except requests.exceptions.RequestException as e:
        return {"error": f"Connection error: {str(e)}", "status": "error"}
    except Exception as e:
        return {"error": f"Unexpected error: {str(e)}", "status": "error"}

def process_transfer_money(entities, user_phone):
    """Process money transfer request"""
    if 'amount' not in entities:
        return {
            "error": "Amount not specified. Please mention the amount to transfer.",
            "status": "error",
            "suggestion": "Try saying: 'Send 500 rupees to [phone number/UPI ID]'"
        }
    
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
        return {
            "error": f"Cannot find contact details for {entities['recipient_name']}. Please provide phone number or UPI ID.",
            "status": "error",
            "suggestion": f"Try saying: 'Send ₹{amount} to {entities['recipient_name']} at [phone number/UPI ID]'"
        }
    
    else:
        return {
            "error": "Recipient not specified. Please provide phone number or UPI ID.",
            "status": "error",
            "suggestion": f"Try saying: 'Send ₹{amount} to [phone number/UPI ID]'"
        }

def process_request_money(entities, user_phone):
    """Process money request"""
    if 'amount' not in entities:
        return {
            "error": "Amount not specified. Please mention the amount to request.",
            "status": "error",
            "suggestion": "Try saying: 'Request 500 rupees from [phone number/UPI ID]'"
        }
    
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
            "status": "error",
            "suggestion": f"Try saying: 'Request ₹{amount} from [phone number/UPI ID]'"
        }

def process_check_balance(user_phone):
    """Process balance check request"""
    params = {'phoneNumber': user_phone}
    return call_django_api('getBalance', params=params)
    

def predict_intent(text):
    """Predict intent from text input"""
    try:
        # Preprocess text
        clean_text = preprocess_text(text)
        
        # Convert to sequence and pad
        sequence = tokenizer.texts_to_sequences([clean_text])
        padded_sequence = pad_sequences(sequence, maxlen=max_len, padding='post')
        
        # Get prediction
        prediction_probs = model.predict(padded_sequence, verbose=0)
        predicted_class_index = np.argmax(prediction_probs, axis=1)[0]
        predicted_intent = label_encoder.inverse_transform([predicted_class_index])[0]
        confidence = float(prediction_probs[0][predicted_class_index])
        
        return predicted_intent, confidence
        
    except Exception as e:
        print(f"Error in prediction: {e}")
        return "error", 0.0

@app.route('/')
def home():
    return jsonify({
        "message": "Enhanced Voice Assistant with Intent Classification and GPT Chatbot is running!",
        "endpoints": {
            "/voice_command": "POST - Complete voice command processing (recommended)",
            "/predict": "POST - Legacy intent prediction",
            "/health": "GET - Check server health"
        }
    })

@app.route('/health')
def health():
    return jsonify({
        "status": "healthy", 
        "message": "Enhanced Voice Assistant Server is running",
        "components": {
            "intent_classifier": "loaded",
            "chatbot": "loaded" if chatbot_generator else "not available",
            "ner_model": "loaded" if nlp else "not available",
            "django_backend": DJANGO_BASE_URL
        }
    })

@app.route('/voice_command', methods=['POST'])
def process_voice_command():
    """
    Main endpoint for processing complete voice commands
    This implements the workflow you specified:
    - transfer_money: intent classifier -> entity -> Django backend -> frontend
    - request_money: intent classifier -> entity -> Django backend -> frontend  
    - check_balance: intent classifier -> Django backend -> frontend
    - general questions: directly to chatbot
    """
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
        
        print(f"Processing voice command: {text}")
        
        # Step 1: Intent Classification
        predicted_intent, confidence = predict_intent(text)
        
        response = {
            "input_text": text,
            "predicted_intent": predicted_intent,
            "confidence": round(confidence, 4),
            "confidence_percentage": round(confidence * 100, 2),
            "status": "success"
        }
        
        # Step 2: Process based on intent following your specified workflow
        if predicted_intent == 'transfer_money':
            print("Processing transfer money request...")
            # Workflow: intent classifier -> entity -> Mock response (Django disabled)
            entities = extract_entities(text, predicted_intent)
            
            # MOCK RESPONSE - Django backend disabled for now
            if 'amount' in entities:
                django_response = {
                    'status': 'success',
                    'message': f'Mock: Transfer of ₹{entities["amount"]} initiated successfully!'
                }
                assistant_message = f'Ready to send ₹{entities["amount"]}'
                if 'recipient_name' in entities:
                    assistant_message += f' to {entities["recipient_name"]}'
                assistant_message += ' (Mock mode - Django disabled)'
            else:
                django_response = {
                    'status': 'error',
                    'error': 'Amount not specified',
                    'suggestion': 'Try saying: "Send 500 rupees to [name]"'
                }
                assistant_message = 'Amount not specified. Please mention the amount to transfer.'
            
            response.update({
                "entities": entities,
                "django_response": django_response,
                "assistant_message": assistant_message,
                "action": "transfer_money"
            })
            
        elif predicted_intent == 'request_money':
            print("Processing request money...")
            # Workflow: intent classifier -> entity -> Mock response (Django disabled)
            entities = extract_entities(text, predicted_intent)
            
            # MOCK RESPONSE - Django backend disabled for now
            if 'amount' in entities:
                django_response = {
                    'status': 'success',
                    'message': f'Mock: Money request for ₹{entities["amount"]} sent!'
                }
                assistant_message = f'Request for ₹{entities["amount"]}'
                if 'recipient_name' in entities:
                    assistant_message += f' from {entities["recipient_name"]}'
                assistant_message += ' sent (Mock mode - Django disabled)'
            else:
                django_response = {
                    'status': 'error',
                    'error': 'Amount not specified',
                    'suggestion': 'Try saying: "Request 500 from [name]"'
                }
                assistant_message = 'Amount not specified. Please mention the amount to request.'
            
            response.update({
                "entities": entities,
                "django_response": django_response,
                "assistant_message": assistant_message,
                "action": "request_money"
            })
            
        elif predicted_intent == 'check_balance':
            print("Processing balance check...")
            # MOCK RESPONSE - Django backend disabled for now
            django_response = {
                'status': 'success',
                'balance': '5000.00'
            }
            assistant_message = f"Your current balance is ₹5000.00 (Mock mode - Django disabled)"
            
            response.update({
                "django_response": django_response,
                "assistant_message": assistant_message,
                "action": "check_balance"
            })
            
        else:
            print(f"General/casual question detected, routing to chatbot...")
            # For normal/casual/generic questions not related to the above 3, directly pass to chatbot
            chatbot_response = get_chatbot_response(text)
            response.update({
                "assistant_message": chatbot_response,
                "source": "chatbot",
                "action": "general_conversation"
            })
        
        print(f"Response: {response}")
        return jsonify(response)
        
    except Exception as e:
        print(f"Error processing voice command: {e}")
        return jsonify({
            "error": str(e),
            "status": "error"
        }), 500

@app.route('/predict', methods=['POST'])
def predict():
    """Legacy endpoint for backward compatibility"""
    try:
        # Get text from request
        data = request.json
        
        if not data or 'text' not in data:
            return jsonify({
                "error": "No text provided",
                "message": "Please send JSON with 'text' field"
            }), 400
        
        text = data['text']
        
        if not text or text.strip() == "":
            return jsonify({
                "error": "Empty text",
                "message": "Text cannot be empty"
            }), 400
        
        # Get prediction
        predicted_intent, confidence = predict_intent(text)
        
        # Extract entities and keywords
        entities = extract_entities(text, predicted_intent)
        
        # Format response
        response = {
            "input_text": text,
            "predicted_intent": predicted_intent,
            "confidence": round(confidence, 4),
            "confidence_percentage": round(confidence * 100, 2),
            "status": "success"
        }
        
        # Return format similar to original for backward compatibility
        return jsonify([response, {"keywords": entities}])
        
    except Exception as e:
        return jsonify({
            "error": str(e),
            "status": "error"
        }), 500

@app.route('/chatbot', methods=['POST'])
def chatbot_endpoint():
    """Direct chatbot endpoint for testing"""
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

@app.route('/predict_batch', methods=['POST'])
def predict_batch():
    """Predict multiple texts at once"""
    try:
        data = request.json
        
        if not data or 'texts' not in data:
            return jsonify({
                "error": "No texts provided",
                "message": "Please send JSON with 'texts' array"
            }), 400
        
        texts = data['texts']
        
        if not isinstance(texts, list):
            return jsonify({
                "error": "Invalid format",
                "message": "texts should be an array"
            }), 400
        
        results = []
        for text in texts:
            predicted_intent, confidence = predict_intent(text)
            results.append({
                "input_text": text,
                "predicted_intent": predicted_intent,
                "confidence": round(confidence, 4),
                "confidence_percentage": round(confidence * 100, 2)
            })
        
        return jsonify({
            "results": results,
            "status": "success",
            "count": len(results)
        })
        
    except Exception as e:
        return jsonify({
            "error": str(e),
            "status": "error"
        }), 500

if __name__ == '__main__':
    print("=" * 60)
    print("🚀 Enhanced Voice Assistant Server Starting...")
    print("=" * 60)
    print("📊 Components Status:")
    print(f"   ✅ Intent Classifier: Loaded")
    print(f"   {'✅' if chatbot_generator else '❌'} GPT Chatbot: {'Loaded' if chatbot_generator else 'Not Available'}")
    print(f"   {'✅' if nlp else '❌'} NER Model: {'Loaded' if nlp else 'Not Available'}")
    print(f"   ⚠️  Django Backend: DISABLED (Mock mode)")
    print("=" * 60)
    print("🌐 Server will be available at: http://localhost:5002")
    print("📡 API endpoints:")
    print("   - POST /voice_command: Complete voice assistant (RECOMMENDED)")
    print("   - POST /predict: Legacy intent prediction")
    print("   - POST /chatbot: Direct chatbot access")
    print("   - GET  /health: Health check")
    print("=" * 60)
    print("🔄 Voice Assistant Workflow (MOCK MODE):")
    print("   💰 Transfer Money: Intent → Entity → Mock Response")
    print("   💸 Request Money: Intent → Entity → Mock Response")
    print("   💳 Check Balance: Intent → Mock Response (₹5000)")
    print("   💬 General Chat: Direct to GPT Chatbot")
    print("=" * 60)
    app.run(host='0.0.0.0', port=5002, debug=True)
