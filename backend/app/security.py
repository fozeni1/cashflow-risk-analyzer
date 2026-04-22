from datetime import timedelta
import hashlib
import hmac
import os
from readline import backend
import secrets
from dotenv import load_dotenv
import os
load_dotenv("/Users/egor/Documents/cashflow-risk-analyzer/backend/.env")

from authx import AuthX, AuthXConfig


JWT_SECRET_KEY = os.getenv("JWT_SECRET_KEY")
JWT_ACCESS_COOKIE_NAME = os.getenv("JWT_ACCESS_COOKIE_NAME", "access_token")
JWT_ACCESS_TOKEN_EXPIRES_MINUTES = int(os.getenv("JWT_ACCESS_TOKEN_EXPIRES_MINUTES", "30"))
JWT_COOKIE_SECURE = os.getenv("JWT_COOKIE_SECURE", "false").lower() == "true"
JWT_COOKIE_SAMESITE = os.getenv("JWT_COOKIE_SAMESITE", "lax")
JWT_COOKIE_CSRF_PROTECT = os.getenv("JWT_COOKIE_CSRF_PROTECT", "false").lower() == "true"
PASSWORD_HASH_ITERATIONS = int(os.getenv("PASSWORD_HASH_ITERATIONS", "100000"))


config = AuthXConfig(
    JWT_SECRET_KEY=JWT_SECRET_KEY,
    JWT_ACCESS_TOKEN_EXPIRES=timedelta(minutes=JWT_ACCESS_TOKEN_EXPIRES_MINUTES),
    JWT_TOKEN_LOCATION=["headers", "cookies"],
    JWT_ACCESS_COOKIE_NAME=JWT_ACCESS_COOKIE_NAME,
    JWT_COOKIE_SECURE=JWT_COOKIE_SECURE,
    JWT_COOKIE_SAMESITE=JWT_COOKIE_SAMESITE,
    JWT_COOKIE_HTTP_ONLY=True,
    JWT_COOKIE_CSRF_PROTECT=JWT_COOKIE_CSRF_PROTECT,
)

security = AuthX(config=config)


def hash_password(password: str) -> str:
    salt = secrets.token_bytes(16)
    password_hash = hashlib.pbkdf2_hmac(
        "sha256",
        password.encode("utf-8"),
        salt,
        PASSWORD_HASH_ITERATIONS,
    )
    return f"{salt.hex()}${password_hash.hex()}"


def verify_password(password: str, stored_hash: str | None) -> bool:
    if not stored_hash:
        return False

    try:
        salt_hex, password_hash_hex = stored_hash.split("$", maxsplit=1)
        salt = bytes.fromhex(salt_hex)
    except ValueError:
        return False

    derived_hash = hashlib.pbkdf2_hmac(
        "sha256",
        password.encode("utf-8"),
        salt,
        PASSWORD_HASH_ITERATIONS,
    )
    return hmac.compare_digest(derived_hash.hex(), password_hash_hex)
