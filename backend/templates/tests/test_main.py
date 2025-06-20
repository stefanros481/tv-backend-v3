from fastapi.testclient import TestClient

from src.main import app

client = TestClient(app)


def test_root():
    """Test the root endpoint returns the welcome message."""
    response = client.get("/")
    assert response.status_code == 200
    assert "message" in response.json()
    assert "Welcome to the API!" in response.json()["message"]


def test_health_check():
    """Test the health check endpoint returns the correct response."""
    response = client.get("/health")
    assert response.status_code == 200
    json_response = response.json()
    assert json_response["status"] == "ok"
    assert json_response["service"] == "FastAPI Microservice"
    assert "version" in json_response
