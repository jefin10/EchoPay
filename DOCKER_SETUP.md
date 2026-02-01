# EchoPay Docker Setup

Complete Docker configuration for the EchoPay multi-service application.

## 🏗️ Architecture

The application consists of 4 Docker services:

1. **PostgreSQL Database** (`db`) - Port 5432
2. **Django Backend** (`django`) - Port 8000 - UPI transaction service
3. **Flask Backend** (`flask`) - Port 5002 - Intent classification & voice assistant
4. **Rasa** (`rasa`) - Port 5005 - Conversational AI

## 🚀 Quick Start

### 1. Initial Setup

```bash
# Navigate to project directory
cd /home/jen/Desktop/Projects/EchoPay

# Copy environment template (optional)
cp .env.example .env

# Edit .env if you want to customize settings
nano .env
```

### 2. Build and Start Services

```bash
# Build all services
docker-compose build

# Start all services
docker-compose up -d

# View logs
docker-compose logs -f
```

### 3. Check Service Health

```bash
# Check container status
docker-compose ps

# Test Flask backend
curl http://localhost:5002/health

# Test Django backend
curl http://localhost:8000/

# Test Rasa
curl http://localhost:5005/
```

## 🛠️ Development Mode

For development with hot-reloading:

```bash
# Start with development overrides
docker-compose -f docker-compose.yml -f docker-compose.dev.yml up

# This mounts your local code into containers
# Changes in Backend/, DJBackend/, and Rasa/ will auto-reload
```

## 📋 Common Commands

### Service Management

```bash
# Start services
docker-compose up -d

# Stop services
docker-compose down

# Restart a specific service
docker-compose restart flask
docker-compose restart django
docker-compose restart rasa

# View service logs
docker-compose logs flask
docker-compose logs django
docker-compose logs rasa

# Follow logs in real-time
docker-compose logs -f flask
```

### Database Management

```bash
# Access PostgreSQL shell
docker-compose exec db psql -U echopay_user -d echopay_db

# Run Django migrations manually
docker-compose exec django python manage.py migrate

# Create Django superuser
docker-compose exec django python manage.py createsuperuser
```

### Rebuilding Services

```bash
# Rebuild specific service
docker-compose build flask
docker-compose build django

# Rebuild and restart
docker-compose up -d --build flask

# Rebuild everything from scratch
docker-compose down
docker-compose build --no-cache
docker-compose up -d
```

### Cleanup

```bash
# Stop and remove containers
docker-compose down

# Remove volumes (WARNING: deletes database data)
docker-compose down -v

# Remove everything including images
docker-compose down -v --rmi all
```

## 🔍 Troubleshooting

### Service Won't Start

```bash
# Check logs for errors
docker-compose logs <service-name>

# Common issues:
# 1. Port already in use - change port in docker-compose.yml
# 2. Build failed - check Dockerfile syntax
# 3. Database connection - ensure db service is healthy
```

### Database Connection Issues

```bash
# Ensure database is ready
docker-compose exec db pg_isready -U echopay_user -d echopay_db

# Check Django can connect
docker-compose exec django python manage.py dbshell
```

### Backend Model Loading Issues

```bash
# Check if model files exist
docker-compose exec flask ls -la /app/Intent_classifier/

# View Flask logs for model loading
docker-compose logs flask | grep -i "model"
```

### Port Conflicts

If a port is already in use, edit `docker-compose.yml`:

```yaml
services:
  flask:
    ports:
      - "5003:5002"  # Change 5003 to any available port
```

## 🌐 Connecting Flutter App

Update your Flutter app to connect to the containerized backends:

```dart
// Update base URLs in your Flutter app
const String DJANGO_BASE_URL = "http://localhost:8000/accounts";
const String FLASK_BASE_URL = "http://localhost:5002";
const String RASA_BASE_URL = "http://localhost:5005";

// For Android emulator, use:
// const String DJANGO_BASE_URL = "http://10.0.2.2:8000/accounts";

// For physical device on same network, use your computer's IP:
// const String DJANGO_BASE_URL = "http://192.168.x.x:8000/accounts";
```

## 📝 Environment Variables

Key environment variables (set in `.env` or `docker-compose.yml`):

### Database
- `POSTGRES_DB` - Database name (default: echopay_db)
- `POSTGRES_USER` - Database user (default: echopay_user)
- `POSTGRES_PASSWORD` - Database password (default: echopay_password)

### Django
- `DEBUG` - Debug mode (1 for dev, 0 for production)
- `DJANGO_SETTINGS_MODULE` - Settings module
- `SECRET_KEY` - Django secret key

### Flask
- `FLASK_ENV` - Environment (development/production)
- `DJANGO_BASE_URL` - Django backend URL for inter-service communication

## 🔒 Production Considerations

For production deployment:

1. **Change default passwords** in `.env`
2. **Set DEBUG=0** for Django
3. **Use gunicorn** instead of development server
4. **Add HTTPS/SSL** with nginx reverse proxy
5. **Set proper SECRET_KEY** for Django
6. **Configure ALLOWED_HOSTS** in Django settings
7. **Use volumes** for persistent data
8. **Set up monitoring** and logging

## 📂 File Structure

```
EchoPay/
├── docker-compose.yml          # Main Docker Compose configuration
├── docker-compose.dev.yml      # Development overrides
├── .env.example                # Environment variable template
├── .dockerignore               # Root-level ignore file
├── Backend/
│   ├── Dockerfile              # Flask backend image
│   ├── .dockerignore
│   └── Intent_classifier/
│       └── flask_server.py     # Main Flask app
├── DJBackend/
│   ├── Dockerfile              # Django backend image
│   ├── .dockerignore
│   ├── entrypoint.sh          # Startup script with migrations
│   └── manage.py
└── Rasa/
    ├── Dockerfile              # Rasa image
    ├── .dockerignore
    ├── config.yml
    ├── domain.yml
    └── data/
```

## ✅ Next Steps

1. **Test the setup**: Run `docker-compose build && docker-compose up`
2. **Check all services**: Verify health endpoints
3. **Run migrations**: Ensure Django database is set up
4. **Test integration**: Try API calls between services
5. **Connect Flutter app**: Update URLs and test end-to-end
