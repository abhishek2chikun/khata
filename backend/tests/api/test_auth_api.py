def test_login_refresh_logout_me_flow(client, seeded_user) -> None:
    login = client.post("/auth/login", json={"username": "owner", "password": "secret123"})
    assert login.status_code == 200
    tokens = login.json()

    refresh = client.post("/auth/refresh", json={"refresh_token": tokens["refresh_token"]})
    assert refresh.status_code == 200

    me = client.get("/auth/me", headers={"Authorization": f"Bearer {refresh.json()['access_token']}"})
    assert me.status_code == 200
    assert me.json()["username"] == "owner"

    logout = client.post(
        "/auth/logout",
        headers={"Authorization": f"Bearer {refresh.json()['access_token']}"},
        json={"refresh_token": refresh.json()["refresh_token"]},
    )
    assert logout.status_code == 200

    refresh_again = client.post("/auth/refresh", json={"refresh_token": refresh.json()["refresh_token"]})
    assert refresh_again.status_code == 401
    assert refresh_again.json()["error"]["code"] == "INVALID_REFRESH_TOKEN"


def test_me_rejects_invalid_access_token_with_error_envelope(client) -> None:
    response = client.get("/auth/me", headers={"Authorization": "Bearer invalid-token"})
    assert response.status_code == 401
    assert response.json()["error"]["code"] == "INVALID_ACCESS_TOKEN"
