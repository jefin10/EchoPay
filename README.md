# EchoPay: Voice-Enabled UPI Payment System

EchoPay is a multi-service UPI payment platform that combines a Flutter mobile application with Django transaction APIs, a Flask voice-intelligence service, and a Rasa conversational assistant.

## Project Overview

The platform supports manual and voice-first payment interactions. Voice input is processed by a TensorFlow-based intent classifier (CNN architecture), with entity extraction and conversational fallback behavior.

## Core Capabilities

- Voice-assisted payment flow and balance inquiry support
- CNN-based intent classification for payment commands
- Conversational fallback through Rasa
- Phone number and UPI ID based money transfer
- OTP-led onboarding and account access
- Transaction and money request management

## Technology Stack

- Frontend: Flutter 3.8.1+
- Backend APIs: Django 5.1.6 + PostgreSQL 15
- Voice Intelligence Service: Flask 2.3.3 + TensorFlow 2.17 (CNN classifier)
- Conversational AI: Rasa 3.6.0
- Containerization: Docker + Docker Compose

## System Architecture

```
+-----------------------+
|  Flutter Mobile App   |
|  Voice and Manual UX  |
+-----------+-----------+
            |
            |
  +---------+---------+-------------------+
  |                   |                   |
  v                   v                   v
+----------------+ +----------------+ +----------------+
| Django API     | | Flask Voice    | | Rasa Service   |
| Port 8000      | | Port 5002      | | Port 5005      |
| Auth, UPI, Txn | | CNN + Entities | | Conversation   |
+-------+--------+ +--------+-------+ +----------------+
        |                   |
        +---------+---------+
                  |
                  v
        +--------------------+
        | PostgreSQL         |
        | Port 5432          |
        | Persistent Storage |
        +--------------------+
```

## Repository Structure

```
VoiceUPI/
├── App/                          # Flutter application
├── Backend/                      # Flask voice and ML service
├── DJBackend/                    # Django transaction backend
├── Rasa/                         # Rasa conversational service
├── docker-compose.yml
├── docker-compose.dev.yml
├── DOCKER_SETUP.md
└── README.md
```

## Getting Started

### 1. Clone and Enter the Repository

```bash
git clone <repository-url>
cd VoiceUPI
```

### 2. Start Backend Services

```bash
docker-compose build
docker-compose up -d
docker-compose ps
```

### 3. Configure Flutter Service Endpoints

Update the URLs in `App/lib/constants/api_constants.dart` based on your runtime environment:

- Android emulator: `10.0.2.2`
- iOS simulator: `localhost` or host IP
- Physical device: host machine LAN IP

### 4. Run the Flutter App

```bash
cd App
flutter pub get
flutter run
```

## Docker Operations

```bash
docker-compose logs -f
docker-compose restart
docker-compose down
docker-compose up -d --build
docker-compose -f docker-compose.yml -f docker-compose.dev.yml up
```

## Service Endpoints

- Django: `http://localhost:8000`
- Flask: `http://localhost:5002`
- Rasa: `http://localhost:5005`

## API Documentation

- Django API documentation: `DJBackend/API_DOCUMENTATION.md`
- Flask API documentation: `Backend/API_DOCUMENTATION.md`

## License

Educational purposes only.
