from app.core.security import create_access_token, decode_token, hash_password, verify_password


def test_hash_and_verify_password() -> None:
    password = "secret123"
    hashed = hash_password(password)
    assert hashed != password
    assert verify_password(password, hashed) is True


def test_access_token_contains_subject() -> None:
    token = create_access_token(subject="user-1")
    payload = decode_token(token)
    assert payload["sub"] == "user-1"
