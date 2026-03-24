# Импортируем класс APIRouter для создания API endpoints
from fastapi import APIRouter, Depends  # Импортируем классы для создания API endpoints и dependency injection
# Импортируем класс Session для работы с базой данных
from sqlalchemy.orm import Session

from app.api.v1.users import get_current_user  # Импортируем функцию для получения текущего пользователя
# Импортируем функцию для получения сессии базы данных через dependency injection
from app.dependency import get_db
from app.models import User  # Импортируем модель пользователя
# Импортируем модель данных для создания кошелька
from app.schemas import CreateWalletRequest, WalletResponse
# Импортируем сервис для работы с кошельками
from app.service import wallets as wallets_service

# Создаем роутер для группировки endpoints связанных с кошельками
router = APIRouter()

@router.get("/balance")
async def get_balance(db: Session = Depends(get_db),  # Сессия базы данных через dependency injection
                current_user: User = Depends(get_current_user)):  # Текущий пользователь из токена авторизации
    # Вызываем сервис для получения баланса кошелька или общего баланса
    return await wallets_service.get_total_balance(db, current_user)  # Если wallet_name None - возвращается общий баланс

@router.post("/wallets", response_model=WalletResponse)
def create_wallet(wallet: CreateWalletRequest, db: Session = Depends(get_db),  # Сессия базы данных через dependency injection
                current_user: User = Depends(get_current_user)):  # Текущий пользователь из токена авторизации
    # Вызываем сервис для создания нового кошелька
    return wallets_service.create_wallet(db, current_user, wallet)


@router.get("/wallets", response_model=list[WalletResponse])
def get_all_wallets(db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):  # Сессия базы данных и текущий пользователь через dependency injection
    # Вызываем сервис для получения списка всех кошельков пользователя
    return wallets_service.get_all_wallets(db, current_user)
