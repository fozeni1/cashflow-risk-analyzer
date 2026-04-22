from dotenv import load_dotenv
import os

load_dotenv("/Users/egor/Documents/cashflow-risk-analyzer/backend/.env")

print("JWT:", os.getenv("JWT_SECRET_KEY"))