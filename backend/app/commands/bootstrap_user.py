import argparse

from app.db import get_session_factory
from app.services.auth_service import bootstrap_user


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--username", required=True)
    parser.add_argument("--password", required=True)
    parser.add_argument("--display-name", required=False)
    args = parser.parse_args()

    session = get_session_factory()()
    try:
        bootstrap_user(session, args.username, args.password, args.display_name)
    except ValueError as exc:
        print(str(exc))
        return 1
    finally:
        session.close()

    print("user created")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
