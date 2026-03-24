from decimal import Decimal
from typing import Dict, Tuple
import aiohttp

from app.enum import CurrencyEnum

# Словарь с резервными курсами валют (используется когда внешний API недоступен)
# Ключ - кортеж из двух валют (базовая валюта, целевая валюта)
# Значение - курс обмена
FALLBACK_RATES: Dict[Tuple[str, str], Decimal] = {
    (CurrencyEnum.USD, CurrencyEnum.RUB): Decimal(str(95.0)),  # Курс обмена USD->RUB
    (CurrencyEnum.USD, CurrencyEnum.EUR): Decimal(str(0.92)),  # Курс обмена USD->EUR
    (CurrencyEnum.EUR, CurrencyEnum.RUB): Decimal(str(103.26)),  # Курс обмена EUR->RUB
    (CurrencyEnum.RUB, CurrencyEnum.USD): Decimal(str(0.0105)),  # Курс обмена RUB->USD
    (CurrencyEnum.EUR, CurrencyEnum.USD): Decimal(str(1.087)),  # Курс обмена EUR->USD
    (CurrencyEnum.RUB, CurrencyEnum.EUR): Decimal(str(0.0097)),  # Курс обмена RUB->EUR
}


async def get_exchange_rate(base: CurrencyEnum, target: CurrencyEnum) -> Decimal:
    # Формируем URL для запроса курса валют из внешнего API
    url = f"https://cdn.jsdelivr.net/npm/@fawazahmed0/currency-api@latest/v1/currencies/{base}.json"

    # Устанавливаем таймаут для запроса (5 секунд)
    timeout = aiohttp.ClientTimeout(total=5.0)

    try:
        # Создаем асинхронную сессию для HTTP запросов
        async with aiohttp.ClientSession(timeout=timeout) as session:
            # Выполняем GET запрос к API курсов валют
            async with session.get(url) as response:
                # Проверяем что запрос успешен (статус 200)
                response.raise_for_status()
                # Получаем данные в формате JSON
                data = await response.json()
                # Извлекаем словарь курсов для базовой валюты
                base_map = data.get(base, {})
                # Получаем курс обмена для целевой валюты
                rate = base_map.get(target)

        # Если курс найден и это число - возвращаем его
        if rate is not None and isinstance(rate, (int, float)):
            return Decimal(rate)
        # Если курс не найден - выбрасываем исключение
        raise KeyError('Rate not found')

    except Exception:
        # Если внешний API недоступен - ищем курс в словаре резервных курсов
        # Если курс не найден - возвращаем 1 (без конвертации)
        return FALLBACK_RATES.get((base, target), Decimal(1))