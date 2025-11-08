#!/usr/bin/env python3
"""
Voice UPI Intent Classification API
Lightweight Flask API for predicting user intents in voice-based UPI transactions
"""

from flask import Flask, request, jsonify
from flask_cors import CORS
import pickle
import re
import os
import logging

# Initialize Flask app
app = Flask(__name__)
CORS(app)  # Enable CORS for all routes

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Global model variable
model_pipeline = None

def load_model():
    """Load the trained model"""
    global model_pipeline
    try:
        model_path = 'voice_upi_intent_model.pkl'
        if not os.path.exists(model_path):
            logger.error(f"Model file not found: {model_path}")
            return False
        
        with open(model_path, 'rb') as f:
            model_pipeline = pickle.load(f)
        
        logger.info("Model loaded successfully!")
        return True
    except Exception as e:
        logger.error(f"Error loading model: {str(e)}")
        return False

def clean_text(text):
    """Clean and preprocess text data"""
    # Convert to lowercase
    text = text.lower()
    # Remove extra whitespace
    text = re.sub(r'\s+', ' ', text)
    # Remove leading/trailing whitespace
    text = text.strip()
    return text

def predict_intent(text):
    """Predict intent for given text"""
    if model_pipeline is None:
        raise ValueError("Model not loaded")
    
    cleaned_text = clean_text(text)
    prediction = model_pipeline.predict([cleaned_text])[0]
    confidence = max(model_pipeline.predict_proba([cleaned_text])[0])
    
    return {
        'intent': prediction,
        'confidence': float(confidence),
        'input_text': text,
        'cleaned_text': cleaned_text
    }

@app.route('/', methods=['GET'])
def home():
    """Health check endpoint"""
    return jsonify({
        'status': 'healthy',
        'message': 'Voice UPI Intent Classification API is running!',
        'version': '1.0.0',
        'model_loaded': model_pipeline is not None
    })

@app.route('/predict', methods=['POST'])
def predict():
    """Predict intent from text"""
    try:
        # Get JSON data from request
        data = request.get_json()
        
        # Validate input
        if not data or 'text' not in data:
            return jsonify({
                'error': 'Missing required field: text',
                'status': 'error'
            }), 400
        
        text = data['text']
        
        # Validate text input
        if not text or not text.strip():
            return jsonify({
                'error': 'Text cannot be empty',
                'status': 'error'
            }), 400
        
        # Make prediction
        result = predict_intent(text)
        result['status'] = 'success'
        
        return jsonify(result)
    
    except Exception as e:
        logger.error(f"Prediction error: {str(e)}")
        return jsonify({
            'error': str(e),
            'status': 'error'
        }), 500

@app.route('/batch_predict', methods=['POST'])
def batch_predict():
    """Predict intents for multiple texts"""
    try:
        # Get JSON data from request
        data = request.get_json()
        
        # Validate input
        if not data or 'texts' not in data:
            return jsonify({
                'error': 'Missing required field: texts (array)',
                'status': 'error'
            }), 400
        
        texts = data['texts']
        
        # Validate texts input
        if not isinstance(texts, list):
            return jsonify({
                'error': 'texts must be an array',
                'status': 'error'
            }), 400
        
        if len(texts) == 0:
            return jsonify({
                'error': 'texts array cannot be empty',
                'status': 'error'
            }), 400
        
        # Limit batch size for performance
        if len(texts) > 100:
            return jsonify({
                'error': 'Batch size cannot exceed 100 texts',
                'status': 'error'
            }), 400
        
        # Make predictions for all texts
        results = []
        for text in texts:
            if text and text.strip():
                result = predict_intent(text)
                results.append(result)
            else:
                results.append({
                    'intent': None,
                    'confidence': 0.0,
                    'input_text': text,
                    'cleaned_text': '',
                    'error': 'Empty text'
                })
        
        return jsonify({
            'status': 'success',
            'predictions': results,
            'count': len(results)
        })
    
    except Exception as e:
        logger.error(f"Batch prediction error: {str(e)}")
        return jsonify({
            'error': str(e),
            'status': 'error'
        }), 500

@app.route('/model_info', methods=['GET'])
def model_info():
    """Get model information"""
    try:
        if model_pipeline is None:
            return jsonify({
                'error': 'Model not loaded',
                'status': 'error'
            }), 500
        
        # Get model classes
        classes = list(model_pipeline.classes_)
        
        # Get model components info
        tfidf = model_pipeline.named_steps['tfidf']
        classifier = model_pipeline.named_steps['classifier']
        
        return jsonify({
            'status': 'success',
            'model_type': 'TF-IDF + Logistic Regression',
            'classes': classes,
            'num_classes': len(classes),
            'max_features': tfidf.max_features,
            'ngram_range': tfidf.ngram_range,
            'vocabulary_size': len(tfidf.vocabulary_) if hasattr(tfidf, 'vocabulary_') else 0
        })
    
    except Exception as e:
        logger.error(f"Model info error: {str(e)}")
        return jsonify({
            'error': str(e),
            'status': 'error'
        }), 500

# Error handlers
@app.errorhandler(404)
def not_found(error):
    return jsonify({
        'error': 'Endpoint not found',
        'status': 'error'
    }), 404

@app.errorhandler(405)
def method_not_allowed(error):
    return jsonify({
        'error': 'Method not allowed',
        'status': 'error'
    }), 405

@app.errorhandler(500)
def internal_error(error):
    return jsonify({
        'error': 'Internal server error',
        'status': 'error'
    }), 500

if __name__ == '__main__':
    # Load model on startup
    if not load_model():
        logger.error("Failed to load model. Exiting...")
        exit(1)
    
    # Get port from environment variable or use default
    port = int(os.environ.get('PORT', 5000))
    
    # Run the app
    app.run(
        host='0.0.0.0', 
        port=port, 
        debug=False  # Set to False for production
    )