# EchoPay (VoiceUPI) — Complete Interview Preparation Guide

> A deep, file-by-file, section-by-section interview brief for a 2-hour technical interview.
> Read this top to bottom once, then drill the **"Weak Links"** and **"Talking Scripts"** sections — those are where interviews are won or lost.

---

## TABLE OF CONTENTS

1. [30-Second & 2-Minute Pitch (memorize these)](#1-elevator-pitches)
2. [System Architecture — The Big Picture](#2-system-architecture)
3. [End-to-End Request Flows (trace these on a whiteboard)](#3-end-to-end-flows)
4. [Component 1 — Flutter Mobile App (DEEP)](#4-flutter-app-deep-dive)
5. [Component 2 — Flask Voice/ML Service (Intent + NER)](#5-flask-ml-service)
6. [Component 3 — The CNN Intent Classifier (ML deep dive)](#6-cnn-intent-classifier)
7. [Component 4 — spaCy NER Model](#7-spacy-ner-model)
8. [Component 5 — Rasa Conversational AI](#8-rasa)
9. [Component 6 — Django Backend + PostgreSQL](#9-django-backend)
10. [Component 7 — Docker / DevOps](#10-docker-devops)
11. [Security Analysis (interviewers WILL push here)](#11-security)
12. [⚠️ WEAK LINKS & MISSING PIECES — with defense scripts](#12-weak-links)
13. [Rapid-fire Q&A bank (100+ questions)](#13-rapid-fire)
14. [System Design / "How would you scale this?"](#14-scaling)
15. [Behavioral / project-story questions](#15-behavioral)
16. [Cheat-sheet of exact numbers & facts](#16-cheatsheet)

---

## 1. ELEVATOR PITCHES

### 30-second pitch
> "EchoPay is a voice-enabled UPI payment app. The user can speak a command like *'send 500 to 9876543210'* and the app sends the money. Under the hood it's a Flutter mobile app talking to three backend services: a Django REST API that owns the accounts, balances and transactions on PostgreSQL; a Flask service that runs a TensorFlow CNN to classify the spoken intent and a spaCy NER model + regex to pull out the amount and recipient; and a Rasa chatbot that handles casual or out-of-scope conversation. Everything is containerized with Docker Compose."

### 2-minute pitch (the structured version)
1. **Problem:** UPI apps are tap-heavy; voice makes payments accessible (low literacy, elderly, hands-free).
2. **Frontend:** Flutter app — phone+OTP onboarding, biometric unlock, manual pay flows (phone / UPI ID / QR / contacts / request money), and a voice assistant tab.
3. **Voice pipeline:** Device speech-to-text (Google's on-device STT via `speech_to_text` package) → text → Flask `/voice_command`.
4. **Intent layer:** Flask runs a 1D-CNN text classifier (3 classes: `transfer_money`, `request_money`, `check_balance`). If confidence ≥ 70%, it extracts entities and tells the app what action to take. If < 70%, it flags `route_to_rasa` and the app forwards the text to Rasa for an FAQ-style reply.
5. **Execution:** The Flutter app (not Flask) calls the Django API to actually move money. Flask only *classifies* — it never touches the database. This keeps the ML service stateless.
6. **Data:** Django + PostgreSQL store `User`, `UserAccount` (balance), `Transaction`, `MoneyRequest`, `OTP`.
7. **Confirmation & security:** Before a voice transfer/balance check executes, the app triggers a biometric (fingerprint/face) prompt.

Keep this as your spine. Every deeper question is a branch off one of these 7 points.

---

## 2. SYSTEM ARCHITECTURE

```
                ┌─────────────────────────┐
                │   Flutter Mobile App     │   (Dart, Material 3)
                │  - Auth (phone+OTP)      │
                │  - Biometric unlock      │
                │  - Manual pay flows      │
                │  - Voice assistant       │
                │  - speech_to_text (STT)  │
                └───────────┬─────────────┘
                            │ HTTP/JSON (http package)
        ┌───────────────────┼────────────────────────┐
        ▼                   ▼                         ▼
┌──────────────┐   ┌──────────────────┐     ┌─────────────────┐
│ Django API   │   │ Flask Voice/ML   │     │ Rasa Service    │
│ Port 8000    │   │ Port 5002        │     │ Port 5005       │
│ DRF views    │   │ CNN intent clf   │     │ FAQ chatbot     │
│ accounts/*   │   │ spaCy NER+regex  │     │ DIET (default)  │
│ Money logic  │   │ STATELESS        │     │ 12 intents      │
└──────┬───────┘   └──────────────────┘     └─────────────────┘
       │ ORM
       ▼
┌──────────────┐
│ PostgreSQL 15│  Port 5432
│ echopay_db   │
└──────────────┘
```

**Key architectural decision to articulate:** *Flask is a pure classifier — it does NOT call Django to move money.* The Flutter app orchestrates: it asks Flask "what does the user want?", gets back an action + entities, then calls Django itself. (Note: `docker-compose.yml` sets `DJANGO_BASE_URL` env on the Flask container, suggesting an earlier design where Flask called Django directly — be ready to explain this is now unused; the current `flask_server.py` never reads it.)

**Ports cheat-sheet:** Django 8000, Flask 5002, Rasa 5005, Postgres 5432.

**Tech versions:** Flutter SDK ^3.8.1, Django 5.1.6, DRF, Flask 2.3.3, TensorFlow 2.17, spaCy 3.6, Rasa 3.6.0, PostgreSQL 15.

---

## 3. END-TO-END FLOWS

### 3.1 Onboarding (phone → OTP → name → biometric)
1. `PhoneNumberPage` — user enters number, picks country code (default +91). `GET /accounts/send_otp/?phone=+91...`.
2. Django `send_otp`: deletes old OTPs for that phone, generates a 6-digit OTP, stores in `OTP` table, returns it in the JSON response **(only because `DEBUG=True`)**. No SMS is actually sent (there's a `# TODO: integrate SMS` and unused Twilio settings).
3. `VerifyOtpPage` — 6 boxes, auto-advance, auto-submit on last digit, 30s resend timer, shake animation on error. `GET /accounts/verify_otp/?phone=...&otp=...`.
4. Django `verify_otp`: finds most recent OTP across phone-format candidates, checks `is_valid()` (≤10 min & not used), matches code, marks verified, then checks if a `User` exists → returns `isNewUser`.
5. If new → `NameEntryPage` → `POST /accounts/signup/` (creates `User` + `UserAccount` with **₹5000 default balance**). If existing → straight to biometric.
6. `BiometricAuthScreen` (in `main.dart`) — `local_auth` fingerprint/face. On success sets `isLoggedIn=true` in SharedPreferences and goes to the dashboard.

### 3.2 Voice payment (the headline feature)
1. `VoiceAssistantPage` → `SpeechScreen` (`voiceToText.dart`).
2. `speech_to_text` package converts speech → text on device.
3. On `finalResult`, app calls `IntentService.processVoiceCommand(text)`.
4. That POSTs to Flask `/voice_command` with `{text, userPhone}`.
5. Flask `predict_intent` → preprocess → tokenize → pad → CNN `model.predict` → argmax → `(intent, confidence)`.
6. **Confidence gate (70%):**
   - `< 70%` → response `action: route_to_rasa`. App forwards text to Rasa, shows the chatbot reply.
   - `≥ 70%` & `transfer_money`/`request_money` → Flask runs `extract_entities` (regex amount/phone/UPI/name + optional spaCy keywords), returns `action` + `entities`.
   - `≥ 70%` & `check_balance` → returns `action: check_balance`.
7. App maps action: shows a confirmation bottom-sheet (transfer/request) or proceeds.
8. On confirm → **biometric prompt** → app calls Django `sendMoneyPhone` / `sendMoneyId` / `createMoneyRequest` / `getBalance`.
9. Django moves the money, writes a `Transaction`, returns success → app shows success dialog.

### 3.3 Manual pay (e.g., pay to phone)
`PayToPhonenumberPage` → search user (`searchPhonenumber`) → enter amount → `POST sendMoneyPhone`. **Note: manual flows do NOT trigger biometric** (only the voice flow does — a real inconsistency to own; see Weak Links).

---

## 4. FLUTTER APP DEEP DIVE

> You asked for extra depth on Flutter. This section is intentionally large.

### 4.1 Project structure
```
App/lib/
├── main.dart                    # App root, theme, routes, biometric gate
├── constants/
│   ├── api_constants.dart       # All backend URLs (hardcoded IP!)
│   ├── app_colors.dart          # Design tokens
│   └── app_typography.dart      # GoogleFonts text styles
├── phone_number_page.dart       # Onboarding step 1
├── verify_otp_page.dart         # Onboarding step 2
├── name_entry_page.dart         # Onboarding step 3 (new users)
├── signup_page.dart
├── normalUPI/                   # Main app surfaces
│   ├── dashboard.dart           # Bottom-nav shell (Home/Voice/Profile)
│   ├── home_page.dart           # Wallet card, quick actions, recent txns
│   ├── voice_assistant_page.dart# Voice landing screen
│   ├── balance_page.dart, history_page.dart, my_qr_page.dart
│   ├── qr_scanner_page.dart, request_money_page.dart
│   └── profile_*.dart
├── payToPhoneNumber/ payToUpiId/ payToContacts/   # Manual transfer flows
├── voiceToText/voiceToText.dart # SpeechScreen — core voice UX
├── services/
│   ├── django_service.dart      # Django API client
│   ├── intent_service.dart      # Flask client + orchestration
│   └── rasa_service.dart        # Rasa client
└── widgets/                     # app_button, app_logo, motion (animations)
```

### 4.2 State management — KNOW THIS
- **There is NO state management library** (no Provider, Riverpod, BLoC, GetX).
- Everything is `StatefulWidget` + `setState`.
- Cross-screen "state" (who is logged in, phone number, name, UPI ID) is persisted in **`SharedPreferences`** and re-read on each screen.
- Keys used: `isLoggedIn` (bool), `phoneNumber`, `userName`, `upiId`, `biometricEnabled`.

**Likely question: "Why no state management?"**
> "The app's shared state is small and mostly identity data, so I used SharedPreferences as a lightweight local store and kept screen-local UI state in setState. For a production app with a global balance, transaction cache, and live updates, I'd move to Riverpod or BLoC to avoid prop-drilling and re-fetching on every screen — right now each screen independently reads SharedPreferences and re-hits the API, which is wasteful."

### 4.3 Navigation
- Named routes declared in `main.dart`: `/phone`, `/verify-otp`, `/name-entry`, `/biometric`, `/main`.
- `initialRoute` is chosen by `isLoggedIn`: logged-in users go to `/biometric` first, new users to `/phone`.
- Deeper screens use imperative `Navigator.push(MaterialPageRoute(...))`.
- The dashboard uses an **`Indexed-like AnimatedSwitcher`** (not `IndexedStack`) with `KeyedSubtree` to fade between Home/Voice/Profile. **Caveat:** because it swaps the child widget (not `IndexedStack`), tab pages are rebuilt and lose their state on switch — be ready to mention this trade-off.

### 4.4 The biometric flow (`main.dart` + `voiceToText.dart`)
- Uses `local_auth` (`LocalAuthentication`).
- `BiometricAuthScreen` checks `isDeviceSupported()`, `canCheckBiometrics`, `getAvailableBiometrics()`. On any failure it calls `_navigateDirectly()` — i.e., **it lets you in without biometrics if the device has none**.
- In `voiceToText.dart`, `_authenticateWithBiometrics` returns `true` (success) when `!canUseBiometrics || !isDeviceSupported`. **This means on a device without biometrics, money moves with no auth.** (Weak link — see §12.)
- `AuthenticationOptions(biometricOnly: false, ...)` → falls back to **device PIN/pattern**, not biometric-only. Worth knowing.

### 4.5 Voice / speech recognition (`voiceToText.dart`)
- Package: `speech_to_text: 7.1.0`. STT runs **on-device** (Android `SpeechRecognizer` / iOS `Speech`), so there's no audio sent to your servers — only the transcribed *text* goes to Flask. Good privacy point.
- `_speech.listen(onResult: _onSpeechResult)`; you process only when `result.finalResult` is true and server is connected.
- A `_pulseController` drives the listening animation; mic button toggles `_startListening`/`_stopListening`.
- After transcription → `IntentService.processVoiceCommand`. Then UI branches on `action`: `initiate_transfer` → confirmation sheet, `show_balance` → biometric + balance dialog, `initiate_request` → request sheet, `chatbot` → show text.

**Likely question: "Is the speech recognition your own model?"**
> "No — speech-to-text is handled by the platform's on-device engine through the `speech_to_text` plugin. My ML work is the *intent classification and entity extraction* on the transcribed text. I deliberately kept audio on-device for privacy and latency; only text leaves the phone."

### 4.6 Networking
- Plain `http` package (no Dio, no interceptors, no retry).
- Three service classes wrap the calls. They catch errors and return a `{status, message}` map rather than throwing.
- **No auth headers / tokens** anywhere — requests are identified purely by `phoneNumber` in the body/query.
- `print()` statements log full request/response (including phone numbers) — should be stripped for production.

### 4.7 `api_constants.dart` — the configuration smell
```dart
const String DJANGO_BASE_URL = 'http://192.168.0.109:8000';   // hardcoded LAN IP
const String INTENT_API_URL  = 'http://192.168.0.109:5002';
const String RASA_BASE_URL   = 'http://192.168.0.109:5005';
```
- URLs are **hardcoded to a developer's local IP** and use **HTTP, not HTTPS**.
- README says to change these per environment (emulator `10.0.2.2`, etc.).
- Production needs: env-based config (`--dart-define`), HTTPS, a real domain. Own this openly.

### 4.8 QR scanning (`qr_scanner_page.dart`)
- `mobile_scanner` for camera, `permission_handler` for camera permission, `image_picker` for gallery (gallery scan is a **"coming soon" stub** — it just shows a snackbar).
- Parses standard UPI deep links: `upi://pay?pa=...&pn=...&am=...` via `Uri.queryParameters` → keys `pa` (payee address), `pn` (name), `am` (amount).
- On "Proceed to pay" it pushes `PayToUpiIdPage` with prefilled fields.

### 4.9 Indian number formatting (nice detail to show off)
`home_page.dart` `_inr()` implements **Indian digit grouping** (lakh/crore: `12,48,000.00`) manually — last 3 digits, then groups of 2. Mention this as attention to locale detail.

### 4.10 Animations / polish
- `widgets/motion.dart` defines `AppMotion` curves/durations, `Pressable` (scale-on-tap), `Entrance`/`Stagger` (entrance animations), `Shimmer`/`SkeletonBar` (loading skeletons).
- `home_page.dart` uses `AnimatedSwitcher` for hide/show balance crossfade, `RefreshIndicator` for pull-to-refresh, and respects `MediaQuery.disableAnimations` (reduce-motion accessibility) — good talking point.

### 4.11 Dependencies (`pubspec.yaml`) — be able to justify each
| Package | Why |
|---|---|
| `speech_to_text` | On-device STT |
| `local_auth` | Biometric/PIN auth |
| `http` | REST calls |
| `shared_preferences` | Local persistence / session |
| `flutter_contacts` | Pay-to-contact |
| `permission_handler` | Camera/contacts permissions |
| `mobile_scanner` | QR scan |
| `qr_flutter` | Render *my* QR |
| `image_picker` | Pick QR from gallery |
| `google_fonts` | Typography (Sora, Plus Jakarta Sans) |
| `avatar_glow`, `highlight_text` | Voice UI flourish |

### 4.12 Flutter fundamentals they may quiz (have crisp answers)
- **StatelessWidget vs StatefulWidget**; `setState` triggers `build`.
- **Widget lifecycle:** `initState` → `didChangeDependencies` → `build` → `dispose`. You use `initState` to kick off async loads and `dispose` to free `AnimationController`s and `TextEditingController`s (you do this correctly — point it out).
- **`mounted` checks:** you guard `setState` with `if (mounted)` after `await` to avoid "setState after dispose" — call this out; it's a common bug you avoided.
- **`Future`/`async`/`await`**, `FutureBuilder` (you mostly use manual loading bools instead).
- **BuildContext across async gaps:** `if (!mounted) return;` before using `context` post-await — you do this.
- **Keys** (`ValueKey` in AnimatedSwitcher), **hot reload vs hot restart**.
- **`const` constructors** for performance (you use them heavily).

---

## 5. FLASK ML SERVICE

File: `Backend/ml-server/flask_server.py`

### 5.1 What it does
- Loads at startup: `intent_model.h5` (Keras), `tokenizer.pkl`, `label_encoder.pkl`, `max_len.pkl`, and the spaCy NER model from `keyword_ner_model/`.
- If model files fail to load → `exit(1)`. If NER missing → continues with `nlp=None` (graceful degrade).
- CORS enabled for all origins (`CORS(app)`).

### 5.2 Endpoints
| Endpoint | Method | Purpose |
|---|---|---|
| `/` | GET | Service banner + endpoint list |
| `/health` | GET | Reports intent_classifier + ner_model status |
| `/voice_command` | POST | **Main** — classify + (entities) + action |
| `/predict` | POST | Legacy: returns `[prediction, {keywords}]` |
| `/predict_batch` | POST | Classify a list of texts |
| `/chatbot` | POST | Deprecated stub (says "use Rasa") |

### 5.3 `predict_intent(text)` pipeline
1. `preprocess_text`: lowercase, strip punctuation (`[^\w\s]`), collapse whitespace.
2. `tokenizer.texts_to_sequences([clean_text])`.
3. `pad_sequences(..., maxlen=max_len=20, padding='post')`.
4. `model.predict` → `np.argmax` → `label_encoder.inverse_transform` → intent + `float(prob)` confidence.

### 5.4 The 70% confidence gate (CORE design decision — expect deep questions)
```python
if confidence_percentage < 70.0:
    response["action"] = "route_to_rasa"   # casual / out-of-scope
else:
    # branch on transfer_money / request_money / check_balance
```
- Rationale: the CNN only knows 3 payment intents. Anything else (greetings, FAQs, gibberish) should fall through to Rasa. The threshold is the **only** thing separating "real command" from "everything else."
- **This is the most attackable design point.** See §6.4 and §12.1.

### 5.5 `extract_entities(text, intent)` — regex-first
For `transfer_money`/`request_money`:
- **Amount:** several regexes for `rs/rupees/₹` + digits → `float`.
- **Phone:** matches 10/11-digit or `+91...`; normalizes to `+91` + last 10 digits.
- **UPI ID:** `([a-zA-Z0-9._-]+@[a-zA-Z]+)`.
- **Recipient name:** patterns like `to/send/pay/give <name>`, filtered against a stop-list (`money`, `cash`, `the`, `my`, ...).
- **Then** if `nlp` exists, adds `entities["ner_keywords"]` from spaCy — but the *actual* downstream logic uses the regex fields, not the NER output. (See §7 / §12.9.)

---

## 6. CNN INTENT CLASSIFIER

File: `Backend/Intent_classifier/model_training.ipynb`, dataset `voice_upi_dataset.csv`.

### 6.1 Dataset
- **~853 rows**, columns `text, intent`.
- 3 balanced classes: `transfer_money` (~270), `request_money` (~276), `check_balance` (~300).
- **Synthetically generated** (`dataset_gen.ipynb`) — templated sentences. Be honest about this.

### 6.2 Preprocessing & vectorization
- Clean text (same as Flask).
- `Tokenizer(num_words=5000, oov_token="<unk>")` fit on training set.
- `pad_sequences(maxlen=20, padding='post')`.
- `LabelEncoder` for the 3 classes.
- `train_test_split(test_size=0.2, stratify=y, random_state=42)`.

### 6.3 Model architecture (memorize this)
```python
Sequential([
  Embedding(vocab_size, 100, input_length=20),  # 100-dim embeddings
  Conv1D(filters=128, kernel_size=5, activation='relu'),
  GlobalMaxPooling1D(),
  Dropout(0.5),
  Dense(64, activation='relu'),
  Dense(3, activation='softmax')
])
# optimizer=adam, loss=sparse_categorical_crossentropy, metrics=[accuracy]
# EarlyStopping(monitor='val_accuracy', patience=5, restore_best_weights=True)
# epochs=20, batch_size=32, validation_split=0.1
```

**Be able to explain every layer:**
- **Embedding:** maps each token id → a learned 100-d vector. `vocab_size = len(word_index)+1`.
- **Conv1D (128 filters, kernel 5):** each filter slides over windows of 5 consecutive word-embeddings → detects local n-gram patterns ("send X to", "my balance"). 128 feature maps.
- **GlobalMaxPooling1D:** takes the max activation of each filter across the sentence → "did this pattern appear anywhere?" → fixed-length 128-vector, length-invariant.
- **Dropout(0.5):** regularization — randomly zeroes half the units in training to fight overfitting.
- **Dense(64, relu) → Dense(3, softmax):** classifier head; softmax gives a probability over the 3 intents.

### 6.4 Results & the overfitting story (CRITICAL — interviewers love this)
- Training hits **val_accuracy = 1.0000 by epoch 2–3**, val_loss → ~0.0018.
- But **test accuracy ≈ 0.90** (`model.evaluate` → 0.9044).
- The gap (val 100% vs test 90%) + perfect val accuracy in 2 epochs = **the model is memorizing templated patterns**, not learning robust language understanding.
- Notebook test predictions reveal the real problem:
  - `"How are you?"` → **check_balance, 0.54**
  - `"whats the weather like today?"` → check_balance, 0.38
  - `"Go fuck yourself"` → check_balance, 0.40
  - i.e., **out-of-domain text gets classified as a payment intent**, just usually below 70% confidence.
- This is exactly *why* the 70% gate exists — it's a band-aid for the lack of a "none/other" class.

### 6.5 Why CNN for text? (be ready)
> "A 1D-CNN over word embeddings is a strong, cheap baseline for short-text intent classification. The conv filters capture key phrases regardless of position, GlobalMaxPool makes it length-invariant, and it trains in seconds. For 3 intents on short commands it's plenty. If I needed nuance or many intents I'd move to a fine-tuned transformer (DistilBERT) — but that's heavier to host."

### 6.6 There's also a LogisticRegression alternative
The notebook has a commented/secondary cell training a **TF-IDF + LogisticRegression** "lightweight model" for cheaper hosting (it errors in the saved notebook because `X_train` wasn't in scope, but the intent is there). Mention you considered a lighter classical model for deployment cost.

---

## 7. SPACY NER MODEL

Folder: `Backend/keyword_ner_model/` (config.cfg, meta.json, ner/, vocab/, tokenizer).

- A **custom-trained spaCy NER pipeline** with only an `ner` component.
- **Labels: `AMOUNT`, `RECIPIENT`** (from `meta.json`).
- spaCy 3.8-trained, blank vectors (`width:0`) — small model.
- In Flask it's loaded via `spacy.load(NER_MODEL_PATH)` and used to add `ner_keywords`.

**The honest truth (and a great "what would you improve" answer):** The trained NER model is **barely wired in**. The transfer logic relies on the **regex** amount/phone/name. The NER output is only appended as `ner_keywords` and never actually consumed by the action logic. So you built and trained a NER model but the production path uses regex. → strong improvement story: "consolidate entity extraction onto the NER model and drop the brittle regex."

---

## 8. RASA

Folder: `Rasa/` (config.yml, domain.yml, data/nlu.yml, stories.yml, rules.yml, actions/actions.py).

### 8.1 What it actually is
- **An FAQ/smalltalk bot**, not a transactional bot. It handles greetings and questions *about* the app.
- **12 intents:** `greet, goodbye, affirm, deny, bot_challenge, ask_app_features, ask_voice_upi, ask_voice_payment_steps, ask_manual_upi, ask_upi_safety, ask_transaction_limits, ask_help, fallback`.
- Responses are **static `utter_` templates** in `domain.yml`.
- **No custom actions** — `actions/actions.py` is entirely commented-out boilerplate. So Rasa never moves money or hits Django.

### 8.2 Config
- `config.yml`: `recipe: default.v1`, `language: en`, **`pipeline: null` and `policies: null`** → Rasa fell back to the **default pipeline** (WhitespaceTokenizer, RegexFeaturizer, CountVectorizers, **DIETClassifier**, FallbackClassifier@0.3) and default policies (Memoization, Rule, TED, UnexpecTED). Know that DIET is the default intent+entity classifier.
- `credentials.yml`: has a `rest:` channel (the app calls `/webhooks/rest/webhook`) and a leftover `rasa: url: http://localhost:5002/api`.
- `endpoints.yml`: everything commented (no action server, in-memory tracker store).
- Trained models in `Rasa/models/*.tar.gz`; docker mounts `./Rasa/models`.

### 8.3 App ↔ Rasa contract (`rasa_service.dart`)
- POST `{sender:'user', message:text}` to `/webhooks/rest/webhook`.
- **All sessions use the same `sender: 'user'`** → everyone shares one conversation tracker. (Weak link — should be the user's id.)
- Rasa returns an array `[{text:...}]`; app takes the first text.

**Likely question: "Why two NLU systems (CNN + Rasa)?"**
> "They serve different jobs. The CNN is a fast, specialized classifier for the 3 money intents where I control the training data and the action mapping. Rasa handles open-ended conversation and FAQs — greetings, 'is this safe', 'how do voice payments work'. The 70% confidence gate decides which engine answers. In hindsight, Rasa's DIET could have done both, so a cleaner design is one NLU engine; I split them partly to keep the payment classifier tightly controlled and partly because the two were built at different times."

---

## 9. DJANGO BACKEND

Folder: `DJBackend/`, app `accounts/`.

### 9.1 Models (`accounts/models.py`)
- **`OTP`**: `phoneNumber`, `otp`(6), `created_at`, `is_verified`. `is_valid()` = within 10 min AND not verified.
- **`User`**: `phoneNumber`(unique), `upiName`, `upiMail`(EmailField, unique). *Note: this is a plain model, **not** Django's `auth.User` — no passwords, no auth integration.*
- **`UserAccount`**: FK→User, `balance` Decimal(10,2) **default 5000.00**, timestamps. (Note FK not OneToOne → a user could technically have multiple accounts.)
- **`Transaction`**: `sender`/`receiver` FK→UserAccount, `amount`, `timestamp`, `status` (pending/completed/failed).
- **`MoneyRequest`**: `requester`/`requestee` FK→UserAccount, `amount`, `message`, `status` (pending/approved/rejected/cancelled), timestamps.

### 9.2 Views (`accounts/views.py`) — all function-based, DRF `@api_view`
Auth/onboarding: `send_otp`, `verify_otp`, `SignUp`.
Lookup: `searchNumber`, `searchByUpiId`, `getProfile`, `getBalance`, `checkHasAccount`.
Money: `sendMoneyId`, `sendMoneyPhone`, `getTransactions`.
Requests: `createMoneyRequest`, `createMoneyRequestByUpi`, `getMoneyRequests`, `updateRequestStatus`.

**Phone normalization helpers (good detail):**
- `canonicalize_phone_number` → always store as `+91XXXXXXXXXX`.
- `get_phone_candidates` → builds a set of formats (`+91...`, `91...`, 10-digit, raw) so lookups match regardless of how the number was entered. Used via `get_user_by_phone`.

**Money transfer logic (`sendMoneyPhone`):**
```python
amount = Decimal(str(request.data.get('amount')))
# find sender & receiver accounts...
if sender_account.balance < amount: return 400 Insufficient
sender_account.balance -= amount
receiver_account.balance += amount
sender_account.save(); receiver_account.save()
Transaction.objects.create(... status='completed')
```
**No `transaction.atomic()`, no `select_for_update()`** → race conditions & partial-failure risk (see §12.2). Confirmed: grep for `atomic`/`select_for_update` returns nothing.

**`updateRequestStatus`** does have decent **authorization checks**: only requester can cancel; only requestee can approve/reject; can't reprocess a non-pending request; on approve it checks balance and moves funds. This is the most "correct" view — highlight it.

### 9.3 URLs (`accounts/urls.py`)
All under `/accounts/` prefix. Endpoints are camelCase paths (e.g., `/accounts/sendMoneyPhone/`).

### 9.4 settings.py — the production red flags
- `SECRET_KEY` hardcoded in source.
- `DEBUG = True`.
- `ALLOWED_HOSTS = [..., '*']`.
- `CORS_ALLOW_ALL_ORIGINS = True`, `CORS_ALLOW_CREDENTIALS = True`.
- **DRF default: `AllowAny` permissions, empty `DEFAULT_AUTHENTICATION_CLASSES`** → **every endpoint is unauthenticated.**
- DB config parsed from `DATABASE_URL` (postgres). Twilio settings read from `.env` but **never used** (SMS not implemented).

---

## 10. DOCKER / DEVOPS

### 10.1 docker-compose.yml — 4 services
- **db**: `postgres:15`, healthcheck `pg_isready`, named volume `echopay_postgres_data`.
- **django**: builds `./DJBackend`, port 8000, `depends_on db (healthy)`, mounts `./DJBackend:/app` (live code), env sets `DEBUG=1` and DB creds.
- **flask**: builds `./Backend`, port 5002, `depends_on django`, env `DJANGO_BASE_URL=http://django:8000/accounts` (unused by current code).
- **rasa**: builds `./Rasa`, port 5005, mounts models, command `run --enable-api --cors "*" --debug`.
- All on a bridge network `echopay_network`; healthchecks via curl.

### 10.2 Dockerfiles
- **Django**: `python:3.11-slim`, installs `postgresql-client/curl/dos2unix`, `entrypoint.sh` waits for Postgres (`pg_isready` loop) → `makemigrations` + `migrate` → `collectstatic` → runs `runserver 0.0.0.0:8000`. *(Dev server, not gunicorn — noted in a comment.)*
- **Flask**: `python:3.11-slim`, pip installs `requirements.txt` (TF 2.17, torch, spacy...), `CMD python flask_server.py` with `debug=True`. Heavy image (TensorFlow + torch).
- **Rasa**: from `rasa/rasa:3.6.0`, copies config/data/models, runs as non-root user 1001.

**Talking points:** migrations auto-run on container start (`makemigrations` in entrypoint is risky — migrations should be committed, not generated at runtime). Dev servers used for both Django and Flask. No reverse proxy (nginx), no TLS, no gunicorn/uvicorn.

---

## 11. SECURITY

Make a **two-column "current vs production"** mental model. Interviewers for a *payments* app will push hard here. Lead with: *"This is a functional prototype; I'm very aware it isn't production-secure, and here's the exact list of what I'd fix."*

| Area | Current state | Production fix |
|---|---|---|
| **API auth** | None. `AllowAny`. Identity = phone number in request body. | JWT/session tokens; bind every action to the authenticated user, ignore client-supplied senderPhone. |
| **Send-from-anyone** | `sendMoneyPhone` trusts `senderPhone` from the client → you can debit *any* account. | Derive sender from the auth token, never the payload. |
| **OTP** | Returned in API response, no SMS, visible in admin. | Real SMS (Twilio), never return OTP, rate-limit, hash it. |
| **Transport** | HTTP, hardcoded LAN IP. | HTTPS + domain + cert pinning. |
| **Secrets** | `SECRET_KEY` in source, `DEBUG=True`. | Env vars/secret manager, `DEBUG=False`. |
| **Biometric** | Skipped if device lacks biometrics; not on manual flows. | Enforce app-lock + PIN fallback; gate *all* money movement. |
| **Session** | Phone stored plaintext in SharedPreferences. | Secure storage (`flutter_secure_storage`), token w/ expiry. |
| **Atomicity** | No DB transaction around debit/credit. | `transaction.atomic()` + `select_for_update()`. |
| **Idempotency** | None — double-submit double-pays. | Idempotency keys per transfer. |
| **Rate limiting** | None on OTP/transfer. | Throttling (DRF throttles / gateway). |
| **PII in logs** | `print()` logs phone numbers + bodies. | Structured logging, redact PII. |

---

## 12. ⚠️ WEAK LINKS & MISSING PIECES

> These are the things an interviewer who reads the code will pounce on. For each: **the issue**, **why it matters**, and **a talking script** that turns it into a "I understand my system's limits" moment. Owning these proactively is far stronger than getting caught.

### 12.1 The 70% threshold is a band-aid for a missing "none" class
**Issue:** The CNN has only 3 classes and no "other/none" class, so *every* input is forced into a payment intent. Out-of-domain text ("how are you", insults, weather) gets a payment label, just usually <70% confidence. The threshold is the sole guard.
**Why it matters:** Softmax is overconfident; an out-of-domain sentence could exceed 70% and trigger a money action. A casual question could also be misrouted.
**Script:**
> "The classifier is closed-set — it always predicts one of three intents. I handle open-domain input with a 70% confidence gate that routes low-confidence text to Rasa. That works in practice but it's a heuristic, not a real solution. The right fix is to add a 'none/other' class trained on negative examples, or use an out-of-distribution detector, or let Rasa's DIET be the single front door with a proper fallback intent. I chose the threshold because it was fast and my dataset is clean, but I know its failure mode: an overconfident softmax on an out-of-domain phrase."

### 12.2 No atomic transaction on money transfer (the big one for a payments app)
**Issue:** Debit and credit are two separate `.save()` calls with no `transaction.atomic()` / `select_for_update()`. If the second save fails, the sender is debited but receiver not credited. Two concurrent transfers can read a stale balance → overdraft (lost update / race condition).
**Script:**
> "My transfer does a read-modify-write on two rows without a DB transaction or row lock. That's the most serious correctness bug for a payments system — it's vulnerable to partial failure and to the classic lost-update race under concurrency. The fix is to wrap the debit, credit, and Transaction insert in `transaction.atomic()` and use `select_for_update()` to lock both account rows, plus a balance check inside the lock. I'd also add an idempotency key so a client retry can't double-charge."

### 12.3 You can send money FROM anyone's account (authz hole)
**Issue:** `senderPhone` comes from the request body and is fully trusted. With no auth, an attacker can POST `sendMoneyPhone` with someone else's `senderPhone`.
**Script:**
> "Right now the API trusts the client to say who the sender is. In production the sender must come from the authenticated session/token, never the payload. This is the #1 thing I'd fix before anyone touches real money."

### 12.4 Voice "pay to a name" doesn't actually work end-to-end
**Issue:** For `"send 500 to John"`, the entity extractor returns `recipient_name="John"`. But `voiceToText.dart._executeMoneyTransfer` only handles two cases: recipient contains `@` → UPI; otherwise it treats it as a phone number and prepends `+91` → `"+91John"`, which Django can't resolve. **There's no name→user lookup.** So voice pay only works with a spoken phone number or UPI ID, not a contact name.
**Script:**
> "Voice pay by *name* is incomplete. I extract the name, but I never resolve it against the user's contacts or a directory — the transfer path assumes a phone number or UPI ID. To finish it I'd match the recognized name against `flutter_contacts` (and disambiguate with a confirmation list) before sending. The demo works with spoken numbers/UPI IDs."

### 12.5 Overfitting / synthetic dataset
**Issue:** 100% val accuracy in 2 epochs, 90% test, templated synthetic data (~850 rows). Real speech (accents, STT errors, code-mixing Hindi/English) isn't represented.
**Script:** (see §6.4) — "I know it's memorizing templates; real STT output is noisier. I'd collect real utterances, add Hinglish, augment, and add a none class."

### 12.6 Dead code paths
**Issue:** `general_conversation` action is handled in both Flask and `intent_service.dart`, but the model can never output it (not a class). `DJANGO_BASE_URL` env on Flask is unused. The `/chatbot` Flask endpoint is a deprecated stub.
**Script:** "There's vestigial code from an earlier design where Flask called Django and had a conversation class — I refactored to make Flask stateless and let the app orchestrate, but didn't fully prune the old branches."

### 12.7 Biometric is bypassable & inconsistent
**Issue:** Auth returns success when the device has no biometrics; manual pay flows skip biometric entirely (only voice flow has it).
**Script:** "Biometric gating is inconsistent — it's on the voice flow but not the manual transfer screens, and it soft-passes on devices without biometrics. I'd enforce a mandatory app-lock with PIN fallback on every money-moving action."

### 12.8 Shared Rasa conversation / no session isolation
**Issue:** `rasa_service.dart` hardcodes `sender: 'user'` → all users share one Rasa tracker.
**Script:** "Every device sends the same Rasa sender id, so conversation state is global. I'd use the user's phone/UPI id as the sender id. It doesn't bite today because responses are stateless FAQs, but it's wrong."

### 12.9 Trained NER model is essentially unused
**Issue:** Entity extraction in production is regex; the spaCy AMOUNT/RECIPIENT model only contributes `ner_keywords` that nothing consumes. (see §7).
**Script:** "I trained a NER model but the live path is regex — I'd consolidate on the NER model and delete the regex, since regex is brittle for amounts like 'fifteen hundred' or names."

### 12.10 Money as float over the wire
**Issue:** Flutter sends `amount` as a JSON number (double). Django does `Decimal(str(amount))` (good — converts via string), but the float origin can still introduce representation issues for values like 0.1.
**Script:** "I convert to Decimal on the server via str() to avoid binary-float drift, but ideally the client sends amount as a string in minor units (paise) and the server works in integers/Decimal end-to-end."

### 12.11 No tests
**Issue:** `accounts/tests.py` empty; `widget_test.dart` is the default counter test; `Rasa/tests/test_stories.yml` exists but minimal.
**Script:** "Test coverage is a gap. For a payments app I'd prioritize unit tests on the transfer logic (insufficient balance, atomicity, concurrency), API contract tests, and an integration test of the voice→intent→action path."

### 12.12 `UserAccount` is FK not OneToOne; `upiMail` is an EmailField holding `name@upi`
**Issue:** FK allows multiple accounts per user; `name@upi` isn't a real email (no TLD) — relies on loose EmailField validation.
**Script:** "`UserAccount` should be OneToOne with `User`. And I overloaded `upiMail` (an EmailField) to store a UPI handle like `jefin@upi`, which is a modeling smell — a dedicated `upi_id` CharField with a validator would be correct."

### 12.13 Auto `makemigrations` at container startup
**Issue:** `entrypoint.sh` runs `makemigrations` on every boot — migrations should be authored and committed, not generated in the container.
**Script:** "Generating migrations at runtime is risky; I'd remove `makemigrations` from the entrypoint and ship committed migration files, running only `migrate`."

### 12.14 Dev servers, no WSGI/ASGI server, no HTTPS
Flask `debug=True` and Django `runserver` are dev-only. Production needs gunicorn/uvicorn + nginx + TLS.

---

## 13. RAPID-FIRE Q&A BANK

**Architecture**
1. *Why microservices?* → separation of concerns; ML deps (TF/torch) isolated from the web API; can scale/replace independently.
2. *Why is Flask stateless?* → easier to scale horizontally, no DB coupling; the app orchestrates.
3. *What if Flask is down?* → `checkServerHealth` shows "offline"; voice command won't process (it only runs when `_serverConnected`).
4. *What if Django is down?* → transfers/balance fail with a network-error message; UI shows error chip.
5. *Could you merge the 3 services?* → yes for a small app; kept separate for dependency isolation & team boundaries.

**Flutter**
6. *setState vs Provider?* → see §4.2.
7. *How is the user kept logged in?* → `isLoggedIn` in SharedPreferences; `initialRoute` branches on it.
8. *Where's the phone number stored?* → SharedPreferences `phoneNumber`, used as identity in API calls.
9. *How does OTP auto-submit work?* → on 6th box change, join controllers, if length 6 call `_verifyOtp`.
10. *How do you avoid setState-after-dispose?* → `if (mounted)` guards after awaits.
11. *How does pull-to-refresh work?* → `RefreshIndicator` → `_refresh` re-fetches balance + txns.
12. *Why GoogleFonts?* → Sora (headings) + Plus Jakarta Sans (body); consistent typography without bundling fonts.
13. *How does the app know which screen to show first?* → `initialRoute` from `isLoggedIn`.

**ML / NLP**
14. *Explain Conv1D over text.* → filters detect n-gram phrase patterns over embeddings.
15. *Why GlobalMaxPooling?* → position-invariant "was this feature present" + fixed-length output.
16. *Why dropout 0.5?* → strong regularization on a small dataset.
17. *Softmax vs sigmoid?* → softmax = mutually-exclusive multiclass (one intent).
18. *sparse_categorical_crossentropy vs categorical?* → labels are integers, not one-hot.
19. *What's `oov_token`?* → unknown words → `<unk>` so unseen tokens don't crash.
20. *Why max_len=20?* → commands are short; pad/truncate to 20 tokens.
21. *How do you measure model quality?* → accuracy + (should add) precision/recall/F1/confusion matrix.
22. *What's DIET (Rasa)?* → Dual Intent & Entity Transformer — Rasa's default joint intent+entity model.
23. *Why a separate NER?* → to pull AMOUNT/RECIPIENT (though regex is what's actually used).

**Django/DB**
24. *Why DecimalField for money?* → exact base-10, no float rounding.
25. *Why Decimal(str(x))?* → avoid binary float error when constructing.
26. *What's `@csrf_exempt` doing on sendMoneyId?* → API called from mobile, no CSRF token; (DRF+AllowAny makes it moot).
27. *How are phone formats reconciled?* → `get_phone_candidates` builds all variants for lookup; `canonicalize_phone_number` for writes.
28. *Default balance?* → ₹5000 (`UserAccount.balance` default) — the "welcome bonus."
29. *OTP expiry?* → 10 minutes, single-use (`is_verified`).
30. *What DB and why?* → PostgreSQL — ACID, relational integrity for financial data.

**Security** (lead with §11 table)
31. *Biggest security risk?* → unauthenticated APIs + client-supplied sender → send-from-anyone.
32. *How would you add auth?* → JWT on login (after OTP), attach to every request, derive identity server-side.

---

## 14. SCALING / SYSTEM DESIGN

If asked "how would you take this to production / 1M users?":
1. **Auth & identity:** OTP→JWT, refresh tokens, server-derived identity.
2. **Correctness:** `transaction.atomic()` + row locks + idempotency keys + a double-entry ledger (don't mutate balances in place — append immutable ledger entries and compute balance).
3. **Serving the API:** gunicorn/uvicorn behind nginx; horizontal scaling; managed Postgres with read replicas; connection pooling (PgBouncer).
4. **ML serving:** put the model behind TensorFlow Serving or a model server; batch requests; cache; or distill to a smaller model; autoscale separately from the API.
5. **Async:** push notifications, SMS, and transaction settlement via a queue (Celery/RabbitMQ/Kafka).
6. **Observability:** structured logs (redact PII), metrics (Prometheus), tracing, alerting.
7. **Real STT/intent:** collect production utterances, retrain with a none-class and Hinglish, monitor drift.
8. **Compliance:** real UPI/bank integration (NPCI), encryption at rest, audit trails, PCI-style controls.
9. **CI/CD:** committed migrations, automated tests, blue-green deploys, IaC.

---

## 15. BEHAVIORAL / PROJECT-STORY QUESTIONS

- **"What was the hardest part?"** → Designing the routing between a closed-set classifier and an open-domain chatbot; getting the confidence gate to feel right; reconciling phone-number formats across the app and DB.
- **"What are you most proud of?"** → The clean separation (stateless ML, app orchestrates, Django owns money); the polished Flutter UX (skeletons, reduce-motion, Indian number formatting, biometric flow).
- **"What would you do differently?"** → One NLU engine; real auth; atomic ledger; finish voice-by-name; consolidate on NER; add tests; env-based config.
- **"What did you learn?"** → End-to-end ML productization (the model is 10% of the work), why payments need transactional rigor, multi-service orchestration with Docker.
- **"Who did what?"** (if team) → be ready to clearly state your contributions vs teammates' (git shows a merge from `jenjose72` and a `chatbot` branch — know which parts are yours).

---

## 16. CHEAT-SHEET (exact facts)

- **Services/ports:** Django 8000, Flask 5002, Rasa 5005, Postgres 5432.
- **Intent classes (3):** transfer_money, request_money, check_balance.
- **Confidence gate:** 70%. Below → Rasa.
- **CNN:** Embedding(100) → Conv1D(128, k=5, relu) → GlobalMaxPool → Dropout(0.5) → Dense(64,relu) → Dense(3,softmax). adam, sparse_categorical_crossentropy.
- **Tokenizer:** num_words=5000, oov `<unk>`, max_len=20, padding post.
- **Dataset:** ~853 rows, synthetic, balanced 3 classes. Train/test 80/20, stratified, seed 42.
- **Results:** val_acc 1.0, test_acc ~0.90.
- **NER:** spaCy, labels AMOUNT + RECIPIENT (regex used in practice).
- **Rasa:** 12 intents, default pipeline (DIET), static responses, no custom actions, single `sender:'user'`.
- **Models:** OTP, User, UserAccount(₹5000 default), Transaction, MoneyRequest.
- **OTP:** 6-digit, 10-min expiry, returned in response (DEBUG), no SMS.
- **Frontend state:** setState + SharedPreferences (no Provider/BLoC).
- **STT:** on-device via `speech_to_text` (only text leaves the phone).
- **Auth:** phone+OTP → biometric unlock; **APIs themselves are unauthenticated (AllowAny)**.
- **Money transfer:** NOT atomic, NOT locked, NOT idempotent — your headline known-issue.

---

## 17. FLUTTER INTERVIEW QUESTION BANK (100 questions)

> Grounded in *this* app where possible, so your answers come with real examples. Format: **Q → short answer**. Drill these out loud.

### A. Dart language (1–15)
1. **What's the difference between `final` and `const`?** → `final` = set once at runtime; `const` = compile-time constant. You use `const` constructors everywhere (e.g., `const SizedBox(height: 12)`) so Flutter can cache & reuse the widget.
2. **What is `late`?** → Declares a non-nullable var initialized later. You use `late final AnimationController _entrance` in `home_page.dart` so a hot-reload can't leave it uninitialized.
3. **What are null-safety operators `?`, `!`, `??`, `?.`, `??=`?** → nullable type / null-assertion / null-coalescing / null-aware access / assign-if-null. Example: `prefs.getString('userName') ?? prefs.getString('upiName')`.
4. **`is` vs `as`?** → `is` checks type (returns bool); `as` casts (throws if wrong). You use `args as Map<String,String>?` in route handling.
5. **What is a `Future`?** → A value available later (async result). Returned by every API call in your services.
6. **`async`/`await` — what does `await` do?** → Suspends the function until the Future completes, without blocking the UI isolate.
7. **What is a `Stream` vs a `Future`?** → Future = one value; Stream = many values over time. `speech_to_text`'s results arrive stream-like via the `onResult` callback.
8. **What is an `isolate`?** → Dart's unit of concurrency with its own memory; no shared state, communicate via messages. Use `compute()` for heavy CPU work off the UI isolate.
9. **Is Dart single-threaded?** → The UI runs on one isolate with an event loop; async work is cooperative, not parallel, unless you spawn isolates.
10. **What's the difference between named and positional parameters?** → `{}` named (optional/required-named via `required`), `[]` optional positional. Your widgets use `required this.phoneNumber`.
11. **What are mixins?** → Reusable behavior added with `with`. You use `with SingleTickerProviderStateMixin` to get a `vsync` for animations.
12. **`SingleTickerProviderStateMixin` vs `TickerProviderStateMixin`?** → Single = one AnimationController; Ticker (plural) = multiple. `voice_assistant_page` uses `TickerProviderStateMixin` (two controllers); `verify_otp_page` uses Single.
13. **What are records and pattern-matching (Dart 3)?** → Tuples like `(IconData, String, VoidCallback)` — you use them in `home_page.dart`'s `_buildQuickActions` (`items[i].$1`, `.$2`).
14. **What is `dynamic` vs `Object?`** → `dynamic` disables type checks; `Object?` keeps them. Your JSON maps are `Map<String, dynamic>`.
15. **Cascade operator `..`?** → Chains calls on the same object: `AnimationController(...)..repeat(reverse: true)`.

### B. Widgets & rendering (16–32)
16. **StatelessWidget vs StatefulWidget?** → Stateless = immutable, no internal state (`MyHomePage`, `PayToPhonenumberPage` shell). Stateful = has mutable State (`_SpeechScreenState`).
17. **Everything is a widget — explain.** → UI, layout, padding, even the app, are widgets composed into a tree.
18. **What are the 3 trees?** → Widget tree (config), Element tree (instances/lifecycle), Render tree (layout & paint).
19. **Why are widgets immutable?** → Cheap to rebuild; Flutter diffs new widget config against elements and only repaints what changed.
20. **What does `build()` return and how often is it called?** → A widget subtree; called on every `setState`, dependency change, parent rebuild, hot reload.
21. **`Column`/`Row` main vs cross axis?** → Column main axis = vertical; Row main axis = horizontal. `mainAxisAlignment` / `crossAxisAlignment` control spacing/alignment.
22. **What is `Expanded` / `Flexible`?** → Distribute remaining space in a Row/Column. You use `Expanded` for nav items and the phone input.
23. **`Expanded` vs `Spacer`?** → `Spacer` = flexible empty space; `Expanded` wraps a child. You use `const Spacer()` in the voice page.
24. **Difference between `SizedBox`, `Padding`, `Container`?** → SizedBox = fixed size/gap; Padding = inset; Container = combo (size+decoration+padding+margin).
25. **What is `BoxDecoration`?** → Paints background color, border, radius, shadow on a Container — used heavily for your card/chip styling.
26. **`SafeArea` — what for?** → Insets content past notches/status bars. Used in nearly every screen.
27. **`Stack` and `Positioned`?** → Overlapping children; Positioned places them. The wallet card glow and QR overlay use Stack.
28. **`ListView` vs `Column`?** → ListView scrolls & lazily builds; Column doesn't scroll. You use `ListView.separated` (horizontal samples) and `SingleChildScrollView` for forms.
29. **`ListView.builder` — why?** → Lazy item creation for long/infinite lists (performance) vs building all children up front.
30. **What is `MediaQuery`?** → Screen size, padding, text scale, `disableAnimations`. You read `MediaQuery.disableAnimations` for reduce-motion accessibility.
31. **`Theme.of(context)` — what is it?** → Inherited app theme (colors, text styles) defined in `main.dart`'s `MaterialApp.theme`.
32. **What's an `InheritedWidget`?** → Propagates data down the tree efficiently; `Theme`, `MediaQuery`, and Provider are built on it. `.of(context)` reads the nearest one.

### C. State management (33–42)
33. **What state management do you use and why?** → `setState` + `SharedPreferences`; small shared state. (Trade-offs in §4.2.)
34. **What does `setState` actually do?** → Marks the element dirty so Flutter schedules a rebuild of that subtree.
35. **What happens if you call `setState` after dispose?** → Exception. You guard with `if (mounted)` after awaits.
36. **`setState` vs Provider vs Riverpod vs BLoC?** → setState = local; Provider/Riverpod = DI + reactive shared state; BLoC = event→state streams for complex flows.
37. **How would you refactor this app to Provider/Riverpod?** → A `AuthProvider` (phone/login), `WalletProvider` (balance/txns cached), screens watch them instead of re-reading SharedPreferences/re-fetching.
38. **Why is re-reading SharedPreferences on every screen bad?** → Repeated async reads + API refetches; no single source of truth; can show stale data.
39. **Where do you keep ephemeral UI state (e.g., `_isListening`)?** → In the `State` object via setState — correct for screen-local UI.
40. **How do you lift state up?** → Move it to a common ancestor and pass callbacks down — or use a provider to avoid prop-drilling.
41. **What is `ValueNotifier`/`ChangeNotifier`?** → Lightweight observable state; `ListenableBuilder` rebuilds on change. You use `ListenableBuilder` on a `FocusNode` in the OTP boxes.
42. **Is `setState` synchronous?** → It synchronously runs its callback, then asynchronously schedules the rebuild for the next frame.

### D. Navigation & routing (43–50)
43. **Named routes vs `Navigator.push`?** → Named (declared in `MaterialApp.routes`: `/phone`, `/verify-otp`, …) vs imperative push of a `MaterialPageRoute`. You use both.
44. **How do you pass data between screens?** → Constructor args (`VerifyOtpPage(phoneNumber:...)`) or route `arguments` (`settings: RouteSettings(arguments: {...})`).
45. **`push` vs `pushReplacement` vs `pushReplacementNamed`?** → push adds; pushReplacement swaps current (used after OTP→biometric so users can't go "back" into auth).
46. **How do you return data from a screen?** → `Navigator.pop(context, result)` and `await` the push.
47. **What is `initialRoute`?** → First route shown; you compute it from `isLoggedIn`.
48. **What's the downside of imperative navigation for deep links?** → Hard to restore state/URLs; `go_router`/Navigator 2.0 solves declarative routing & deep links.
49. **How does back navigation work on Android?** → System back pops the Navigator stack; `WillPopScope`/`PopScope` to intercept.
50. **How do you show a bottom sheet / dialog?** → `showModalBottomSheet` (transfer confirmation) and `showDialog` (success/balance). They return Futures.

### E. Async, networking, JSON (51–62)
51. **How do you make HTTP calls?** → `http` package; `http.get/post`, `jsonEncode`/`jsonDecode`. Wrapped in service classes.
52. **How do you handle errors?** → try/catch returning `{status:'error', message:...}` maps so UI can branch without exceptions.
53. **GET with query params — how?** → `Uri.parse(url).replace(queryParameters: {...})` (used for OTP, balance, search).
54. **POST JSON — headers?** → `headers: {'Content-Type':'application/json'}`, `body: jsonEncode({...})`.
55. **How do you parse JSON in Dart?** → `jsonDecode` → `Map<String,dynamic>`/`List`; you index keys directly (no codegen models).
56. **Why use typed model classes instead of raw maps?** → Compile-time safety, fewer typos; you'd add `fromJson`/`toJson` or `json_serializable`.
57. **How do you avoid blocking the UI during a network call?** → It's async; you show loading bools/spinners (`_isLoading`, `_isProcessing`) and a CircularProgressIndicator.
58. **What's `FutureBuilder` and why didn't you use it much?** → Rebuilds UI on Future states; you opted for manual loading flags — both valid, FutureBuilder reduces boilerplate.
59. **How would you add retry/timeout?** → `.timeout(Duration(...))` + retry loop or use `dio` with interceptors.
60. **How do you cancel an in-flight request?** → `http` doesn't natively; use `http.Client` + `Client.close()`, or `dio` CancelToken.
61. **Concurrent calls — how?** → `await Future.wait([...])`. You use it in `home_page._refresh`.
62. **What's the risk of `print()` in production?** → Leaks PII (phone numbers) to logs; use a logger and strip in release.

### F. Lifecycle & resources (63–70)
63. **State lifecycle order?** → `createState` → `initState` → `didChangeDependencies` → `build` → (`didUpdateWidget`) → `dispose`.
64. **What goes in `initState`?** → One-time setup: start animations, kick off `_loadProfile/_loadBalance`, init speech.
65. **What goes in `dispose`?** → Free controllers (`AnimationController`, `TextEditingController`, `FocusNode`, `Timer`, `MobileScannerController`). You do this in every screen — call it out.
66. **What's the leak if you forget `dispose`?** → Controllers keep ticking/holding memory; "setState after dispose" errors; battery drain from animations.
67. **`didChangeDependencies` vs `initState`?** → didChangeDependencies runs after initState and whenever an InheritedWidget dependency changes (safe place for `MediaQuery`/`Theme` reads).
68. **What is `WidgetsBinding.instance.addPostFrameCallback`?** → Runs code after the first frame paints. You use it to `requestFocus` on the first OTP box and to start the entrance animation.
69. **App lifecycle (background/foreground) — how to observe?** → `WidgetsBindingObserver.didChangeAppLifecycleState` — useful to re-lock the app or pause the camera.
70. **Why is `mounted` important across async gaps?** → After an `await`, the widget may be gone; using `context`/`setState` then crashes — guard with `if (!mounted) return;`.

### G. Forms, input, validation (71–77)
71. **How does form validation work?** → `Form` + `GlobalKey<FormState>`; `TextFormField.validator`; `_formKey.currentState!.validate()`. Used on phone & name pages.
72. **`TextField` vs `TextFormField`?** → TextFormField integrates with Form validation; TextField is standalone (used in OTP boxes & amount fields).
73. **How do you restrict input to digits?** → `inputFormatters: [FilteringTextInputFormatter.digitsOnly]` + `keyboardType: TextInputType.phone/number`.
74. **How do the OTP boxes auto-advance?** → `onChanged` moves focus to next/previous `FocusNode`; auto-submits on the 6th.
75. **How do you manage a `TextEditingController`?** → Create in field/initState, read `.text`, `dispose()` it.
76. **How do you show inline errors?** → `validator` returns a string, or your custom `_errorChip` + `AnimatedSize` for smooth appearance.
77. **How do you dismiss the keyboard?** → `FocusScope.of(context).unfocus()` or tap-outside handling.

### H. Animations & UX polish (78–85)
78. **What's an `AnimationController`?** → Drives a value 0→1 over a duration; needs a `vsync` (TickerProvider). Used for pulse, shake, entrance.
79. **`Tween` and `CurvedAnimation`?** → Tween maps 0→1 to a range (e.g., scale 0.96→1.06); Curve eases it (`AppMotion.inOut`).
80. **`AnimatedBuilder` vs `AnimatedContainer`?** → AnimatedBuilder rebuilds on a controller (mic pulse); AnimatedContainer implicitly animates property changes (OTP box border).
81. **`AnimatedSwitcher` — where & why?** → Crossfade balance hide/show and dashboard tab swaps; needs a `Key` to detect child change.
82. **Implicit vs explicit animations?** → Implicit = `AnimatedFoo` widgets (set a target, it tweens). Explicit = you drive an AnimationController (shake, pulse).
83. **How do you respect reduce-motion?** → Check `MediaQuery.disableAnimations` and skip/disable the entrance `Stagger`.
84. **What is `Hero`?** → Shared-element transition between screens (not used here but commonly asked).
85. **How do you build a skeleton loader?** → A shimmering placeholder (`Shimmer`/`SkeletonBar` in `motion.dart`) shown while `_loadingBalance`/`_loadingTransactions`.

### I. Platform, permissions, plugins (86–92)
86. **How do permissions work?** → `permission_handler`: `Permission.camera.request()`; handle denied with a settings dialog (`openAppSettings`).
87. **How does biometric auth work?** → `local_auth`: `isDeviceSupported`, `canCheckBiometrics`, `authenticate(localizedReason:...)`; `biometricOnly:false` allows device PIN fallback.
88. **How does speech-to-text work and where does audio go?** → `speech_to_text` uses on-device platform STT; only transcribed *text* leaves the device.
89. **How do you scan QR codes?** → `mobile_scanner` `onDetect` → parse `upi://pay?...` via `Uri.queryParameters`.
90. **What's a platform channel?** → `MethodChannel` bridge to native (Kotlin/Swift) code; plugins like local_auth use it under the hood.
91. **Where are Android permissions declared?** → `AndroidManifest.xml` (camera, microphone, internet, biometric/USE_BIOMETRIC).
92. **How do you store the session locally?** → `SharedPreferences` (key-value). For secrets you'd use `flutter_secure_storage` (Keychain/Keystore).

### J. Performance, testing, release (93–100)
93. **How do you optimize rebuilds?** → `const` widgets, split widgets so `setState` rebuilds a smaller subtree, avoid heavy work in `build`, use `ListView.builder`.
94. **What causes jank and how to find it?** → Long frames (>16ms at 60fps); use DevTools performance/timeline; move heavy work off the UI isolate with `compute`.
95. **`const` constructor — performance benefit?** → Canonicalized, reused instances → fewer allocations & rebuilds.
96. **Types of tests in Flutter?** → Unit, Widget (`testWidgets` + `WidgetTester`), Integration (`integration_test`). Your `widget_test.dart` is the default stub — a known gap.
97. **How would you test the transfer flow?** → Mock the `http` client / services, widget-test the confirmation sheet, unit-test entity parsing, integration-test voice→action.
98. **Debug vs profile vs release builds?** → Debug (assertions, hot reload, slow), Profile (perf testing), Release (optimized AOT, no debug aids).
99. **Hot reload vs hot restart?** → Reload injects code & keeps state (rebuilds widgets); restart resets app state. State changes to fields may need restart.
100. **How do you build/release?** → `flutter build apk`/`appbundle` (Android), `flutter build ipa` (iOS); manage env via `--dart-define`; version in `pubspec.yaml` (`1.0.0+1`).

### Bonus project-specific Flutter Qs (101–110)
101. **Why `AnimatedSwitcher` instead of `IndexedStack` for tabs?** → You chose a fade; trade-off is tab pages rebuild & lose state. `IndexedStack` would preserve state but keep all pages alive.
102. **How does the app decide voice vs chat?** → Flask returns `action`; `intent_service.dart` maps `route_to_rasa`/`chatbot` → `RasaService`, else `initiate_transfer`/`show_balance`/`initiate_request`.
103. **Where is biometric enforced and where is it missing?** → Enforced in the voice flow (`voiceToText`) and app unlock; **missing on manual pay screens** — be ready to admit this.
104. **How is the recipient resolved for a voice transfer?** → If it contains `@` → UPI ID; else treated as phone (+91 prepended). Names aren't resolved → known gap.
105. **How does pull-to-refresh refetch?** → `RefreshIndicator.onRefresh` → `Future.wait([_loadBalance, _loadRecentTransactions])`.
106. **How are transactions merged & sorted on Home?** → Map sent+received into a common shape, sort by timestamp desc, `take(4)`.
107. **How is balance hidden?** → `_balanceHidden` toggles text to `••••••` inside an `AnimatedSwitcher` crossfade.
108. **Why store `phoneNumber` in SharedPreferences?** → It's the identity sent to every API (no token) — convenient but insecure; should be a JWT.
109. **How do you format Indian currency?** → Custom `_inr()` doing lakh/crore grouping (`12,48,000.00`).
110. **What happens on a cold start if logged in?** → `initialRoute` = `/biometric` → biometric prompt → dashboard; phone/name/upiId loaded from SharedPreferences.

---

### Final advice for the 2 hours
1. **Lead the architecture conversation** with the 7-point pitch and the diagram.
2. **Volunteer the weak links before they find them** — it reads as senior-level self-awareness, especially the atomicity and auth gaps for a *payments* app.
3. **For every "what's wrong", immediately give the fix.** Problem→fix pairs are what they're scoring.
4. **On ML, tell the overfitting/none-class story confidently** — it shows you understand your model's failure modes, not just its happy path.
5. Keep a glass of water and the §16 cheat-sheet numbers in your head. Good luck.
