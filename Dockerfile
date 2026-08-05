# syntax=docker/dockerfile:1

# ---- Build stage: install deps into a venv, keep build tools out of final image ----
FROM python:3.12-slim AS builder

WORKDIR /app

RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

COPY requirements.txt .
RUN pip install --no-cache-dir --upgrade pip==24.2 \
    && pip install --no-cache-dir -r requirements.txt

# ---- Final stage: minimal runtime image ----
FROM python:3.12-slim

# Create a non-root user/group to run the app
RUN groupadd --gid 1001 appgroup \
    && useradd --uid 1001 --gid appgroup --shell /usr/sbin/nologin --create-home appuser

# Bring in only the installed virtual environment, not build tooling
COPY --from=builder /opt/venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH" \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

WORKDIR /app
COPY --chown=appuser:appgroup app.py .

USER appuser

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD python -c "import urllib.request,sys; sys.exit(0) if urllib.request.urlopen('http://127.0.0.1:8080/health', timeout=2).status == 200 else sys.exit(1)"

# gunicorn binds 0.0.0.0 intentionally here — this is the container's own
# network namespace, which is the correct/expected binding for a containerized service.
CMD ["gunicorn", "--bind", "0.0.0.0:8080", "--workers", "2", "--timeout", "30", "app:app"]
