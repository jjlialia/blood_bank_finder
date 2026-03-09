import os
import firebase_admin
from firebase_admin import credentials, firestore
from dotenv import load_dotenv

load_dotenv()

from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    SECRET_KEY: str = os.getenv("SECRET_KEY", "your-secret-key-change-it-in-production")
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60 * 24 # 24 hours
    FIREBASE_SERVICE_ACCOUNT_PATH: str = os.getenv("FIREBASE_SERVICE_ACCOUNT_PATH")

    class Config:
        env_file = ".env"

settings = Settings()

def initialize_firebase():
    if not settings.FIREBASE_SERVICE_ACCOUNT_PATH:
        raise ValueError("FIREBASE_SERVICE_ACCOUNT_PATH not found in environment variables")
    
    if not firebase_admin._apps:
        cred = credentials.Certificate(settings.FIREBASE_SERVICE_ACCOUNT_PATH)
        firebase_admin.initialize_app(cred)

def get_db():
    initialize_firebase()
    return firestore.client()
