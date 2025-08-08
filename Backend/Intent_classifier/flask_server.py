from flask import Flask, request, jsonify
from flask_cors import CORS
import pickle
import numpy as np
import re
from tensorflow.keras.models import load_model
from tensorflow.keras.preprocessing.sequence import pad_sequences

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
        "message": "Intent Classification API is running!",
        "endpoints": {
            "/predict": "POST - Send text to get intent prediction",
            "/health": "GET - Check server health"
        }
    })

@app.route('/health')
def health():
    return jsonify({"status": "healthy", "message": "Server is running"})

@app.route('/predict', methods=['POST'])
def predict():
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
        
        # Format response
        response = {
            "input_text": text,
            "predicted_intent": predicted_intent,
            "confidence": round(confidence, 4),
            "confidence_percentage": round(confidence * 100, 2),
            "status": "success"
        }
        
        return jsonify(response)
        
    except Exception as e:
        return jsonify({
            "error": str(e),
            "status": "error"
        }), 500

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
    print("Starting Intent Classification Flask Server...")
    print("Server will be available at: http://localhost:5000")
    print("API endpoints:")
    print("  - GET  /: Server info")
    print("  - GET  /health: Health check")
    print("  - POST /predict: Single text prediction")
    print("  - POST /predict_batch: Multiple text predictions")
    app.run(host='0.0.0.0', port=5002, debug=True)
