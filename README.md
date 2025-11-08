# Voice UPI Intent Classification API

A lightweight machine learning API for predicting user intents in voice-based UPI transactions.

## 🎯 Model Performance
- **Accuracy:** 97.65%
- **Model Size:** ~40KB (extremely lightweight!)
- **Classes:** `transfer_money`, `check_balance`, `request_money`

## 🚀 Quick Start

### Local Development

1. **Install dependencies:**
```bash
pip install -r requirements.txt
```

2. **Place the model file:**
Ensure `voice_upi_intent_model.pkl` is in the same directory as `voice_upi_api.py`

3. **Run the API:**
```bash
python voice_upi_api.py
```

4. **Test the API:**
Open `test_interface.html` in your browser or use curl:
```bash
curl -X POST http://localhost:5000/predict \
  -H "Content-Type: application/json" \
  -d '{"text": "send 500 to my friend"}'
```

## 🌐 API Endpoints

### 1. Health Check
- **URL:** `GET /`
- **Description:** Check if the API is running

### 2. Single Prediction
- **URL:** `POST /predict`
- **Body:** `{"text": "your text here"}`
- **Response:**
```json
{
  "intent": "transfer_money",
  "confidence": 0.98,
  "input_text": "send 500 to my friend",
  "cleaned_text": "send 500 to my friend",
  "status": "success"
}
```

### 3. Batch Prediction
- **URL:** `POST /batch_predict`
- **Body:** `{"texts": ["text1", "text2", ...]}`
- **Response:**
```json
{
  "status": "success",
  "predictions": [...],
  "count": 2
}
```

### 4. Model Information
- **URL:** `GET /model_info`
- **Description:** Get model details and classes

## 🚀 Free Tier Deployment Options

### Option 1: Render (Recommended)
1. Create account at [render.com](https://render.com)
2. Connect your GitHub repository
3. Create a new Web Service
4. Use Python 3 environment
5. Build Command: `pip install -r requirements.txt`
6. Start Command: `gunicorn voice_upi_api:app`

### Option 2: Railway
1. Create account at [railway.app](https://railway.app)
2. Connect your GitHub repository
3. Railway will auto-detect Python and deploy

### Option 3: Heroku (Limited free tier)
1. Create account at [heroku.com](https://heroku.com)
2. Install Heroku CLI
3. Commands:
```bash
heroku create your-app-name
git add .
git commit -m "Deploy voice UPI API"
git push heroku main
```

### Option 4: PythonAnywhere
1. Create account at [pythonanywhere.com](https://pythonanywhere.com)
2. Upload your files
3. Configure web app with Flask

## 📁 Required Files for Deployment

Ensure these files are in your deployment directory:
- `voice_upi_api.py` (main API file)
- `voice_upi_intent_model.pkl` (trained model)
- `requirements.txt` (dependencies)
- `Procfile` (for Heroku/Render)
- `test_interface.html` (optional, for testing)

## 🔧 Environment Variables

For production deployment, you may want to set:
- `PORT`: Port number (automatically set by most platforms)
- `FLASK_ENV`: Set to 'production'

## 💡 Usage Examples

### Transfer Money
- "send 500 to my friend"
- "transfer 1000 to mom via upi"
- "pay 250 to john"

### Check Balance
- "what is my current balance"
- "check my account balance"
- "how much money do i have"

### Request Money
- "ask dad for 500 rupees"
- "request 250 from mom"
- "collect money from john"

## 🛠️ Model Details

- **Algorithm:** TF-IDF Vectorization + Logistic Regression
- **Features:** 5000 max features, unigrams and bigrams
- **Preprocessing:** Text cleaning, lowercase conversion
- **Training Data:** 848 samples across 3 intent classes

## 📊 Performance Metrics

| Intent | Precision | Recall | F1-Score |
|--------|-----------|--------|----------|
| check_balance | 1.00 | 1.00 | 1.00 |
| request_money | 0.98 | 0.95 | 0.96 |
| transfer_money | 0.95 | 0.98 | 0.96 |

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## 📝 License

This project is open source and available under the MIT License.

---

**Built with ❤️ for voice-enabled UPI transactions**