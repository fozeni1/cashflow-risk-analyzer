import os

from dotenv import load_dotenv
from sqlalchemy import create_engine, inspect, text
from sqlalchemy.orm import sessionmaker, declarative_base

load_dotenv()

# URL подключения к базе данных. По умолчанию используется локальный SQLite,
# а для Railway/PostgreSQL задайте DATABASE_URL в backend/.env.
DATABASE_URL = os.getenv("DATABASE_URL", "sqlite:///./finance.db")
if DATABASE_URL.startswith("postgres://"):
    DATABASE_URL = DATABASE_URL.replace("postgres://", "postgresql://", 1)

# Создаем движок для подключения к базе данных
engine_kwargs = {"pool_pre_ping": True}
if DATABASE_URL.startswith("sqlite"):
    # check_same_thread=False позволяет использовать SQLite в многопоточной среде
    engine_kwargs["connect_args"] = {"check_same_thread": False}

engine = create_engine(DATABASE_URL, **engine_kwargs)

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

    # Для существующих баз добавляем колонку без полной миграционной системы.
    with engine.begin() as connection:
        connection.execute(text('ALTER TABLE "user" ADD COLUMN password_hash VARCHAR'))
