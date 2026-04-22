# Импортируем функции для работы с базой данных из SQLAlchemy
from sqlalchemy import create_engine, inspect, text
from sqlalchemy.orm import sessionmaker, declarative_base

# URL подключения к базе данных SQLite
DATABASE_URL = "sqlite:///./finance.db"

# Создаем движок для подключения к базе данных
# check_same_thread=False позволяет использовать SQLite в многопоточной среде
engine = create_engine(DATABASE_URL, connect_args={"check_same_thread": False})

# Создаем фабрику для создания сессий работы с базой данных
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

# Базовый класс для всех моделей базы данных
Base = declarative_base()


def bootstrap_database() -> None:
    Base.metadata.create_all(bind=engine)

    inspector = inspect(engine)
    if not inspector.has_table("user"):
        return

    user_columns = {column["name"] for column in inspector.get_columns("user")}
    if "password_hash" in user_columns:
        return

    # Для существующих SQLite-баз добавляем колонку без полной миграционной системы.
    with engine.begin() as connection:
        connection.execute(text('ALTER TABLE "user" ADD COLUMN password_hash VARCHAR'))
