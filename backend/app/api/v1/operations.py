# Импортируем класс APIRouter для создания API endpoints
from datetime import datetime  # Импортируем класс datetime для работы с датами

from fastapi import APIRouter, Depends, Query  # Импортируем классы для создания API endpoints и dependency injection
# Импортируем класс Session для работы с базой данных
from sqlalchemy.orm import Session

# Импортируем функцию для получения сессии базы данных через dependency injection
from app.dependency import get_db, get_current_user
from app.models import User  # Импортируем модель пользователя
# Импортируем модель данных для операций с деньгами
from app.schemas import OperationRequest, OperationResponse
# Импортируем сервис для работы с операциями
from app.service import operations as operations_service

# Создаем роутер для группировки endpoints связанных с операциями
router = APIRouter()

@router.post("/operations/income", response_model=OperationResponse)
def add_income(operation: OperationRequest, db: Session = Depends(get_db),  # Сессия базы данных через dependency injection
                current_user: User = Depends(get_current_user)):  # Текущий пользователь из токена авторизации
    # Вызываем сервис для добавления дохода к балансу кошелька
    return operations_service.add_income(db, current_user, operation)


@router.post("/operations/expense", response_model=OperationResponse)
def add_expense(operation: OperationRequest, db: Session = Depends(get_db),  # Сессия базы данных через dependency injection
                current_user: User = Depends(get_current_user)):  # Текущий пользователь из токена авторизации
    # Вызываем сервис для добавления расхода (вычитания из баланса кошелька)
    return operations_service.add_expense(db, current_user, operation)

@router.get("/operations", response_model=list[OperationResponse])
def get_operations_list(
    wallet_id: int | None = Query(None),  # Фильтр по идентификатору кошелька (необязательный параметр)
    date_from: datetime | None = Query(None),  # Фильтр по начальной дате (необязательный параметр)
    date_to: datetime | None = Query(None),  # Фильтр по конечной дате (необязательный параметр)
    user: User = Depends(get_current_user),  # Текущий пользователь из токена авторизации
    db: Session = Depends(get_db),  # Сессия базы данных
):
    # Вызываем сервис для получения списка операций с фильтрами
    return operations_service.get_operations_list(db, user, wallet_id, date_from, date_to)
