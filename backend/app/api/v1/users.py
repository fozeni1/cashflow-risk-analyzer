from fastapi import APIRouter, Depends, HTTPException, Response, status
# Импортируем класс Session для работы с базой данных
from sqlalchemy.orm import Session

# Импортируем функции для получения сессии базы данных и текущего пользователя
from app.dependency import get_db, get_current_user
from app.models import User  # Импортируем модель пользователя
# Импортируем модели данных для пользователей
from app.schemas import TokenResponse, UserRequest, UserResponse
from app.security import (
    JWT_ACCESS_TOKEN_EXPIRES_MINUTES,
    security,
    verify_password,
)
# Импортируем сервис для работы с пользователями
from app.service import users as users_service
from app.repository import users as users_repository

# Создаем роутер для группировки endpoints связанных с пользователями
router = APIRouter()

@router.post("/users", response_model=UserResponse)
def create_user(payload: UserRequest, db: Session = Depends(get_db)):  # Сессия базы данных через dependency injection
    # Вызываем сервис для создания нового пользователя
    return users_service.create_user(db, payload.username, payload.password)  # Передаем имя пользователя из запроса

@router.get("/users/me", response_model=UserResponse)
def get_me(current_user: User = Depends(get_current_user)):  # Текущий пользователь из токена авторизации
    # Преобразуем модель SQLAlchemy в модель Pydantic для ответа
    return UserResponse.model_validate(current_user)

@router.post("/login", response_model=TokenResponse)
def login(creds: UserRequest, response: Response, db: Session = Depends(get_db)):
    user = users_repository.get_user(db=db, login=creds.username)
    if user is None or not verify_password(creds.password, user.password_hash):
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid credentials")

    token = security.create_access_token(uid=str(user.id))
    security.set_access_cookies(
        token=token,
        response=response,
        max_age=JWT_ACCESS_TOKEN_EXPIRES_MINUTES * 60,
    )
    return TokenResponse(access_token=token)

@router.post("/logout")
def logout(response: Response):
    security.unset_access_cookies(response)
    return {"message": "Logged out"}

@router.get("/protected")
def protected(current_user: User = Depends(get_current_user)):
    return {"message": f"Hello, {current_user.login}"}
