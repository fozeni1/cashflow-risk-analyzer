# Импортируем класс Session для работы с базой данных
from sqlalchemy.orm import Session

from app.models import User

# Находим пользователя в базе данных по его логину
def get_user(db: Session, login: str) -> User | None:
    # Выполняем запрос к таблице пользователей
    # Фильтруем записи по логину
    return db.query(User).filter(User.login == login).scalar()


# Создаем нового пользователя в базе данных
def create_user(db: Session, login: str) -> User:
    # Создаем новый объект пользователя с указанным логином
    user = User(login=login)
    # Добавляем пользователя в сессию базы данных
    db.add(user)
    # Применяем изменения к базе данных (но не сохраняем транзакцию)
    db.flush()
    # Возвращаем созданный объект пользователя
    return user
