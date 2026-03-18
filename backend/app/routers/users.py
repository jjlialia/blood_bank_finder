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

from fastapi import APIRouter, Depends, HTTPException
from typing import List
from ..models import UserCreate, UserResponse
from ..services.firestore_service import FirestoreService
from ..config import get_db

router = APIRouter(prefix="/users", tags=["users"])

def get_service(db=Depends(get_db)):
    """Dependency to get the database service."""
    return FirestoreService(db)

@router.post("/", response_model=UserResponse)
async def create_user(user: UserCreate, service: FirestoreService = Depends(get_service)):
    """
    DATA FLOW: Signup Screen (Flutter) -> This Handler -> create_or_update_user in Service.
    Authenticates and saves a new user profile.
    """
    try:
        return await service.create_or_update_user(user.uid, user.dict())
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to create user: {str(e)}")

@router.get("/{uid}", response_model=UserResponse)
async def get_user(uid: str, service: FirestoreService = Depends(get_service)):
    """
    DATA FLOW: App Startup -> This Handler -> Firestore -> UI.
    Fetches the profile for the currently logged-in user.
    """
    user = await service.get_user(uid)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    return user

@router.get("/", response_model=List[UserResponse])
async def list_users(service: FirestoreService = Depends(get_service)):
    """
    DATA FLOW: Manage Users Screen (Admin) -> This Handler -> List of all accounts.
    Allows Super Admins to see everyone registered in the system.
    """
    try:
        return await service.list_all_users()
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to list users: {str(e)}")

@router.patch("/{uid}/ban")
async def toggle_ban(uid: str, is_banned: bool, service: FirestoreService = Depends(get_service)):
    """
    USER INPUT: Admin clicks 'Ban' button.
    DATA FLOW: UI -> This Handler -> Updates 'isBanned' field in Firestore.
    """
    try:
        await service.toggle_user_ban(uid, is_banned)
        return {"message": "User ban status updated"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to update ban status: {str(e)}")

@router.patch("/{uid}/role")
async def update_role(uid: str, role: str, hospital_id: str = None, service: FirestoreService = Depends(get_service)):
    """
    USER INPUT: Admin promotes user to 'hospital_admin' and selects a site.
    DATA FLOW: UI -> This Handler -> Updates 'role' and 'hospitalId' in Firestore.
    """
    await service.update_user_role(uid, role, hospital_id)
    return {"message": "User role updated"}
