from fastapi.testclient import TestClient
import pytest

from app.main import create_app


pytestmark = pytest.mark.no_db


def test_health_route_works() -> None:
    client = TestClient(create_app())
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json() == {"status": "ok"}
