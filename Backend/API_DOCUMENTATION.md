# Flask Voice Service API Documentation

This document describes the HTTP endpoints exposed by the Flask voice service.

## Base URL

- Local: `http://localhost:5002`

## Service Purpose

The Flask service performs voice-intent processing and related NLP steps:

- Intent prediction using a TensorFlow CNN-based classifier
- Entity extraction for payment intents
- Confidence-based routing signals for conversational fallback
- Optional chatbot response generation

## Response Conventions

Most endpoints return JSON with:

- `status: "success"` for successful operations
- `status: "error"` for failures

## Endpoints

### GET `/`
Service home endpoint.

Returns a basic service message and endpoint list.

### GET `/health`
Health and component status endpoint.

Returns:
- `status`
- `message`
- `components.intent_classifier`
- `components.chatbot`
- `components.ner_model`
- `components.django_backend`

### POST `/voice_command`
Primary endpoint for processing a single voice command.

Request body:
- `text` (string, required)
- `userPhone` (string, optional)

Typical success fields:
- `status`
- `input_text`
- `predicted_intent`
- `confidence`
- `confidence_percentage`
- `assistant_message`
- `action` (`transfer_money`, `request_money`, `check_balance`, or `route_to_rasa`)
- `entities` (for payment-related intents)
- `route_to_rasa` (boolean when fallback is requested)

Validation errors:
- Missing `text` returns HTTP 400.
- Empty `text` returns HTTP 400.

### POST `/predict`
Legacy single-text intent prediction endpoint.

Request body:
- `text` (string, required)

Returns a legacy list response:
- item 1: prediction metadata
- item 2: extracted keywords/entities

### POST `/predict_batch`
Batch intent prediction endpoint.

Request body:
- `texts` (array of strings, required)

Returns:
- `status`
- `count`
- `results[]` with prediction metadata per text

### POST `/chatbot`
Direct chatbot endpoint.

Request body:
- `text` (string, required)

Returns:
- `status`
- `input_text`
- `response`

## Notes

- Intent confidence below threshold is flagged for fallback handling through Rasa.
- The service returns intent and entity guidance for the frontend to execute follow-up actions.
- For exact implementation details, refer to `ml-server/flask_server.py`.
