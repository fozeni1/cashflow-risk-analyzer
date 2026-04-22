# Импортируем класс HTTPException для обработки ошибок HTTP запросов
from fastapi import HTTPException
# Импортируем класс Session для работы с базой данных
from sqlalchemy.orm import Session
# Импортируем репозиторий для работы с пользователями
from app.repository import users as users_repository
# Импортируем функции для безопасной работы с паролями
from app.security import hash_password
# Импортируем модель данных для ответа с информацией о пользователе
from app.schemas import UserResponse


def create_user(db: Session, login: str, password: str) -> UserResponse:
    # Проверяем не существует ли уже пользователь с таким логином
    if users_repository.get_user(db, login):
        raise HTTPException(status_code=400, detail="User already exists")  # Если пользователь уже есть - возвращаем ошибку 400

    # Создаем нового пользователя через репозиторий
    user = users_repository.create_user(db, login, hash_password(password))
    # Сохраняем изменения в базе данных
    db.commit()
    # Преобразуем модель SQLAlchemy в модель Pydantic для ответа
    return UserResponse.model_validate(user)
