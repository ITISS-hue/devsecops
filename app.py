"""
Simple, security-conscious Flask web app.

Design choices made specifically to keep this clean on SonarQube / SAST scans:
- No hardcoded secrets or credentials (reads from environment only)
- Debug mode is never enabled
- No use of eval/exec, no string-built SQL, no shell=True subprocess calls
- Input on the one dynamic route is validated and length-capped before use
- Generic exception handler avoids leaking stack traces to clients
"""

import logging
import os
from flask import Flask, jsonify, request

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s %(levelname)s %(name)s %(message)s",
)
logger = logging.getLogger(__name__)

app = Flask(__name__)

MAX_NAME_LENGTH = 50


@app.route("/", methods=["GET"])
def index():
    """Basic landing endpoint."""
    return jsonify({"message": "Hello from a secure Flask app"}), 200


@app.route("/health", methods=["GET"])
def health():
    """Liveness/readiness probe endpoint for container orchestration."""
    return jsonify({"status": "healthy"}), 200


@app.route("/greet", methods=["GET"])
def greet():
    """Example of safely handling user-supplied input."""
    name = request.args.get("name", "world")

    # Validate and cap input length to avoid abuse / injection-style payloads
    if not isinstance(name, str) or len(name) > MAX_NAME_LENGTH:
        return jsonify({"error": "invalid 'name' parameter"}), 400

    safe_name = "".join(ch for ch in name if ch.isalnum() or ch in (" ", "-", "_"))
    return jsonify({"message": f"Hello, {safe_name}!"}), 200


@app.errorhandler(404)
def not_found(_error):
    return jsonify({"error": "not found"}), 404


@app.errorhandler(500)
def internal_error(_error):
    # Log full details server-side, never expose internals to the client
    logger.exception("Unhandled server error")
    return jsonify({"error": "internal server error"}), 500


if __name__ == "__main__":
    # Local dev only. In the container, gunicorn is used instead (see Dockerfile).
    port = int(os.environ.get("PORT", "8080"))
    app.run(host="127.0.0.1", port=port)
