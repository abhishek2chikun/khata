from fastapi import HTTPException, status


def get_current_user() -> dict[str, str]:
    raise HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Authentication dependency not implemented yet",
    )
