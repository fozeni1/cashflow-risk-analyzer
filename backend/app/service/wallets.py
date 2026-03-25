# Импортируем класс HTTPException для обработки ошибок HTTP запросов
from decimal import Decimal

from fastapi import HTTPException
# Импортируем класс Session для работы с базой данных
from sqlalchemy.orm import Session

from app.enum import CurrencyEnum
from app.models import User
# Импортируем репозиторий для работы с кошельками
from app.repository import wallets as wallets_repository
# Импортируем модель данных для создания кошелька
from app.schemas import CreateWalletRequest, WalletResponse, TotalBalance
from app.service import exchange_service

async def get_total_balance(db: Session, current_user: User) -> TotalBalance:
    # Получаем все кошельки пользователя из репозитория
    wallets = wallets_repository.get_all_wallets(db, current_user.id)
    # Инициализируем общий баланс нулем
    total_balance = Decimal(0)

    # Проходим по всем кошелькам пользователя
    for wallet in wallets:
        # Если валюта кошелька - рубли, просто добавляем баланс
        if wallet.currency == CurrencyEnum.RUB:
            total_balance += wallet.balance
        else:
            # Если валюта другая - получаем курс обмена в рубли
            exchange_rate = await exchange_service.get_exchange_rate(wallet.currency, CurrencyEnum.RUB)

            total_balance += exchange_rate * wallet.balance

    # Возвращаем общий баланс в рублях
    return TotalBalance(total_balance=total_balance)

def create_wallet(db: Session, current_user: User, wallet: CreateWalletRequest) -> WalletResponse:
    # Проверяем не существует ли уже такой кошелек
    if wallets_repository.is_wallet_exist(db, current_user.id, wallet.name):
        raise HTTPException(status_code=400, detail=f"Wallet '{wallet.name}' already exists")  # Если кошелек уже есть - возвращаем ошибку 400

    # Валидация name и initial_balance теперь в модели CreateWalletRequest!
    # Создаем новый кошелек с начальным балансом через репозиторий
    wallet = wallets_repository.create_wallet(db, current_user.id, wallet.name, wallet.initial_balance, wallet.currency)
    # Сохраняем изменения в базе данных
    db.commit()
    # Возвращаем информацию о созданном кошельке
    return WalletResponse.model_validate(wallet)


def get_all_wallets(db: Session, current_user: User) -> list[WalletResponse]:
    # Получаем все кошельки пользователя из репозитория
    wallets = wallets_repository.get_all_wallets(db, current_user.id)
    # Преобразуем модели SQLAlchemy в модели Pydantic для ответа
    return [WalletResponse.model_validate(wallet) for wallet in wallets]

