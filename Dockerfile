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

# Copy app.py
COPY app.py .
RUN chmod 644 app.py

# FIX 1: Create data directory for SQLite DB and grant full ownership to non-root user
RUN mkdir -p /app/data && chown -R 10001:10001 /app

# Set environment variables
ENV PYTHONUNBUFFERED=1 \
    PORT=8000 \
    HOST=0.0.0.0 \
    DB_PATH=/app/data/users.db

# Switch to non-root user
USER 10001:10001

EXPOSE 8000

# FIX 2: Single worker with threads for smooth SQLite and Session handling
CMD ["gunicorn", "--bind", "0.0.0.0:8000", "--workers", "1", "--threads", "4", "app:app"]