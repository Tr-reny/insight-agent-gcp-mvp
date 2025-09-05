from fastapi.testclient import TestClient
from main import app

client = TestClient(app)

def test_analyze_basic():
    resp = client.post("/analyze", json={"text": "I love cloud engineering!"})
    assert resp.status_code == 200
    data = resp.json()
    assert data["word_count"] == 4
    # character count includes punctuation and spaces
    assert data["character_count"] == 25

def test_health():
    resp = client.get("/healthz")
    assert resp.status_code == 200
    assert resp.json()["status"] == "ok"
