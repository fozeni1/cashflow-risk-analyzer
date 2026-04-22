from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.api.v1.wallets import router as wallet_router
from app.api.v1.operations import router as operations_router
from app.api.v1.users import router as users_router

from app.database import bootstrap_database
from app.security import security

app = FastAPI()
security.handle_errors(app)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(wallet_router, prefix="/api/v1", tags=["wallet"])
app.include_router(operations_router, prefix="/api/v1", tags=["operations"])
app.include_router(users_router, prefix="/api/v1", tags=["users"])

# Создаем все таблицы в базе данных при старте приложения
bootstrap_database()
