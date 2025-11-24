FROM python:3.11-slim

WORKDIR /app

# Install dependencies
RUN pip install --no-cache-dir fastapi==0.104.1 uvicorn==0.24.0

# Copy application
COPY main.py .

# Expose port
EXPOSE 8080

# Set environment variables
ENV APP_VERSION=1.0.0
ENV ENVIRONMENT=production

# Run application
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8080"]