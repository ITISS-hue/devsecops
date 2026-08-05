# Secure Flask App

Minimal Flask web app + Dockerfile, built to come back clean on SonarQube and Bandit.

## Run locally
```bash
pip install -r requirements.txt
python app.py          # dev server on 127.0.0.1:8080
```

## Run tests
```bash
pip install pytest pytest-cov
pytest --cov=app --cov-report=xml tests/
```

## Build & run the container
```bash
docker build -t secure-flask-app .
docker run -p 8080:8080 secure-flask-app
curl http://localhost:8080/health
```

## Run SonarScanner (local, needs a Sonar server/token)
```bash
pytest --cov=app --cov-report=xml tests/
sonar-scanner \
  -Dsonar.host.url=<your-sonarqube-url> \
  -Dsonar.login=<your-token>
```

## Container vulnerability scan
```bash
docker scout cves secure-flask-app
# or
trivy image secure-flask-app
```

## Why this passes clean
- No hardcoded secrets/credentials
- No `eval`, `exec`, `shell=True`, or string-built SQL
- Flask debug mode never enabled
- User input on `/greet` is length-capped and sanitized
- Generic 500 handler avoids leaking stack traces
- Multi-stage Docker build — build tools never ship in the final image
- Runs as a non-root user (uid 1001) inside the container
- Dependency versions pinned in `requirements.txt`
- `gunicorn` (not the Flask dev server) serves the app in the container
