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

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
INTENT_MODEL_DIR = os.path.normpath(os.path.join(BASE_DIR, "..", "Intent_classifier"))
NER_MODEL_PATH = os.path.normpath(os.path.join(BASE_DIR, "..", "keyword_ner_model"))

# Load intent classification model and preprocessors
print("Loading intent classification model...")
try:
    model = load_model(os.path.join(INTENT_MODEL_DIR, "intent_model.h5"))

    with open(os.path.join(INTENT_MODEL_DIR, "tokenizer.pkl"), "rb") as f:
        tokenizer = pickle.load(f)

    with open(os.path.join(INTENT_MODEL_DIR, "label_encoder.pkl"), "rb") as f:
        label_encoder = pickle.load(f)

    with open(os.path.join(INTENT_MODEL_DIR, "max_len.pkl"), "rb") as f:
        max_len = pickle.load(f)

    print("Intent classification model loaded successfully!")

except Exception as e:
    print(f"Error loading intent classification files: {e}")
    exit(1)

# Load NER model for entity extraction
print("Loading NER model...")
try:
    if os.path.exists(NER_MODEL_PATH):
        nlp = spacy.load(NER_MODEL_PATH)
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
    text = re.sub(r"[^\w\s]", "", text)  # Remove punctuation
    text = re.sub(r"\s+", " ", text).strip()  # Remove extra spaces
    return text


def extract_entities(text, intent):
    """Extract entities based on intent using multiple methods"""
    entities = {}
    text_lower = text.lower()

    if intent in ["transfer_money", "request_money"]:
        # Extract amount
        amount_patterns = [
            r"(?:rs\.?|rupees?|₹)?\s*(\d+(?:\.\d{2})?)\s*(?:rs\.?|rupees?|₹)?",
            r"(\d+)\s*(?:rupees?|rs\.?|₹)",
            r"₹\s*(\d+(?:\.\d{2})?)",
            r"(\d+)\s+rupees?",
        ]

        for pattern in amount_patterns:
            amount_match = re.search(pattern, text_lower)
            if amount_match:
                entities["amount"] = float(amount_match.group(1))
                break

        # Extract phone number
        phone_patterns = [
            r"(?:phone\s+)?(?:number\s+)?(?:mobile\s+)?(\d{10}|\d{11})",
            r"(\+91\d{10})",
            r"(?:to\s+|from\s+)?(\d{10})",
            r"number\s+(\d{10})",
        ]

        for pattern in phone_patterns:
            phone_match = re.search(pattern, text)
            if phone_match:
                phone = phone_match.group(1)
                if not phone.startswith("+91"):
                    phone = "+91" + phone.lstrip("0")[-10:]  # Get last 10 digits
                entities["phone_number"] = phone
                break

        # Extract UPI ID
        upi_pattern = r"([a-zA-Z0-9._-]+@[a-zA-Z]+)"
        upi_match = re.search(upi_pattern, text)
        if upi_match:
            entities["upi_id"] = upi_match.group(1)

        # Extract recipient name (words that could be names)
        name_patterns = [
            r"(?:to|send|pay|give)\s+([a-zA-Z]+(?:\s+[a-zA-Z]+)?)",
            r"([a-zA-Z]+)\s+(?:rs\.|rupees|₹|\d+)",
            r"(?:request\s+(?:from\s+)?|ask\s+)([a-zA-Z]+(?:\s+[a-zA-Z]+)?)",
        ]

        for pattern in name_patterns:
            name_match = re.search(pattern, text_lower)
            if name_match:
                potential_name = name_match.group(1).strip()
                # Filter out common words
                if potential_name not in [
                    "money",
                    "cash",
                    "amount",
                    "payment",
                    "the",
                    "my",
                    "his",
                    "her",
                    "upi",
                    "via",
                ]:
                    entities["recipient_name"] = potential_name.title()
                    break

    # Use NER model if available for additional keywords
    if nlp:
        try:
            doc = nlp(text)
            ner_entities = [ent.text for ent in doc.ents]
            if ner_entities:
                entities["ner_keywords"] = ner_entities
        except Exception:
            pass

    return entities


