FROM python:3.11-slim

WORKDIR /app

# Copy and install dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy all backend files
COPY . .

# Set working directory to ml-server where flask_server.py is located
WORKDIR /app/ml-server

# Expose port 5002 (as defined in flask_server.py)
EXPOSE 5002

# Set environment variables
ENV PYTHONUNBUFFERED=1
ENV FLASK_APP=flask_server.py

# Run the Flask server
CMD ["python", "flask_server.py"]
