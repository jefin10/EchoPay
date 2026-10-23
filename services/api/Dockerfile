FROM python:3.11-slim

WORKDIR /app

# Install system dependencies including dos2unix for line ending conversion
RUN apt-get update && apt-get install -y \
    postgresql-client \
    curl \
    dos2unix \
    && rm -rf /var/lib/apt/lists/*

# Copy and install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy project files
COPY . .

# Copy entrypoint script and fix line endings + permissions
COPY entrypoint.sh /entrypoint.sh
RUN dos2unix /entrypoint.sh && chmod +x /entrypoint.sh

# Set environment variables
ENV PYTHONUNBUFFERED=1
ENV DJANGO_SETTINGS_MODULE=DJBackend.settings

# Expose port
EXPOSE 8000

# Use entrypoint script
ENTRYPOINT ["/entrypoint.sh"]

# Run Django development server (for production, use gunicorn)
CMD ["python", "manage.py", "runserver", "0.0.0.0:8000"]
