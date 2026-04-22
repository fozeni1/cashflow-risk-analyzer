from __future__ import annotations

from datetime import datetime
from functools import lru_cache
from pathlib import Path
from typing import Any

from sqlalchemy import func
from sqlalchemy.orm import Session

from app.enum import OperationType
from app.models import Operation, Wallet


class PredictionUnavailableError(RuntimeError):
    pass


def _load_ml_dependencies() -> tuple[Any, Any, Any]:
    try:
        import joblib
        import numpy as np
        import pandas as pd
    except ModuleNotFoundError as exc:
        raise PredictionUnavailableError("ML dependencies are not installed") from exc

    return joblib, np, pd


@lru_cache(maxsize=1)
def _load_model_bundle() -> tuple[Any, list[str]]:
    joblib, _, _ = _load_ml_dependencies()
    model_path = Path(__file__).resolve().parent.parent / "model" / "model.pkl"
    if not model_path.exists():
        raise PredictionUnavailableError("ML model file is missing")

    try:
        model_data = joblib.load(model_path)
    except Exception as exc:
        raise PredictionUnavailableError("ML model could not be loaded") from exc

    model = model_data.get("model")
    features = model_data.get("features")
    if model is None or not isinstance(features, list):
        raise PredictionUnavailableError("ML model bundle has invalid structure")

    return model, features


def get_daily_expenses(db: Session, user_id: int) -> list[float]:
    result = (
        db.query(func.date(Operation.created_at), func.sum(Operation.amount))
        .join(Wallet, Wallet.id == Operation.wallet_id)
        .filter(Operation.type == OperationType.EXPENSE, Wallet.user_id == user_id)
        .group_by(func.date(Operation.created_at))
        .order_by(func.date(Operation.created_at))
        .all()
    )

    return [float(row[1]) for row in result]


def build_features(data: list[float]) -> Any:
    _, np, pd = _load_ml_dependencies()
    df = pd.DataFrame({"total": data})

    df["day_index"] = np.arange(len(df))
    df["day_of_week"] = datetime.today().weekday()
    df["prev_amount"] = df["total"].shift(1)

    df = df.dropna()
    if df.empty:
        return df

    return df.iloc[-1:]


def align_features(df: Any, features: list[str]) -> Any:
    for col in features:
        if col not in df:
            df[col] = 0

    return df[features]


def get_total_balance(db: Session, user_id: int) -> float:
    result = (
        db.query(func.sum(Wallet.balance))
        .filter(Wallet.user_id == user_id)
        .scalar()
    )

    return float(result or 0)


def predict_expense(db: Session, user_id: int) -> dict[str, float]:
    data = get_daily_expenses(db, user_id)
    total_balance = get_total_balance(db, user_id)

    if len(data) < 2:
        return {
            "predicted_expense": 0.0,
            "predicted_balance": total_balance,
        }

    model, features = _load_model_bundle()

    df = build_features(data)
    if df.empty:
        return {
            "predicted_expense": 0.0,
            "predicted_balance": total_balance,
        }

    df = align_features(df, features)

    prediction = model.predict(df)
    predicted_expense = abs(float(prediction[0]))
    predicted_balance = total_balance - predicted_expense

    return {
        "predicted_expense": predicted_expense,
        "predicted_balance": predicted_balance
    }
