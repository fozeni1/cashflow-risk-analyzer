# Импортируем класс APIRouter для создания API endpoints
from fastapi import APIRouter, Depends  # Импортируем классы для создания API endpoints и dependency injection
# Импортируем класс Session для работы с базой данных
from sqlalchemy.orm import Session

# Импортируем функции для получения сессии базы данных и текущего пользователя
from app.dependency import get_db, get_current_user
from app.models import User  # Импортируем модель пользователя
# Импортируем модели данных для пользователей
from app.schemas import UserRequest, UserResponse
# Импортируем сервис для работы с пользователями
from app.service import users as users_service

# Создаем роутер для группировки endpoints связанных с пользователями
router = APIRouter()

@router.post("/users", response_model=UserResponse)
def create_user(payload: UserRequest, db: Session = Depends(get_db)):  # Сессия базы данных через dependency injection
    # Вызываем сервис для создания нового пользователя
    return users_service.create_user(db, payload.login)  # Передаем логин из запроса

@router.get("/users/me", response_model=UserResponse)
def get_me(current_user: User = Depends(get_current_user)):  # Текущий пользователь из токена авторизации
    # Преобразуем модель SQLAlchemy в модель Pydantic для ответа
    return UserResponse.model_validate(current_user)
