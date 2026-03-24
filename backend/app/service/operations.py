# Импортируем класс HTTPException для обработки ошибок HTTP запросов
from datetime import datetime

from fastapi import HTTPException
# Импортируем класс Session для работы с базой данных
from sqlalchemy.orm import Session

from app.enum import OperationType
from app.models import User
# Импортируем модель данных для операций с деньгами
from app.schemas import OperationRequest, OperationResponse
# Импортируем репозиторий для работы с кошельками
from app.repository import wallets as wallets_repository
from app.repository import operations as operations_repository


def add_income(db: Session, current_user: User, operation: OperationRequest) -> OperationResponse:
    # Проверяем существует ли кошелек
    if not wallets_repository.is_wallet_exist(db, current_user.id, operation.wallet_name):
        raise HTTPException(
            status_code=404,
            detail=f"Wallet '{operation.wallet_name}' not found"
        )  # Если кошелька нет - возвращаем ошибку 404

    wallet = wallets_repository.add_income(db, current_user.id, operation.wallet_name, operation.amount)
    # Создаем запись об операции дохода через репозиторий
    operation = operations_repository.create_operation(
        db=db,
        wallet_id=wallet.id,  # Идентификатор кошелька
        type=OperationType.INCOME,  # Тип операции - доход
        amount=operation.amount,  # Сумма операции
        currency=wallet.currency,  # Валюта операции (из кошелька)
        category=operation.description,  # Категория операции (из описания)
    )
    # Сохраняем изменения в базе данных
    db.commit()
    # Возвращаем информацию об операции
    return OperationResponse.model_validate(operation)

def add_expense(db: Session, current_user: User, operation: OperationRequest) -> OperationResponse:
    # Проверяем существует ли кошелек
    if not wallets_repository.is_wallet_exist(db, current_user.id, operation.wallet_name):
        raise HTTPException(
            status_code=404,
            detail=f"Wallet '{operation.wallet_name}' not found"
        )  # Если кошелька нет - возвращаем ошибку 404

    # Валидация amount > 0 теперь в модели OperationRequest!

    # Проверяем достаточно ли средств в кошельке (это бизнес-логика, не валидация!)
    # Получаем текущий баланс кошелька из репозитория
    wallet = wallets_repository.get_wallet_balance_by_name(db, current_user.id, operation.wallet_name)
    if wallet.balance < operation.amount:  # Если баланс меньше суммы расхода
        raise HTTPException(
            status_code=400,
            detail=f"Insufficient funds. Available: {wallet.balance}"
        )  # Если денег недостаточно - возвращаем ошибку 400

    # Вычитаем расход из баланса кошелька через репозиторий
    wallet = wallets_repository.add_expense(db, current_user.id, operation.wallet_name, operation.amount)
    # Создаем запись об операции расхода через репозиторий
    operation = operations_repository.create_operation(
        db=db,
        wallet_id=wallet.id,  # Идентификатор кошелька
        type=OperationType.EXPENSE,  # Тип операции - расход
        amount=operation.amount,  # Сумма операции
        currency=wallet.currency,  # Валюта операции (из кошелька)
        category=operation.description,  # Категория операции (из описания)
    )
    # Сохраняем изменения в базе данных
    db.commit()
    # Возвращаем информацию об операции
    return OperationResponse.model_validate(operation)


def get_operations_list(
    db: Session,
    current_user: User,
    wallet_id: int | None = None,  # Фильтр по идентификатору кошелька (необязательный параметр)
    date_from: datetime | None = None,  # Фильтр по начальной дате (необязательный параметр)
    date_to: datetime | None = None  # Фильтр по конечной дате (необязательный параметр)
) -> list[OperationResponse]:
    """
    Получает список операций пользователя с фильтрацией по кошельку и датам
    
    Args:
        db: Сессия базы данных
        current_user: Текущий пользователь
        wallet_id: Идентификатор кошелька для фильтрации (если не указан, возвращаются операции всех кошельков)
        date_from: Начальная дата для фильтрации
        date_to: Конечная дата для фильтрации
        
    Returns:
        Список операций в формате OperationResponse
        
    Raises:
        HTTPException: Если указанный кошелек не найден
    """
    # Если указан идентификатор кошелька - фильтруем по нему
    if wallet_id:
        # Получаем кошелек по идентификатору из репозитория
        wallet = wallets_repository.get_wallet_by_id(db, current_user.id, wallet_id)
        # Проверяем существует ли кошелек
        if not wallet:
            raise HTTPException(
                status_code=404,
                detail=f"Wallet '{wallet_id}' not found"
            )  # Если кошелька нет - возвращаем ошибку 404

        # Используем только указанный кошелек для фильтрации
        wallets_ids = [wallet.id]
    else:
        # Если кошелек не указан - получаем все кошельки пользователя
        wallets = wallets_repository.get_all_wallets(db, current_user.id)
        # Формируем список идентификаторов всех кошельков пользователя
        wallets_ids = [w.id for w in wallets]

    # Получаем список операций из репозитория с фильтрацией
    operations = operations_repository.get_operations_list(
        db,
        wallets_ids,  # Список идентификаторов кошельков для фильтрации
        date_from,  # Начальная дата для фильтрации
        date_to  # Конечная дата для фильтрации
    )
    # Преобразуем модели SQLAlchemy в модели Pydantic для ответа
    result = []
    for operation in operations:
        result.append(OperationResponse.model_validate(operation))
    return result
