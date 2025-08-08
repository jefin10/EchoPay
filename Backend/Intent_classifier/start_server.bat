@echo off
echo Starting Intent Classification Flask Server...
echo.

cd /d "c:\Users\ASUS\Desktop\VS code\Work\college\Intent_classifier"

echo Checking if virtual environment exists...
if not exist "venv" (
    echo Creating virtual environment...
    python -m venv venv
)

echo Activating virtual environment...
call venv\Scripts\activate

echo Installing requirements...
pip install -r requirements.txt

echo.
echo Starting Flask server...
echo Server will be available at: http://localhost:5000
echo Press Ctrl+C to stop the server
echo.

python flask_server.py

pause
