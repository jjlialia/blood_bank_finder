"""
FILE: notifications.py (FastAPI Router)

DESCRIPTION:
This router manages the creation and retrieval of in-app alerts for users. 
While most notifications are created automatically during request updates, 
this router allows for manual alerts as well.

DATA FLOW OVERVIEW:
1. RECEIVES DATA FROM: 
   - Internal automated triggers (via Service) or manual Admin alerts.
2. PROCESSING:
   - User Matching: Ensures each notification is mapped to the correct 'userId'.
3. SENDS DATA TO:
   - 'FirestoreService': To add records to the 'notifications' collection.
4. OUTPUTS:
   - 'NotificationResponse': A list of alerts ready to be displayed in the app's bell icon.
"""

from fastapi import APIRouter, Depends, HTTPException
from typing import List
from app.models import NotificationCreate, NotificationResponse
from app.services.firestore_service import FirestoreService
from app.config import get_db

router = APIRouter(prefix="/notifications", tags=["notifications"])

def get_service(db=Depends(get_db)):
    """Injects the database service."""
    return FirestoreService(db)

@router.post("/", response_model=NotificationResponse)
async def create_notification(notification: NotificationCreate, service: FirestoreService = Depends(get_service)):
    """
    RECEIVED FROM: Backend Status Triggers (Internal Flow).
    SENT TO: `FirestoreService.create_notification` -> 'notifications' collection.
    """
    notif_id = await service.create_notification(notification.dict())
    return {**notification.dict(), "id": notif_id}

@router.get("/{user_id}", response_model=List[NotificationResponse])
async def list_notifications(user_id: str, service: FirestoreService = Depends(get_service)):
    """
    RECEIVED FROM: NotificationsScreen (Flutter).
    SENT TO: `FirestoreService.list_user_notifications`.
    """
    return await service.list_user_notifications(user_id)
