# EchoPay - Voice-Enabled UPI Payment System

A complete AI-powered voice-enabled UPI payment application with intelligent intent classification, conversational AI, and traditional payment features.

## 📋 Table of Contents
1. [Project Overview](#project-overview)
2. [Architecture](#architecture)
3. [Prerequisites](#prerequisites)
4. [Backend Setup](#backend-setup)
5. [Frontend Setup](#frontend-setup)
6. [Docker Setup](#docker-setup)
7. [Running the Application](#running-the-application)
8. [API Documentation](#api-documentation)
9. [Testing](#testing)
10. [Troubleshooting](#troubleshooting)

---

## 🎯 Project Overview

**EchoPay** is an AI-powered voice-enabled UPI payment application that combines:
- **Voice Commands**: Natural language processing for hands-free UPI transactions
- **Intent Classification**: ML model (97.65% accuracy) to understand user payment intentions
- **Conversational AI**: Rasa chatbot for general queries and assistance
- **Traditional UPI**: Full-featured manual payment interface

### Key Features
- 🎤 Voice-based money transfers
- 💰 Balance checking via voice commands
- 📱 QR code scanning and generation
- 👥 Contact-based payments
- 💬 AI chatbot assistance (Rasa)
- 🔐 Secure authentication (Biometric + OTP)
- 📊 Transaction history
- 🤖 Intent classification with 97.65% accuracy

### Model Performance
- **Accuracy:** 97.65%
- **Model Size:** ~40KB (extremely lightweight!)
- **Intent Classes:** `transfer_money`, `check_balance`, `request_money`
- **Algorithm:** TF-IDF + Logistic Regression (Flask) & LSTM Neural Network (TensorFlow)

---

## 🏗️ Architecture

The application consists of **4 main backend services** + **1 mobile frontend**:

```
┌─────────────────────────────────────────────────────────────┐
│                    Flutter Mobile App                        │
│                   (Android/iOS - EchoPay)                    │
└───────────────┬─────────────────────────────────────────────┘
                │
                ├──────────────┬──────────────┬──────────────┐
                │              │              │              │
                ▼              ▼              ▼              ▼
        ┌───────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐
        │  Django   │  │  Flask   │  │   Rasa   │  │PostgreSQL│
        │ Backend   │  │ Backend  │  │ Chatbot  │  │ Database │
        │ (Port     │  │ (Port    │  │ (Port    │  │ (Port    │
        │  8000)    │  │  5002)   │  │  5005)   │  │  5432)   │
        └───────────┘  └──────────┘  └──────────┘  └──────────┘
```

### Component Responsibilities

#### 1. **Django Backend (Port 8000)**
- **Purpose**: UPI transaction management & user accounts
- **Database**: PostgreSQL
- **Key Features**:
  - User authentication (OTP via Twilio)
  - Account management with balance tracking
  - Money transfers (phone/UPI ID)
  - Transaction history
  - Money request handling

#### 2. **Flask Backend (Port 5002)**
- **Purpose**: AI/ML processing for voice commands
- **Key Features**:
  - Intent classification (97.65% accuracy)
  - Named Entity Recognition (NER) - extracts amounts, phone numbers, UPI IDs
  - Entity extraction from voice input
  - Orchestrates calls to Django backend
  - Routes to Rasa for conversational queries

#### 3. **Rasa (Port 5005)**
- **Purpose**: Conversational AI for general queries
- **Key Features**:
  - Handles low-confidence intents
  - FAQ responses (app features, security, usage)
  - Natural conversation flow
  - Fallback responses

#### 4. **PostgreSQL Database (Port 5432)**
- **Purpose**: Data persistence
- **Tables**: Users, UserAccounts, Transactions, MoneyRequests

#### 5. **Flutter App (EchoPay)**
- **Purpose**: Mobile frontend (Android/iOS)
- **Key Features**: Speech-to-text, voice commands, QR scanning, contact payments

---

## 📦 Prerequisites

### System Requirements
- **OS**: Windows 10/11, macOS, or Linux
- **RAM**: Minimum 8GB (16GB recommended)
- **Storage**: 5GB free space

### Software Requirements

#### For Backend Development
```bash
# Python 3.10 or 3.11
python --version

# PostgreSQL 15
postgres --version

# pip
pip --version
```

#### For Frontend Development
```bash
# Flutter 3.8.1+
flutter --version

# Android Studio / Xcode
```

#### For Docker Setup (Recommended) ⭐
```bash
docker --version
docker-compose --version
```

---

## 🚀 Backend Setup

### Option 1: Docker Setup (Recommended) ⭐

#### Step 1: Environment Setup

Create `.env` file in project root:

```bash
# PostgreSQL
POSTGRES_DB=echopay_db
POSTGRES_USER=echopay_user
POSTGRES_PASSWORD=echopay_password
POSTGRES_HOST=db
POSTGRES_PORT=5432

# Django
DEBUG=1
SECRET_KEY=your-secret-key-here

# Twilio (for OTP)
TWILIO_ACCOUNT_SID=your_account_sid
TWILIO_AUTH_TOKEN=your_auth_token
TWILIO_PHONE_NUMBER=your_phone_number

# Database URL
DATABASE_URL=postgresql://echopay_user:echopay_password@db:5432/echopay_db
```

#### Step 2: Build and Run

```bash
# Navigate to project
cd EchoPay

# Build containers
docker-compose build

# Start all services
docker-compose up -d

# Check status
docker-compose ps
```

Expected output:
```
NAME                  STATUS          PORTS
echopay_db           Up              0.0.0.0:5432->5432/tcp
echopay_django       Up (healthy)    0.0.0.0:8000->8000/tcp
echopay_flask        Up (healthy)    0.0.0.0:5002->5002/tcp
echopay_rasa         Up (healthy)    0.0.0.0:5005->5005/tcp
```

#### Step 3: Verify Services

```bash
# Django
curl http://localhost:8000/

# Flask
curl http://localhost:5002/health

# Rasa
curl http://localhost:5005/
```

#### Docker Commands

```bash
# View logs
docker-compose logs -f
docker-compose logs -f django

# Restart
docker-compose restart

# Stop
docker-compose down

# Rebuild
docker-compose up -d --build
```

---

### Option 2: Manual Setup

#### PostgreSQL Setup

```bash
# Create database
psql -U postgres
CREATE DATABASE echopay_db;
CREATE USER echopay_user WITH PASSWORD 'echopay_password';
GRANT ALL PRIVILEGES ON DATABASE echopay_db TO echopay_user;
\q
```

#### Django Backend

```bash
cd DJBackend
python -m venv venv
# Windows:
venv\Scripts\activate
# Linux/Mac:
source venv/bin/activate

pip install -r requirements.txt
python manage.py migrate
python manage.py runserver 0.0.0.0:8000
```

#### Flask Backend

```bash
cd Backend/Intent_classifier
python -m venv venv
venv\Scripts\activate
pip install -r requirements.txt
python flask_server.py
```

#### Rasa

```bash
cd Rasa
python -m venv venv
venv\Scripts\activate
pip install rasa
rasa train
rasa run --enable-api --cors "*" --port 5005
```

---

## 📱 Frontend Setup (Flutter App)

### Step 1: Install Flutter

Download from https://flutter.dev/docs/get-started/install

```bash
flutter doctor
```

### Step 2: Configure API URLs

Edit `App/lib/constants/api_constants.dart`:

```dart
// Android Emulator
const String DJANGO_BASE_URL = 'http://10.0.2.2:8000';
const String INTENT_API_URL = 'http://10.0.2.2:5002';
const String RASA_BASE_URL = 'http://10.0.2.2:5005';

// Physical Device (use your computer's IP)
// const String DJANGO_BASE_URL = 'http://192.168.1.100:8000';
// const String INTENT_API_URL = 'http://192.168.1.100:5002';
// const String RASA_BASE_URL = 'http://192.168.1.100:5005';
```

### Step 3: Run App

```bash
cd App
flutter pub get
flutter run
```

---

## ▶️ Running the Application

### Full Stack with Docker

```bash
# Start all services
docker-compose up -d

# Run Flutter app
cd App
flutter run
```

### Full Stack Manual (4 Terminals)

```bash
# Terminal 1: Django
cd DJBackend && python manage.py runserver 0.0.0.0:8000

# Terminal 2: Flask
cd Backend/Intent_classifier && python flask_server.py

# Terminal 3: Rasa
cd Rasa && rasa run --enable-api --cors "*" --port 5005

# Terminal 4: Flutter
cd App && flutter run
```

---

## 📚 API Documentation

### Django Endpoints

#### Authentication
- `GET /accounts/send_otp/?phone=<phone>` - Send OTP
- `GET /accounts/verify_otp/?phone=<phone>&otp=<otp>` - Verify OTP
- `POST /accounts/signup/` - Sign up user

#### Account
- `GET /accounts/getProfile/?phoneNumber=<phone>` - Get profile
- `GET /accounts/getBalance/?phoneNumber=<phone>` - Get balance

#### Transactions
- `POST /accounts/sendMoneyPhone/` - Send money by phone
- `POST /accounts/sendMoneyId/` - Send money by UPI ID
- `GET /accounts/getTransactions/?phoneNumber=<phone>` - History

#### Money Requests
- `GET /accounts/getMoneyRequests/?phoneNumber=<phone>` - Get requests
- `POST /accounts/createMoneyRequest/` - Create request
- `POST /accounts/updateRequestStatus/` - Update status

### Flask Endpoints

- `POST /voice_command` - Process voice command (main endpoint)
  ```json
  {
    "text": "send 500 to 9876543210",
    "userPhone": "+919999999999"
  }
  ```
- `POST /predict` - Legacy intent prediction
- `GET /health` - Health check

### Rasa Endpoints

- `POST /webhooks/rest/webhook` - Chat with bot
- `GET /` - Health check

---

## 🧪 Testing

### Backend Tests

```bash
# Django
curl http://localhost:8000/
curl "http://localhost:8000/accounts/send_otp/?phone=9876543210"

# Flask
curl http://localhost:5002/health
curl -X POST http://localhost:5002/voice_command \
  -H "Content-Type: application/json" \
  -d '{"text": "send 500 to 9876543210", "userPhone": "+919999999999"}'

# Rasa
curl -X POST http://localhost:5005/webhooks/rest/webhook \
  -H "Content-Type: application/json" \
  -d '{"sender": "test", "message": "hello"}'
```

### Voice Command Examples

**Transfer Money:**
- "Send 500 rupees to 9876543210"
- "Transfer 1000 to john@paytm"

**Check Balance:**
- "What is my balance"
- "Check my account balance"

**Request Money:**
- "Request 500 from 9876543210"
- "Ask 1000 rupees from john@paytm"

---

## ❗ Troubleshooting

### 1. Flutter: Cannot connect to backend

```dart
// Use 10.0.2.2 for Android Emulator
const String DJANGO_BASE_URL = 'http://10.0.2.2:8000';

// Use computer's IP for physical device
// Find IP: ipconfig (Windows) or ifconfig (Mac/Linux)
const String DJANGO_BASE_URL = 'http://192.168.1.100:8000';
```

### 2. Docker: Services not starting

```bash
docker-compose logs django
docker-compose down
docker-compose build --no-cache
docker-compose up -d
```

### 3. Port already in use

```bash
# Windows
netstat -ano | findstr :8000
taskkill /PID <PID> /F

# Linux/Mac
lsof -ti:8000 | xargs kill -9
```

### 4. Flutter: Missing packages

```bash
flutter clean
flutter pub get
flutter run
```

---

## 📊 Project Structure

```
EchoPay/
├── App/                    # Flutter mobile app (EchoPay)
│   ├── lib/
│   │   ├── main.dart
│   │   ├── constants/     # API URLs
│   │   ├── normalUPI/     # Main screens
│   │   └── services/      # API services
│   └── pubspec.yaml
├── Backend/               # Flask AI/ML backend
│   └── Intent_classifier/
│       ├── flask_server.py
│       └── intent_model.h5
├── DJBackend/            # Django UPI backend
│   ├── accounts/
│   └── manage.py
├── Rasa/                 # Rasa chatbot
│   ├── domain.yml
│   └── data/
├── docker-compose.yml
└── .env
```

---

## 🚀 Quick Start Summary

### Using Docker
```bash
cd EchoPay
docker-compose up -d
cd App && flutter run
```

### Manual
```bash
# Terminal 1: Django
cd DJBackend && python manage.py runserver 0.0.0.0:8000

# Terminal 2: Flask  
cd Backend/Intent_classifier && python flask_server.py

# Terminal 3: Rasa
cd Rasa && rasa run --enable-api --cors "*" --port 5005

# Terminal 4: Flutter
cd App && flutter run
```

---

## 🔐 Security Notes

**Development:**
- Debug mode enabled
- CORS allows all origins
- Secrets in plain text

**Production:**
- Set `DEBUG=False`
- Use environment variables
- Configure specific CORS origins
- Use HTTPS
- Implement rate limiting

---

## 📄 License

Educational purposes only.

---

**Built with ❤️ for voice-enabled UPI transactions**
