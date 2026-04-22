# Импортируем класс Decimal для точных вычислений с деньгами
from datetime import datetime
from decimal import Decimal

# Импортируем классы из библиотеки Pydantic для создания моделей данных и валидации

from pydantic import BaseModel, ConfigDict, Field, field_validator

from app.enum import CurrencyEnum


# Модель для описания операции с деньгами
# BaseModel из Pydantic автоматически валидирует данные
class OperationRequest(BaseModel):
    # Название кошелька (обязательное поле, максимум 127 символов)
    wallet_name: str = Field(..., max_length=127)
    # Сумма операции (обязательное поле, должна быть положительной)
    amount: Decimal
    # Описание операции (необязательное поле, максимум 255 символов)
    description: str | None = Field(None, max_length=255)

    # Валидатор для проверки что сумма положительная
    @field_validator('amount')
    def amount_must_be_positive(cls, v: Decimal) -> Decimal:
        # Проверяем что значение больше нуля
        if v <= 0:
            # Если нет - выбрасываем ошибку валидации
            raise ValueError('Amount must be positive')
        # Возвращаем значение если все ок
        return v

    # Валидатор для проверки что имя кошелька не пустое
    @field_validator('wallet_name')
    def wallet_name_not_empty(cls, v: str) -> str:
        # Убираем пробелы по краям
        v = v.strip()
        # Проверяем что строка не пустая
        if not v:
            # Если пустая - выбрасываем ошибку валидации
            raise ValueError('Wallet name cannot be empty')
        # Возвращаем очищенное значение
        return v


# Модель для создания кошелька
class CreateWalletRequest(BaseModel):
    # Название кошелька (обязательное поле, максимум 127 символов)
    name: str = Field(..., max_length=127)
    # Начальный баланс (необязательное поле, по умолчанию 0)
    initial_balance: Decimal = 0

    # Валюта кошелька (по умолчанию российский рубль)
    currency: CurrencyEnum = CurrencyEnum.RUB

    # Валидатор для проверки что имя кошелька не пустое
    @field_validator('name')
    def name_not_empty(cls, v: str) -> str:
        # Убираем пробелы по краям
        v = v.strip()
        # Проверяем что строка не пустая
        if not v:
            # Если пустая - выбрасываем ошибку валидации
            raise ValueError('Wallet name cannot be empty')
        # Возвращаем очищенное значение
        return v

    # Валидатор для проверки что начальный баланс не отрицательный
    @field_validator('initial_balance')
    def balance_not_negative(cls, v: Decimal) -> Decimal:
        # Проверяем что значение не отрицательное
        if v < 0:
            # Если отрицательное - выбрасываем ошибку валидации
            raise ValueError('Initial balance cannot be negative')
        # Возвращаем значение если все ок
        return v

# Модель для создания пользователя
class UserRequest(BaseModel):
    username: str = Field(..., max_length=127)
    password: str = Field(..., max_length=127)


class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"


# Модель для ответа с информацией о пользователе
class UserResponse(BaseModel):
    # Настройка для автоматического создания модели из атрибутов объекта (например, из модели SQLAlchemy)
    model_config = ConfigDict(from_attributes=True)
    # Уникальный идентификатор пользователя
    id: int
    username: str = Field(validation_alias="login")

# Модель для ответа с информацией о кошельке
class WalletResponse(BaseModel):
    # Настройка для автоматического создания модели из атрибутов объекта (например, из модели SQLAlchemy)
    model_config = {"from_attributes": True}

    # Уникальный идентификатор кошелька
    id: int
    # Название кошелька
    name: str
    # Баланс кошелька
    balance: Decimal
    # Валюта кошелька
    currency: CurrencyEnum

# Модель для ответа с информацией об операции
class OperationResponse(BaseModel):
    # Настройка для автоматического создания модели из атрибутов объекта (например, из модели SQLAlchemy)
    model_config = {"from_attributes": True}

    # Уникальный идентификатор операции
    id: int
    # Идентификатор кошелька, к которому относится операция
    wallet_id: int
    # Тип операции (расход или доход)
    type: str
    # Сумма операции
    amount: Decimal
    # Валюта операции
    currency: CurrencyEnum
    # Категория операции
    category: str | None
    # Подкатегория операции
    subcategory: str | None
    # Дата и время создания операции
    created_at: datetime


class TotalBalance(BaseModel):
    total_balance: Decimal


class PredictionResponse(BaseModel):
    predicted_expense: float
    predicted_balance: float
