# EchoPay - Voice-Enabled UPI Payment System

A complete AI-powered voice-enabled UPI payment application with intelligent intent classification, conversational AI, and traditional payment features.

## 🎯 Project Overview

**EchoPay** is an AI-powered voice UPI payment application combining machine learning, natural language processing, and a modern mobile interface.

### Key Features
- 🎤 Voice-based money transfers and balance checks
- 🤖 Intent classification with LSTM neural network
- 💬 Rasa chatbot for conversational assistance
- 📱 QR code scanning and generation
- 👥 Contact-based payments
- 🔐 Biometric + OTP authentication
- 📊 Transaction history and money requests

### Tech Stack
- **Frontend**: Flutter 3.8.1+ (Android/iOS)
- **Backend Services**:
  - Django 5.1.6 + PostgreSQL 15 (Transaction API)
  - Flask 2.3.3 + TensorFlow 2.17 (Intent Classification)
  - Rasa 3.6.0 (Conversational AI)
- **Deployment**: Docker + Docker Compose

---

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Flutter Mobile App                        │
│                      (Voice + Manual)                        │
└───────────────┬─────────────────────────────────────────────┘
                │
                ├──────────────┬──────────────┬──────────────┐
                │              │              │              │
                ▼              ▼              ▼              ▼
        ┌───────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐
        │  Django   │  │  Flask   │  │   Rasa   │  │PostgreSQL│
        │  (8000)   │  │  (5002)  │  │  (5005)  │  │  (5432)  │
        └───────────┘  └──────────┘  └──────────┘  └──────────┘
```

### Services

1. **Django Backend** - UPI transaction management, user accounts, authentication
2. **Flask Backend** - Voice command processing, intent classification (LSTM model)
3. **Rasa** - Conversational AI for help queries and fallback responses
4. **PostgreSQL** - Persistent data storage

---

## 📦 Prerequisites

### Required
- **Docker** & **Docker Compose** (recommended)
- **Flutter 3.8.1+** (for mobile app)
- **Git**

### Alternative (Manual Setup)
- Python 3.11
- PostgreSQL 15
- Android Studio or Xcode

---

## 🚀 Running with Docker (Recommended)

### Step 1: Clone Repository

```bash
git clone <repository-url>
cd VoiceUPI
```

### Step 2: Start Backend Services

```bash
# Build and start all containers
docker-compose build
docker-compose up -d

# Verify services are running
docker-compose ps
```

**Expected Output:**
```
NAME                STATUS          PORTS
echopay_db          Up              0.0.0.0:5432->5432/tcp
echopay_django      Up (healthy)    0.0.0.0:8000->8000/tcp
echopay_flask       Up (healthy)    0.0.0.0:5002->5002/tcp
echopay_rasa        Up (healthy)    0.0.0.0:5005->5005/tcp
```

### Step 3: Configure Flutter App

Edit `App/lib/constants/api_constants.dart`:

```dart
// For Android Emulator
const String DJANGO_BASE_URL = 'http://10.0.2.2:8000';
const String INTENT_API_URL = 'http://10.0.2.2:5002';
const String RASA_BASE_URL = 'http://10.0.2.2:5005';

// For Physical Device - Replace with your computer's IP
// Windows: ipconfig
// Mac/Linux: ifconfig
// const String DJANGO_BASE_URL = 'http://192.168.1.100:8000';
```

### Step 4: Run Flutter App

```bash
cd App
flutter pub get
flutter run
```

### Docker Management Commands

```bash
# View logs
docker-compose logs -f

# View specific service logs
docker-compose logs -f django
docker-compose logs -f flask

# Restart services
docker-compose restart

# Stop all services
docker-compose down

# Rebuild containers
docker-compose up -d --build

# Development mode (hot reload)
docker-compose -f docker-compose.yml -f docker-compose.dev.yml up
```

---

## 🧪 Testing Services

### Health Checks

```bash
# Django API
curl http://localhost:8000/

# Flask Intent Classifier
curl http://localhost:5002/health

# Rasa Chatbot
curl http://localhost:5005/
```

### API Testing

**Send OTP:**
```bash
curl "http://localhost:8000/accounts/send_otp/?phone=9876543210"
```

**Voice Command:**
```bash
curl -X POST http://localhost:5002/voice_command \
  -H "Content-Type: application/json" \
  -d '{
    "text": "send 500 rupees to 9876543210",
    "userPhone": "+919999999999"
  }'
```

**Rasa Chat:**
```bash
curl -X POST http://localhost:5005/webhooks/rest/webhook \
  -H "Content-Type: application/json" \
  -d '{
    "sender": "test",
    "message": "hello"
  }'
