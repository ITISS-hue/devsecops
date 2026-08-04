# Base Image
FROM python:3.11-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PORT=8000

WORKDIR /app

# Dependencies install
COPY requirements.txt .
RUN pip install --no-cache-dir --require-hashes -r requirements.txt gunicorn==22.0.0

# Option A: Agar .dockerignore present hai, toh COPY . . safe hai
COPY . .

# Non-root user setup
RUN addgroup --system appgroup && adduser --system --group appuser \
    && chown -R appuser:appgroup /app
USER appuser

EXPOSE 8000

CMD ["gunicorn", "--bind", "0.0.0.0:8000", "--workers", "3", "app:app"]