from enum import StrEnum, auto


# Перечисление доступных валют
class CurrencyEnum(StrEnum):
    RUB = auto()
    USD = auto()
    EUR = auto()

# Перечисление типов операций с деньгами
class OperationType(StrEnum):
    EXPENSE = auto()
    INCOME = auto()
    TRANSFER = auto()