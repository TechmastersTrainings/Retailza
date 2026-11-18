from datetime import datetime, timedelta
from typing import Optional, Dict, Any
import jwt
import bcrypt
from backend.app.config import settings

# Fixed, clearly-insecure key used ONLY outside production when SECRET_KEY is unset
# (local dev and the test suite). Production must set a real SECRET_KEY; main.py
# refuses to start otherwise, so this value can never sign real tokens in prod.
_DEV_FALLBACK_SECRET = "dev-insecure-secret-not-for-production"


def get_secret_key() -> str:
    if settings.SECRET_KEY:
        return settings.SECRET_KEY
    if settings.APP_ENV == "production":
        raise RuntimeError("SECRET_KEY must be set in production.")
    return _DEV_FALLBACK_SECRET


def hash_password(password: str) -> str:
    pwd_bytes = password.encode('utf-8')[:72]
    salt = bcrypt.gensalt()
    return bcrypt.hashpw(pwd_bytes, salt).decode('utf-8')


def verify_password(plain_password: str, hashed_password: str) -> bool:
    if not hashed_password:
        return False
    pwd_bytes = plain_password.encode('utf-8')[:72]
    hashed_bytes = hashed_password.encode('utf-8')
    try:
        return bcrypt.checkpw(pwd_bytes, hashed_bytes)
    except Exception:
        return False


def create_access_token(data: Dict[str, Any], expires_delta: Optional[timedelta] = None) -> str:
    to_encode = data.copy()
    if expires_delta:
        expire = datetime.utcnow() + expires_delta
    else:
        expire = datetime.utcnow() + timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
    to_encode.update({"exp": expire, "type": "access"})
    encoded_jwt = jwt.encode(to_encode, get_secret_key(), algorithm=settings.ALGORITHM)
    return encoded_jwt


def create_refresh_token(data: Dict[str, Any]) -> str:
    to_encode = data.copy()
    expire = datetime.utcnow() + timedelta(days=settings.REFRESH_TOKEN_EXPIRE_DAYS)
    to_encode.update({"exp": expire, "type": "refresh"})
    encoded_jwt = jwt.encode(to_encode, get_secret_key(), algorithm=settings.ALGORITHM)
    return encoded_jwt


def decode_token(token: str) -> Dict[str, Any]:
    try:
        payload = jwt.decode(token, get_secret_key(), algorithms=[settings.ALGORITHM])
        return payload
    except jwt.PyJWTError:
        return {}