```

### Voice Command Examples

- "Send 500 rupees to 9876543210"
- "What is my balance"
- "Request 1000 from John"
- "Transfer 250 to user@paytm"

---

## 📊 Project Structure

```
VoiceUPI/
├── App/                          # Flutter mobile app
│   ├── lib/
│   │   ├── main.dart            # App entry point
│   │   ├── constants/           # API URLs and configs
│   │   ├── normalUPI/           # Main screens (dashboard, voice, profile)
│   │   ├── services/            # API service classes
│   │   └── voiceToText/         # Voice processing
│   └── pubspec.yaml             # Flutter dependencies
│
├── Backend/                      # Flask AI/ML service
│   └── Intent_classifier/
│       ├── flask_server.py      # Main server
│       ├── intent_model.h5      # LSTM model
│       ├── tokenizer.pkl        # Text preprocessor
│       ├── label_encoder.pkl    # Intent labels
│       └── requirements.txt
│
├── DJBackend/                    # Django API service
│   ├── accounts/                # UPI transaction app
│   │   ├── models.py           # User, Transaction, OTP models
│   │   ├── views.py            # API endpoints
│   │   └── urls.py
│   ├── DJBackend/
│   │   └── settings.py         # Django config
│   ├── manage.py
│   └── requirements.txt
│
├── Rasa/                         # Rasa chatbot
│   ├── domain.yml               # Intents and responses
│   ├── data/
│   │   ├── nlu.yml             # Training data
│   │   └── stories.yml          # Conversation flows
│   └── config.yml
│
├── docker-compose.yml            # Main Docker config
├── docker-compose.dev.yml        # Development overrides
└── DOCKER_SETUP.md              # Detailed Docker guide
```

---

## 🔧 API Documentation

### Django Endpoints

**Authentication:**
- `GET /accounts/send_otp/?phone=<phone>` - Generate OTP
- `GET /accounts/verify_otp/?phone=<phone>&otp=<otp>` - Verify OTP
- `POST /accounts/signup/` - Create new user

**Account:**
- `GET /accounts/getProfile/?phoneNumber=<phone>` - Get user profile
- `GET /accounts/getBalance/?phoneNumber=<phone>` - Get account balance

**Transactions:**
- `POST /accounts/sendMoneyPhone/` - Send money via phone number
- `POST /accounts/sendMoneyId/` - Send money via UPI ID
- `GET /accounts/getTransactions/?phoneNumber=<phone>` - Transaction history

**Money Requests:**
- `GET /accounts/getMoneyRequests/?phoneNumber=<phone>` - Get all requests
- `POST /accounts/createMoneyRequest/` - Create payment request
- `POST /accounts/updateRequestStatus/` - Accept/decline request

### Flask Endpoints

- `POST /voice_command` - Process voice command and extract intent
- `GET /health` - Service health check

### Rasa Endpoints

- `POST /webhooks/rest/webhook` - Chat with bot
- `GET /` - Health check

---

## ❗ Troubleshooting

### Flutter Cannot Connect to Backend

**Problem:** App shows connection errors

**Solution:**
```dart
// Android Emulator: Use 10.0.2.2
const String DJANGO_BASE_URL = 'http://10.0.2.2:8000';

// Physical Device: Use computer's IP address
// Get IP: ipconfig (Windows) or ifconfig (Mac/Linux)
const String DJANGO_BASE_URL = 'http://192.168.1.100:8000';
```

### Docker Container Fails to Start

```bash
# Check logs
docker-compose logs django

# Clean rebuild
docker-compose down
docker-compose build --no-cache
docker-compose up -d
```

### Port Already in Use

```bash
# Windows
netstat -ano | findstr :8000
taskkill /PID <PID> /F

# Linux/Mac
lsof -ti:8000 | xargs kill -9
```

### Flask Model Loading Error

**Ensure model files exist:**
```
Backend/Intent_classifier/
├── intent_model.h5
├── tokenizer.pkl
├── label_encoder.pkl
└── max_len.pkl
```

---

## 🔐 Security Considerations

**Current Configuration (Development):**
- ✅ OTP-based authentication
- ✅ Database credentials in environment
- ⚠️ Debug mode enabled
- ⚠️ CORS allows all origins
- ⚠️ OTP shown in API response

**For Production:**
- Set `DEBUG=False` in Django settings
- Configure specific CORS origins
- Use environment variables for all secrets
- Enable HTTPS/TLS
- Implement rate limiting
- Use proper SMS provider (Twilio) for OTP
- Add request logging and monitoring

---

## 📄 License

Educational purposes only.

---

**Built with ❤️ using Flutter, Django, Flask & Rasa**
