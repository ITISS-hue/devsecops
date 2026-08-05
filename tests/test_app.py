import pytest

from app import app as flask_app


@pytest.fixture
def client():
    flask_app.config.update(TESTING=True)
    with flask_app.test_client() as client:
        yield client


def test_index(client):
    resp = client.get("/")
    assert resp.status_code == 200
    assert resp.get_json()["message"] == "Hello from a secure Flask app"


def test_health(client):
    resp = client.get("/health")
    assert resp.status_code == 200
    assert resp.get_json()["status"] == "healthy"


def test_greet_default(client):
    resp = client.get("/greet")
    assert resp.status_code == 200
    assert resp.get_json()["message"] == "Hello, world!"


def test_greet_with_name(client):
    resp = client.get("/greet?name=Akash")
    assert resp.status_code == 200
    assert resp.get_json()["message"] == "Hello, Akash!"


def test_greet_rejects_overlong_input(client):
    resp = client.get("/greet?name=" + "a" * 100)
    assert resp.status_code == 400


def test_404(client):
    resp = client.get("/does-not-exist")
    assert resp.status_code == 404
