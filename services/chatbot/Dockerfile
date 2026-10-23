# Use official Rasa image as base
FROM rasa/rasa:3.6.0

# Set working directory
WORKDIR /app

# Switch to root to install dependencies
USER root

# Copy requirements file if exists
COPY requirements.txt* ./

# Install custom Python dependencies if requirements.txt exists
RUN if [ -f requirements.txt ]; then pip install --no-cache-dir -r requirements.txt; fi

# Copy Rasa configuration files
COPY config.yml domain.yml ./
COPY data/ ./data/
COPY actions/ ./actions/

# Copy trained models
COPY models/ ./models/

# Set permissions
RUN chown -R 1001:1001 /app

# Switch back to non-root user
USER 1001

# Expose Rasa port
EXPOSE 5005

# Default command (can be overridden in docker-compose)
CMD ["run", "--enable-api", "--cors", "*"]
