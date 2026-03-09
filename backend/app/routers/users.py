from fastapi import APIRouter, Depends, HTTPException
from typing import List
from ..models import UserCreate, UserResponse
from ..services.firestore_service import FirestoreService
from ..config import get_db

router = APIRouter(prefix="/users", tags=["users"])

def get_service(db=Depends(get_db)):
    return FirestoreService(db)

@router.post("/", response_model=UserResponse)
async def create_user(user: UserCreate, service: FirestoreService = Depends(get_service)):
    return await service.create_or_update_user(user.uid, user.dict())

@router.put("/{uid}", response_model=UserResponse)
async def update_user(uid: str, user: UserCreate, service: FirestoreService = Depends(get_service)):
    await service.update_user(uid, user.dict())
    return {**user.dict(), "uid": uid}

@router.get("/{uid}", response_model=UserResponse)
async def get_user(uid: str, service: FirestoreService = Depends(get_service)):
    user = await service.get_user(uid)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    return user

@router.get("/", response_model=List[UserResponse])
async def list_users(service: FirestoreService = Depends(get_service)):
    return await service.list_all_users()

@router.patch("/{uid}/ban")
async def toggle_ban(uid: str, is_banned: bool, service: FirestoreService = Depends(get_service)):
    await service.toggle_user_ban(uid, is_banned)
    return {"message": "User ban status updated"}

@router.patch("/{uid}/role")
async def update_role(uid: str, role: str, hospital_id: str = None, service: FirestoreService = Depends(get_service)):
    await service.update_user_role(uid, role, hospital_id)
    return {"message": "User role updated"}
