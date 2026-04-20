import hashlib
import json
from datetime import date, datetime
from decimal import Decimal
from uuid import UUID


def _normalize_value(value):
    if isinstance(value, dict):
        return {key: _normalize_value(value[key]) for key in sorted(value)}
    if isinstance(value, list):
        return [_normalize_value(item) for item in value]
    if isinstance(value, tuple):
        return [_normalize_value(item) for item in value]
    if isinstance(value, Decimal):
        return format(value, "f")
    if isinstance(value, UUID | date | datetime):
        return str(value)
    return value


def canonical_request_hash(payload: dict) -> str:
    normalized_payload = _normalize_value(payload)
    encoded_payload = json.dumps(normalized_payload, separators=(",", ":"), sort_keys=True)
    return hashlib.sha256(encoded_payload.encode("utf-8")).hexdigest()
