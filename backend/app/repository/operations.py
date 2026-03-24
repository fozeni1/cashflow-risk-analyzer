from datetime import datetime
from decimal import Decimal

from sqlalchemy.orm import Session

from app.enum import CurrencyEnum
from app.models import Operation


def create_operation(
    db: Session,
    wallet_id: int,
    type: str,
    amount: Decimal,
    currency: CurrencyEnum,
    category: str | None = None,
    subcategory: str | None = None,
) -> Operation:
    # Создаем новый объект операции с указанными параметрами
    operation = Operation(
        wallet_id=wallet_id,  # Идентификатор кошелька
        type=type,  # Тип операции
        amount=amount,  # Сумма операции
        currency=currency,  # Валюта операции
        category=category,  # Категория операции
        subcategory=subcategory,  # Подкатегория операции
    )
    db.add(operation)  # Добавляем операцию в сессию базы данных
    db.flush()  # Применяем изменения к базе данных (но не сохраняем транзакцию)
    return operation  # Возвращаем созданный объект операции

def get_operations_list(
    db: Session,
    wallets_ids: list[int],  # Список идентификаторов кошельков для фильтрации
    date_from: datetime | None,  # Начальная дата для фильтрации (необязательный параметр)
    date_to: datetime | None,  # Конечная дата для фильтрации (необязательный параметр)
) -> list[Operation]:
    # Начинаем запрос к таблице операций
    # Фильтруем операции по списку идентификаторов кошельков
    query = db.query(Operation).filter(Operation.wallet_id.in_(wallets_ids))

    # Если указана начальная дата - добавляем фильтр по дате создания операции
    if date_from:
        query = query.filter(Operation.created_at >= date_from)

    # Если указана конечная дата - добавляем фильтр по дате создания операции
    if date_to:
        query = query.filter(Operation.created_at <= date_to)

    # Возвращаем все найденные операции
    return query.all()