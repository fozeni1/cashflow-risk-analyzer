from typing import Generator

from authx.exceptions import AuthXException
from fastapi import Depends, HTTPException, Request, Security, status
from fastapi.security import APIKeyCookie, HTTPAuthorizationCredentials, HTTPBearer
from sqlalchemy.orm import Session

from app.database import SessionLocal
from app.models import User
from app.repository import users as users_repository
from app.security import JWT_ACCESS_COOKIE_NAME
from app.security import security, JWT_COOKIE_CSRF_PROTECT


bearer_scheme = HTTPBearer(
    auto_error=False,
    description="JWT access token in Authorization: Bearer <token>",
)
cookie_scheme = APIKeyCookie(
    name=JWT_ACCESS_COOKIE_NAME,
    auto_error=False,
)


def get_db() -> Generator[Session, None, None]:
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


def _unauthorized_exception() -> HTTPException:
    return HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )


async def get_current_user(
    request: Request,
    _: HTTPAuthorizationCredentials | None = Security(bearer_scheme),
    __: str | None = Security(cookie_scheme),
    db: Session = Depends(get_db),
) -> User:
    try:
        request_token = await security.get_access_token_from_request(request)
        payload = security.verify_token(
            request_token,
            verify_csrf=JWT_COOKIE_CSRF_PROTECT and request.method.upper() in security.config.JWT_CSRF_METHODS,
        )
        user_id = int(payload.sub)
    except (AuthXException, TypeError, ValueError):
        raise _unauthorized_exception()

    user = users_repository.get_user_by_id(db, user_id)
    if user is None:
        raise _unauthorized_exception()

    return user

