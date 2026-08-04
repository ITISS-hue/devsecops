# Stage 1: Build stage for dependency resolution
FROM python:3.11-slim AS builder

WORKDIR /app

RUN pip install --no-cache-dir --only-binary :all: pip-tools

# Copy requirements.in (loose versions)
COPY requirements.in .

# Generate hash-locked requirements automatically during build
RUN pip-compile --generate-hashes requirements.in -o requirements.txt


# Stage 2: Final runtime image
FROM python:3.11-slim AS runner

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PORT=8000

WORKDIR /app

# Copy lockfile from builder stage
COPY --from=builder /app/requirements.txt .

# Enforce strict hash verification
RUN pip install --no-cache-dir --require-hashes -r requirements.txt gunicorn==22.0.0

# Non-root user setup
RUN addgroup --system appgroup && adduser --system --group appuser \
    && chown -R appuser:appgroup /app

COPY app.py .
USER appuser

EXPOSE 8000

CMD ["gunicorn", "--bind", "0.0.0.0:8000", "--workers", "3", "app:app"]