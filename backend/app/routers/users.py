
from fastapi import APIRouter, Depends, HTTPException
from typing import List, Optional
from app.models import UserCreate, UserResponse
from app.services.firestore_service import FirestoreService
from app.config import get_db

router = APIRouter(prefix="/users", tags=["users"])

def get_service(db=Depends(get_db)):
    """Dependency to get the database service."""
    return FirestoreService(db)

@router.post("/", response_model=UserResponse)
async def create_user(user: UserCreate, service: FirestoreService = Depends(get_service)):
    """
    DATA FLOW: Signup Screen (Flutter) -> This Handler -> create_or_update_user in Service.
    Authenticates and saves a new user profile.
    RECEIVED FROM: SignupScreen (Flutter).
    SENT TO: `FirestoreService.create_or_update_user` -> 'users' collection.
    """
    return await service.create_or_update_user(user.uid, user.dict())

@router.get("/{user_id}", response_model=UserResponse)
async def get_user(user_id: str, service: FirestoreService = Depends(get_service)):
    """
    RECEIVED FROM: AuthProvider (Flutter).
    SENT TO: `FirestoreService.get_user`.
    """
    user = await service.get_user(user_id)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    return user

@router.get("/", response_model=List[UserResponse])
async def list_users(service: FirestoreService = Depends(get_service)):
    """
    RECEIVED FROM: ManageUsersScreen (Super Admin).
    SENT TO: `FirestoreService.list_all_users`.
    """
    return await service.list_all_users()

@router.patch("/{user_id}/ban")
async def toggle_ban(user_id: str, is_banned: bool, service: FirestoreService = Depends(get_service)):
    """
    RECEIVED FROM: ManageUsersScreen (Admin Action).
    SENT TO: `FirestoreService.toggle_user_ban`.
    """
    await service.toggle_user_ban(user_id, is_banned)
    return {"message": "User ban status updated"}

@router.patch("/{user_id}/role")
async def update_role(user_id: str, role: str, hospital_id: Optional[str] = None, service: FirestoreService = Depends(get_service)):
    """
    RECEIVED FROM: UserRolesScreen (Admin Action).
    SENT TO: `FirestoreService.update_user_role`.
    """
    await service.update_user_role(user_id, role, hospital_id)
    return {"message": "User role updated"}

























"""
FILE: users.py (FastAPI Router)

DESCRIPTION:
This router handles all User-related operations. It manages the lifecycle 
of a user profile, from initial registration to admin-led role promotions.

DATA FLOW OVERVIEW:
1. RECEIVES DATA FROM: 
   - The Flutter Frontend (Signup, Profile, and Admin screens).
2. PROCESSING:
   - Auth Logic: Connects the unique 'uid' from Firebase Auth to a 
     structured 'UserModel' in Firestore.
   - Admin Controls: Allows Super Admins to 'Ban' users or change their roles.
3. SENDS DATA TO:
   - 'FirestoreService': To persist the user data in the 'users' collection.
4. OUTPUTS:
   - 'UserResponse': JSON data representing the user's current status and profile.
"""
