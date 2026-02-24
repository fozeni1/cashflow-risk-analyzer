![Python](https://img.shields.io/badge/Python-3.11-blue)
![FastAPI](https://img.shields.io/badge/FastAPI-async-green)
![Flutter](https://img.shields.io/badge/Flutter-mobile-blue)
![Status](https://img.shields.io/badge/status-in%20development-yellow)
<h1>ПАК анализа финансовой устойчивости пользователя</h1>
<p align="center">Это система анализа личных финансов</p><br>

## Что будет?

- Расчёт индекса финансовой устойчивости (FSI)
- Расчёт горизонта исчерпания накоплений
- ML-модуль прогнозирования баланса

<p>Проект представляет собой программно-аппаратный 
комплекс для анализа финансовой устойчивости пользователя, в котором 
серверная часть развёрнута на Raspberry Pi Zero. Система предназначена 
для предоставления информации о доходах и расходах, проведения 
аналитического расчёта финансовых показателей. 
Пользователь взаимодействует с системой через мобильное приложение, 
а все вычисления выполняются на сервере. Функциональный модуль финансовой 
аналитики реализует расчёт коэффициентов финансовой устойчивости, 
анализ обязательной нагрузки, прогнозирование будущего баланса.</p>
<p>Структура проекта следующая:</p>
<p align="center">Flutter client<br>
        ↓<br>
REST API<br>
        ↓<br>
FastAPI Backend (Raspberry Pi Zero)<br>
        ↓<br>
Financial Core Module<br>
        ↓<br>
SQLite Database
</p>
Нейронка строит такую файловую структуру проекта:<br><br>

```bash
cashflow-risk-analyzer/
│
├── .vscode/                     # VS Code configuration
│   ├── settings.json
│   ├── launch.json
│   └── extensions.json
│
├── backend/            # FastAPI server (Raspberry Pi)
│   ├── app/
│   │   ├── main.py
│   │   │
│   │   ├── core/
│   │   │   ├── config.py
│   │   │   ├── security.py
│   │   │   ├── auth_2fa.py
│   │   │   └── dependencies.py
│   │   │
│   │   ├── db/
│   │   │   ├── database.py
│   │   │   ├── models.py
│   │   │   ├── repositories.py
│   │   │   └── migrations/
│   │   │
│   │   ├── schemas/
│   │   │   ├── user.py
│   │   │   ├── transaction.py
│   │   │   ├── analytics.py
│   │   │   └── scenario.py
│   │   │
│   │   ├── api/
│   │   │   ├── auth.py
│   │   │   ├── users.py
│   │   │   ├── transactions.py
│   │   │   ├── analytics.py
│   │   │   └── scenarios.py
│   │   │
│   │   ├── finance_core/ # Financial computation engine
│   │   │   ├── __init__.py
│   │   │   ├── statistics.py
│   │   │   ├── metrics.py
│   │   │   ├── risk_analysis.py
│   │   │   ├── forecasting.py
│   │   │   └── scenario_engine.py
│   │   │
│   │   └── services/
│   │       ├── analytics_service.py
│   │       ├── transaction_service.py
│   │       └── user_service.py
│   │
│   ├── requirements.txt
│   └── .env
│
├── frontend/                    # Flutter client
│   ├── lib/
│   └── pubspec.yaml
│
├── docs/
├── README.md
└── .gitignore
```
Важно учесть, что она может поменяться
## Tech Stack

**Backend**
- Python 3.11+
- FastAPI
- SQLite
- JWT + 2FA (TOTP)

**Frontend**
- Flutter (Dart)

**Hardware**
- Raspberry Pi Zero

##  Roadmap

- [x] Архитектура проекта
- [ ] Базовый CRUD транзакций
- [ ] Реализация Fast API
- [ ] Risk Analysis
- [ ] ML-прогнозирование
- [ ] Деплой на Raspberry Pi
