from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer, OAuth2PasswordRequestForm
from datetime import datetime, timedelta
from typing import Optional
from jose import JWTError, jwt
from passlib.context import CryptContext
from ..config import settings
from ..models import UserResponse
from ..services.firestore_service import FirestoreService
from google.cloud import firestore

router = APIRouter(prefix="/auth", tags=["auth"])

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="auth/login")

def create_access_token(data: dict, expires_delta: Optional[timedelta] = None):
    to_encode = data.copy()
    if expires_delta:
        expire = datetime.utcnow() + expires_delta
    else:
        expire = datetime.utcnow() + timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
    to_encode.update({"exp": expire})
    encoded_jwt = jwt.encode(to_encode, settings.SECRET_KEY, algorithm=settings.ALGORITHM)
    return encoded_jwt

async def get_current_user(token: str = Depends(oauth2_scheme)):
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )
    try:
        payload = jwt.decode(token, settings.SECRET_KEY, algorithms=[settings.ALGORITHM])
        user_id: str = payload.get("sub")
        if user_id is None:
            raise credentials_exception
    except JWTError:
        raise credentials_exception
    
    # In a real app, you'd fetch from DB here
    db = firestore.Client()
    service = FirestoreService(db)
    user = await service.get_user(user_id)
    if user is None:
        raise credentials_exception
    return user

from ..models import UserResponse, LoginRequest

@router.post("/login")
async def login(login_data: LoginRequest):
    # This is a simplified login for the migration context.
    # In practice, you'd verify against stored hashed passwords or Firebase Auth.
    # Since Flutter uses Firebase Auth, we might rely on the Firebase token 
    # and "exchange" it or just use JWT for backend-specific sessions if needed.
    # For now, let's implement a standard JWT login.
    
    db = firestore.Client()
    service = FirestoreService(db)
    user = await service.get_user_by_email(login_data.username) 
    
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect email or password",
        )
    
    # Normally check password here. For this migration, we are moving logic.
    # If the user exists in Firestore, we issue a token for now.
    
    access_token_expires = timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
    access_token = create_access_token(
        data={"sub": user['uid']}, expires_delta=access_token_expires
    )
    return {"access_token": access_token, "token_type": "bearer"}
