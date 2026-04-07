# Django Backend API Documentation

This document describes the available HTTP endpoints exposed by the Django backend.

## Base URL

- Local: `http://localhost:8000`
- Route prefix: `/accounts/`

Full endpoint format:

`http://localhost:8000/accounts/<endpoint>/`

## Response Conventions

Most endpoints return JSON in one of these shapes:

- Success: `{ "status": "success", ... }`
- Error: `{ "status": "error", "error" or "message": "..." }`

## Authentication and Onboarding

### GET `/accounts/send_otp/`
Generate and store a one-time password for a phone number.

Query parameters:
- `phone` (string, required)

Success response:
- `status`
- `message`
- `otp` (included in debug mode)

### GET `/accounts/verify_otp/`
Verify OTP and determine whether the user is new.

Query parameters:
- `phone` (string, required)
- `otp` (string, required)

Success response:
- `status`
- `message`
- `isNewUser`
- `phoneNumber`
- `upiName` and `upiId` for existing users

### POST `/accounts/signup/`
Create a new user after OTP verification.

Request body:
- `upiName` (string, required)
- `phoneNumber` (string, required)

Success response:
- `status`
- `upiName`
- `phoneNumber`
- `upiId`

## Account and Search

### GET `/accounts/searchPhonenumber/`
Find user details by phone number.

Query parameters:
- `phoneNumber` (string, required)

Success response:
- `status`
- `upiName`
- `upiId`

### GET `/accounts/searchByUpiId/`
Find user details by UPI ID.

Query parameters:
- `upiId` (string, required)

Success response:
- `status`
- `upiName`
- `phoneNumber`

### GET `/accounts/getProfile/`
Get profile details for a phone number.

Query parameters:
- `phoneNumber` (string, required)

Success response:
- `status`
- `upiName`
- `upiId`

### GET `/accounts/getBalance/`
Get account balance.

Query parameters:
- `phoneNumber` (string, required)

Success response:
- `status`
- `balance`

### GET `/accounts/checkHasAccount/`
Check whether a user account exists.

Query parameters:
- `phoneNumber` (string, required)

Success response:
- `status`
- `hasAccount` (boolean)

## Transactions

### POST `/accounts/sendMoneyPhone/`
Transfer money using sender and receiver phone numbers.

Request body:
- `senderPhone` (string, required)
- `receiverPhone` (string, required)
- `amount` (number/string, required)

Success response:
- `status`
- `message`

### POST `/accounts/sendMoneyId/`
Transfer money using sender phone and receiver UPI ID.

Request body:
- `senderPhone` (string, required)
- `receiverUpi` (string, required)
- `amount` (number/string, required)

Success response:
- `status`
- `message`

### POST `/accounts/getTransactions/`
Get sent and received transaction history for a user.

Request body:
- `phoneNumber` (string, required)

Success response:
- `status`
- `transactions.sent[]`
- `transactions.received[]`

## Money Requests

### POST `/accounts/createMoneyRequest/`
Create a money request using requestee phone number.

Request body:
- `requesterPhone` (string, required)
- `requesteePhone` (string, required)
- `amount` (number/string, required)
- `message` (string, optional)

Success response:
- `status`
- `message`
- `requestId`

### POST `/accounts/createMoneyRequestByUpi/`
Create a money request using requestee UPI ID.

Request body:
- `requesterPhone` (string, required)
- `requesteeUpi` (string, required)
- `amount` (number/string, required)
- `message` (string, optional)

Success response:
- `status`
- `message`
- `requestId`

### GET `/accounts/getMoneyRequests/`
Get sent and received money requests for a user.

Query parameters:
- `phoneNumber` (string, required)

Success response:
- `status`
- `sentRequests[]`
- `receivedRequests[]`

### POST `/accounts/updateRequestStatus/`
Update request status and optionally settle funds when approved.

Request body:
- `requestId` (number, required)
- `status` (string, required) - `approved`, `rejected`, or `cancelled`
- `phoneNumber` (string, required)

Success response:
- `status`
- `message`

## Notes

- Phone number inputs are normalized by backend utility methods.
- Error status codes vary by failure reason (400, 403, 404, 500).
- For exact payload handling and validation behavior, refer to `accounts/views.py`.