def predict_intent(text):
    """Predict intent from text input"""
    try:
        # Preprocess text
        clean_text = preprocess_text(text)

        # Convert to sequence and pad
        sequence = tokenizer.texts_to_sequences([clean_text])
        padded_sequence = pad_sequences(sequence, maxlen=max_len, padding="post")

        # Get prediction
        prediction_probs = model.predict(padded_sequence, verbose=0)
        predicted_class_index = np.argmax(prediction_probs, axis=1)[0]
        predicted_intent = label_encoder.inverse_transform([predicted_class_index])[0]
        confidence = float(prediction_probs[0][predicted_class_index])

        return predicted_intent, confidence

    except Exception as e:
        print(f"Error in prediction: {e}")
        return "error", 0.0


@app.route("/")
def home():
    return jsonify(
        {
            "message": "Voice Assistant with intent classification is running!",
            "endpoints": {
                "/voice_command": "POST - Complete voice command processing (recommended)",
                "/predict": "POST - Legacy intent prediction",
                "/health": "GET - Check server health",
            },
        }
    )


@app.route("/health")
def health():
    return jsonify(
        {
            "status": "healthy",
            "message": "Voice Assistant Server is running",
            "components": {
                "intent_classifier": "loaded",
                "ner_model": "loaded" if nlp else "not available",
            },
        }
    )


@app.route("/voice_command", methods=["POST"])
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

        if not data or "text" not in data:
            return (
                jsonify(
                    {
                        "error": "No text provided",
                        "message": "Please send JSON with 'text' field",
                    }
                ),
                400,
            )

        text = data["text"]
        if not text or text.strip() == "":
            return (
                jsonify({"error": "Empty text", "message": "Text cannot be empty"}),
                400,
            )

        print(f"Processing voice command: {text}")

        # Step 1: Intent Classification
        predicted_intent, confidence = predict_intent(text)

        confidence_percentage = round(confidence * 100, 2)

        response = {
            "input_text": text,
            "predicted_intent": predicted_intent,
            "confidence": round(confidence, 4),
            "confidence_percentage": confidence_percentage,
            "status": "success",
        }

        # CONFIDENCE THRESHOLD CHECK: If confidence < 70%, route to Rasa for casual conversation
        if confidence_percentage < 70.0:
            print(f"Low confidence ({confidence_percentage}%), routing to Rasa...")
            response.update(
                {
                    "assistant_message": "Let me help you with that.",
                    "source": "intent_classifier",
                    "action": "route_to_rasa",
                    "route_to_rasa": True,
                    "reason": "low_confidence",
                }
            )
            print(f"Response: {response}")
            return jsonify(response)

        # Step 2: Process based on intent (only if confidence >= 70%)
        print(
            f"High confidence ({confidence_percentage}%), processing intent: {predicted_intent}"
        )
        if predicted_intent == "transfer_money":
            print("Processing transfer money request - extracting entities...")
            entities = extract_entities(text, predicted_intent)

            if "amount" in entities:
                assistant_message = f"Ready to send ₹{entities['amount']}"
                if "recipient_name" in entities:
                    assistant_message += f" to {entities['recipient_name']}"
                elif "phone_number" in entities:
                    assistant_message += f" to {entities['phone_number']}"
                elif "upi_id" in entities:
                    assistant_message += f" to {entities['upi_id']}"
            else:
                assistant_message = (
                    "Amount not specified. Please mention the amount to transfer."
                )

            response.update(
                {
                    "entities": entities,
                    "assistant_message": assistant_message,
                    "action": "transfer_money",
                }
            )

        elif predicted_intent == "request_money":
            print("Processing request money - extracting entities...")
            entities = extract_entities(text, predicted_intent)

            if "amount" in entities:
                assistant_message = f"Request for ₹{entities['amount']}"
                if "recipient_name" in entities:
                    assistant_message += f" from {entities['recipient_name']}"
                elif "phone_number" in entities:
                    assistant_message += f" from {entities['phone_number']}"
                elif "upi_id" in entities:
                    assistant_message += f" from {entities['upi_id']}"
            else:
                assistant_message = (
                    "Amount not specified. Please mention the amount to request."
                )

            response.update(
                {
                    "entities": entities,
                    "assistant_message": assistant_message,
                    "action": "request_money",
                }
            )

        elif predicted_intent == "check_balance":
            print("Processing balance check - returning to frontend...")
            assistant_message = "Checking your balance"

            response.update(
                {
                    "assistant_message": assistant_message,
                    "action": "check_balance",
                }
            )

        else:
            print("General/casual question detected or unknown intent")
            # For normal/casual/generic questions, return response with flag to route to Rasa
            response.update(
                {
                    "assistant_message": "Let me help you with that.",
                    "source": "intent_classifier",
                    "action": "route_to_rasa",
                    "route_to_rasa": True,
                }
            )

        print(f"Response: {response}")
        return jsonify(response)

    except Exception as e:
        print(f"Error processing voice command: {e}")
        return jsonify({"error": str(e), "status": "error"}), 500


