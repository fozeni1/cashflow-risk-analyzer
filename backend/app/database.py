import os

from dotenv import load_dotenv
from sqlalchemy import create_engine, inspect, text
from sqlalchemy.orm import sessionmaker, declarative_base

load_dotenv()

# 📌 URL базы
DATABASE_URL = os.getenv("DATABASE_URL", "sqlite:///./finance.db")

# 🔥 фикс для Railway (postgres:// → postgresql://)
if DATABASE_URL.startswith("postgres://"):
    DATABASE_URL = DATABASE_URL.replace("postgres://", "postgresql://", 1)

# ⚙️ настройки движка
engine_kwargs = {"pool_pre_ping": True}

if DATABASE_URL.startswith("sqlite"):
    engine_kwargs["connect_args"] = {"check_same_thread": False}

engine = create_engine(DATABASE_URL, **engine_kwargs)

# 📌 сессии
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

# 📌 базовый класс
Base = declarative_base()


def bootstrap_database() -> None:
    # 🔥 КРИТИЧЕСКИ ВАЖНО — импорт моделей
    from app.models import user, wallet, operation

    # 🔥 создаём таблицы
    Base.metadata.create_all(bind=engine)

    inspector = inspect(engine)

    # 👇 ПРОВЕРЬ НАЗВАНИЕ ТАБЛИЦЫ
    # если у тебя __tablename__ = "users"
    if not inspector.has_table("users"):
        return

    user_columns = {column["name"] for column in inspector.get_columns("users")}

    # 👇 миграция (если вдруг старая БД)
    if "password_hash" in user_columns:
        return

    with engine.begin() as connection:
        connection.execute(
            text('ALTER TABLE "users" ADD COLUMN password_hash VARCHAR')
        )
