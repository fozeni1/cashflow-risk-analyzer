# Используем лёгкий Python
FROM python:3.11-slim

# Рабочая директория
WORKDIR /app

# Устанавливаем системные зависимости (если нужны)
RUN apt-get update && apt-get install -y \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Копируем зависимости
COPY requirements.txt .

# Устанавливаем зависимости
RUN pip install --no-cache-dir -r requirements.txt

# Копируем весь проект
COPY . .

# Открываем порт
EXPOSE 8080
ENV PYTHONPATH=/app
# Запуск FastAPI
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8080"]