# VoiceUPI Intent Classification System

## Overview
This system processes voice commands for UPI transactions using Flask backend and Flutter frontend.

## System Architecture

```
User speaks -> Flutter App -> Flask Server -> Intent Model -> Response -> Flutter Action
                                    |
                                    v
                            Keyword Extraction
```

## Flask Server Setup

### File: `flask_server_corrected.py`

**Location**: `Backend/Intent_classifier/flask_server_corrected.py`

### Endpoints

#### 1. GET `/`
Server information and available endpoints.

**Response:**
```json
{
  "message": "VoiceUPI Intent Classification API is running!",
  "version": "1.0",
  "endpoints": {
    "/": "GET - Server info",
    "/health": "GET - Check server health",
    "/predict": "POST - Single text intent prediction with keyword extraction"
  }
}
```

#### 2. GET `/health`
Health check endpoint.

**Response:**
```json
{
  "status": "healthy",
  "message": "Server is running",
  "model_loaded": true
}
```

#### 3. POST `/predict`
Main prediction endpoint.

**Request:**
```json
{
  "text": "send 1000 rs to jefin"
}
```

**Response:**
```json
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
```

### Supported Intents

1. **transfer_money** - Send money to someone
2. **check_balance** - Check account balance
3. **request_money** - Request money from someone

### Running the Server

```bash
cd Backend/Intent_classifier
python flask_server_corrected.py
```

Server will run on: `http://0.0.0.0:5000`

For production deployment (Render, Heroku, etc.):
- The `PORT` environment variable will be automatically detected
- CORS is enabled for Flutter app communication

---

## Flutter Integration

### Files Modified

1. **`lib/constants/api_constants.dart`**
   - Contains all API URLs
   - Change `INTENT_API_URL` to your Flask server URL

2. **`lib/services/intent_service.dart`**
   - Handles communication with Flask server
   - Processes intent and extracts keywords
   - Returns structured response for UI

3. **`lib/voiceToText/voiceToText.dart`**
   - Voice input interface
   - Displays confirmation dialogs
   - Executes actions based on intent

### API Configuration

In `lib/constants/api_constants.dart`:

```dart
// For local development
const String INTENT_API_URL = 'http://172.16.192.54:5002';

// For production (Render)
const String INTENT_API_URL = 'https://voiceupiintent.onrender.com';

// Endpoints
const String CLASSIFY_INTENT_URL = '$INTENT_API_URL/predict';
```

### Usage Flow

#### Example: "Send 1000 rs to jefin"

1. **User speaks**: "send 1000 rs to jefin"

2. **Speech to Text**: Converts to text string

3. **Intent Service** (`IntentService.processVoiceCommand(text)`):
   - Calls Flask `/predict` endpoint
   - Receives intent and keywords
   - Returns structured response:
   ```dart
   {
     'status': 'success',
     'intent': 'transfer_money',
     'action': 'initiate_transfer',
     'message': 'Send ₹1000 to jefin?',
     'data': {
       'amount': 1000.0,
       'recipient': 'jefin',
       'original_text': 'send 1000 rs to jefin'
     }
   }
   ```

4. **UI Shows Confirmation Dialog**:
   ```
   Confirm Transfer
   Send ₹1000 to jefin?
   
   [Cancel]  [Confirm & Send]
   ```

5. **On Confirmation**:
   - Calls backend to execute transfer
   - Shows success message
   - Updates UI with "✓ Successfully sent ₹1000 to jefin!"

### Code Example

```dart
// In your Flutter widget
final result = await IntentService.processVoiceCommand("send 1000 rs to jefin");

if (result['action'] == 'initiate_transfer') {
  // Show confirmation dialog
  showDialog(
    context: context,
    builder: (context) => TransferConfirmationDialog(
      amount: result['data']['amount'],
      recipient: result['data']['recipient'],
    ),
  );
}
```

---

## Testing

### Test Flask Server

```bash
# Test health endpoint
curl http://localhost:5000/health

# Test prediction
curl -X POST http://localhost:5000/predict \
  -H "Content-Type: application/json" \
  -d '{"text": "send 1000 rs to jefin"}'
```

### Test in Flutter

1. Make sure Flask server is running
2. Update `INTENT_API_URL` in `api_constants.dart`
3. Open Voice Assistant in app
4. Speak: "send 1000 rs to jefin"
5. Verify confirmation dialog appears
6. Check console for logs

---

## Deployment

### Deploy Flask Server to Render

1. Create `requirements.txt`:
```txt
Flask==3.0.0
flask-cors==4.0.0
tensorflow==2.15.0
spacy==3.7.2
numpy==1.26.2
```

2. Create `render.yaml`:
```yaml
services:
  - type: web
    name: voiceupi-intent
    env: python
    buildCommand: pip install -r requirements.txt
    startCommand: python flask_server_corrected.py
```

3. Deploy to Render and get URL

4. Update Flutter app:
```dart
const String INTENT_API_URL = 'https://your-app.onrender.com';
```

---

## Troubleshooting

### Common Issues

1. **Server not responding**
   - Check if Flask server is running
   - Verify URL in `api_constants.dart`
   - Check firewall/network settings

2. **Low confidence predictions**
   - Retrain model with more data
   - Check text preprocessing
   - Verify model files are loaded correctly

3. **Keywords not extracted**
   - Ensure NER model is properly trained
   - Check `keyword_ner_model` directory exists
   - Verify spacy model is loaded

4. **CORS errors**
   - Ensure `CORS(app)` is in Flask code
   - Check request headers

---

## Example Voice Commands

### Transfer Money
- "send 1000 rs to jefin"
- "transfer 500 rupees to john"
- "pay 250 to mom"

### Check Balance
- "check my balance"
- "what's my balance"
- "show balance"

### Request Money
- "request 500 from dad"
- "ask john for 1000 rupees"
- "collect money from mom"

---

## Future Enhancements

1. Add support for UPI ID and phone number in voice commands
2. Implement transaction history queries
3. Add multi-language support
4. Improve keyword extraction accuracy
5. Add voice feedback (text-to-speech)

---

## Contact

For issues or questions, please check the logs:
- Flask: Check terminal output
- Flutter: Check console logs in VS Code/Android Studio