@app.route("/predict", methods=["POST"])
def predict():
    """Legacy endpoint for backward compatibility"""
    try:
        # Get text from request
        data = request.json

        if not data or "text" not in data:
            return (
                jsonify(
                    {
                        "error": "No text provided",
                        "message": "Please send JSON with 'text' field",
                    }
                ),
                400,
            )

        text = data["text"]

        if not text or text.strip() == "":
            return (
                jsonify({"error": "Empty text", "message": "Text cannot be empty"}),
                400,
            )

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
            "status": "success",
        }

        # Return format similar to original for backward compatibility
        return jsonify([response, {"keywords": entities}])

    except Exception as e:
        return jsonify({"error": str(e), "status": "error"}), 500


@app.route("/chatbot", methods=["POST"])
def chatbot_endpoint():
    """Deprecated endpoint kept for compatibility."""
    return jsonify(
        {
            "status": "success",
            "message": "Chatbot endpoint is deprecated. Use Rasa for conversational responses.",
            "source": "deprecated",
        }
    )


@app.route("/predict_batch", methods=["POST"])
def predict_batch():
    """Predict multiple texts at once"""
    try:
        data = request.json

        if not data or "texts" not in data:
            return (
                jsonify(
                    {
                        "error": "No texts provided",
                        "message": "Please send JSON with 'texts' array",
                    }
                ),
                400,
            )

        texts = data["texts"]

        if not isinstance(texts, list):
            return (
                jsonify(
                    {
                        "error": "Invalid format",
                        "message": "texts should be an array",
                    }
                ),
                400,
            )

        results = []
        for text in texts:
            predicted_intent, confidence = predict_intent(text)
            results.append(
                {
                    "input_text": text,
                    "predicted_intent": predicted_intent,
                    "confidence": round(confidence, 4),
                    "confidence_percentage": round(confidence * 100, 2),
                }
            )

        return jsonify({"results": results, "status": "success", "count": len(results)})

    except Exception as e:
        return jsonify({"error": str(e), "status": "error"}), 500


if __name__ == "__main__":
    print("=" * 60)
    print("Voice Assistant Server Starting...")
    print("=" * 60)
    print("Components Status:")
    print("   Intent Classifier: Loaded")
    print(f"   NER Model: {'Loaded' if nlp else 'Not Available'}")
    print("=" * 60)
    print("Server will be available at: http://localhost:5002")
    print("API endpoints:")
    print("   - POST /voice_command: Complete voice assistant (RECOMMENDED)")
    print("   - POST /predict: Legacy intent prediction")
    print("   - POST /chatbot: Deprecated compatibility endpoint")
    print("   - GET  /health: Health check")
    print("=" * 60)
    print("Voice Assistant Workflow:")
    print("   Transfer Money: Intent -> Entity -> Frontend action")
    print("   Request Money: Intent -> Entity -> Frontend action")
    print("   Check Balance: Intent -> Frontend action")
    print("   General Chat: Route to Rasa")
    print("=" * 60)
    app.run(host="0.0.0.0", port=5002, debug=True)
