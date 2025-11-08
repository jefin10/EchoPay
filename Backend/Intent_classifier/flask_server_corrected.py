from flask import Flask, request, jsonify
from flask_cors import CORS
import pickle
import numpy as np
import re
from tensorflow.keras.models import load_model
from tensorflow.keras.preprocessing.sequence import pad_sequences
import spacy
import os

app = Flask(__name__)
CORS(app)  # Enable CORS for Flutter app

# Load model and preprocessors
print("Loading model and preprocessors...")
try:
    model = load_model('intent_model.h5')
    
    with open('tokenizer.pkl', 'rb') as f:
        tokenizer = pickle.load(f)
    
    with open('label_encoder.pkl', 'rb') as f:
        label_encoder = pickle.load(f)
    
    with open('max_len.pkl', 'rb') as f:
        max_len = pickle.load(f)
    
    print("All files loaded successfully!")
    
except Exception as e:
    print(f"Error loading files: {e}")
    exit(1)

def preprocess_text(text):
    """Clean and preprocess text for prediction"""
    text = text.lower()  # Convert to lowercase
    text = re.sub(r'[^\w\s]', '', text)  # Remove punctuation
    text = re.sub(r'\s+', ' ', text).strip()  # Remove extra spaces
    return text

def keyWordExtractor(text):
    """Extract keywords from text using keyword_ner_model"""
    try:
        # Load the NER model from keyword_ner_model directory
        model_path = os.path.join(os.path.dirname(__file__), '../keyword_ner_model')
        nlp = spacy.load(model_path)
        doc = nlp(text)
        keywords = {
            "amount": None,
            "recipient": None,
            "phone_number": None,
            "upi_id": None
        }
        
        for ent in doc.ents:
            if ent.label_ == "AMOUNT":
                keywords["amount"] = ent.text
            elif ent.label_ == "PERSON":
                keywords["recipient"] = ent.text
            elif ent.label_ == "PHONE":
                keywords["phone_number"] = ent.text
            elif ent.label_ == "UPI_ID":
                keywords["upi_id"] = ent.text
        
        return keywords
    except Exception as e:
        print(f"Error in keyword extraction: {e}")
        return {"amount": None, "recipient": None, "phone_number": None, "upi_id": None}

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
        "message": "VoiceUPI Intent Classification API is running!",
        "version": "1.0",
        "endpoints": {
            "/": "GET - Server info",
            "/health": "GET - Check server health",
            "/predict": "POST - Single text intent prediction with keyword extraction"
        }
    })

@app.route('/health')
def health():
    return jsonify({
        "status": "healthy", 
        "message": "Server is running",
        "model_loaded": model is not None
    })

@app.route('/predict', methods=['POST'])
def predict():
    """
    Predict intent and extract keywords from voice command
    
    Expected input:
    {
        "text": "send 1000 rs to jefin"
    }
    
    Returns:
    {
        "input_text": "send 1000 rs to jefin",
        "predicted_intent": "transfer_money",
        "confidence": 0.9876,
        "confidence_percentage": 98.76,
        "keywords": {
            "amount": "1000",
            "recipient": "jefin",
            "phone_number": null,
            "upi_id": null
        },
        "status": "success"
    }
    """
    try:
        print("Received prediction request...")
        
        # Get text from request
        data = request.json
        
        if not data or 'text' not in data:
            return jsonify({
                "error": "No text provided",
                "message": "Please send JSON with 'text' field",
                "status": "error"
            }), 400
        
        text = data['text']
        
        if not text or text.strip() == "":
            return jsonify({
                "error": "Empty text",
                "message": "Text cannot be empty",
                "status": "error"
            }), 400
        
        print(f"Processing text: {text}")
        
        # Get prediction
        predicted_intent, confidence = predict_intent(text)
        
        # Extract keywords
        keywords = keyWordExtractor(text) 
        print(f"Predicted Intent: {predicted_intent}")
        print(f"Confidence: {confidence}")
        print(f"Extracted Keywords: {keywords}")
        
        # Format response
        response = {
            "input_text": text,
            "predicted_intent": predicted_intent,
            "confidence": round(confidence, 4),
            "confidence_percentage": round(confidence * 100, 2),
            "keywords": keywords,
            "status": "success"
        }
        
        return jsonify(response)
        
    except Exception as e:
        print(f"Error in /predict endpoint: {e}")
        return jsonify({
            "error": str(e),
            "status": "error",
            "message": "Internal server error"
        }), 500

if __name__ == '__main__':
    print("=" * 60)
    print("Starting VoiceUPI Intent Classification Flask Server...")
    print("=" * 60)
    print("\nServer Configuration:")
    print(f"  - Host: 0.0.0.0")
    port = int(os.environ.get("PORT", 5000))
    print(f"  - Port: {port}")
    print("\nAvailable Endpoints:")
    print("  - GET  /         : Server information")
    print("  - GET  /health   : Health check")
    print("  - POST /predict  : Intent prediction with keyword extraction")
    print("\nExample Request:")
    print('  curl -X POST http://localhost:5000/predict \\')
    print('       -H "Content-Type: application/json" \\')
    print('       -d \'{"text": "send 1000 rs to jefin"}\'')
    print("\n" + "=" * 60)
    
    app.run(host='0.0.0.0', port=port, debug=True)
