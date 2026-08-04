# Multi-stage build for DevSecOps security and minimal image size
FROM python:3.11-slim AS builder

WORKDIR /app

# Upgrade pip
RUN pip install --no-cache-dir --upgrade pip==24.0

# Copy and install dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir --only-binary :all: --require-hashes -r requirements.txt

# Final Runtime Stage
FROM python:3.11-slim

# Create non-root user for execution
RUN groupadd -g 10001 appgroup && \
    useradd -u 10001 -g appgroup -s /bin/sh appuser

WORKDIR /app

# Copy installed site-packages from builder
COPY --from=builder /usr/local/lib/python3.11/site-packages /usr/local/lib/python3.11/site-packages
COPY --from=builder /usr/local/bin /usr/local/bin

# Copy app.py owned by root (default) and restrict write access
COPY app.py .
RUN chmod 644 app.py

# Set environment variables
ENV PYTHONUNBUFFERED=1 \
    PORT=8000 \
    HOST=0.0.0.0

# Switch to non-root user
USER 10001:10001

EXPOSE 8000

CMD ["gunicorn", "--bind", "0.0.0.0:8000", "--workers", "2", "app:app"]