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
from ..models import NotificationCreate, NotificationResponse
from ..services.firestore_service import FirestoreService
from ..config import get_db

router = APIRouter(prefix="/notifications", tags=["notifications"])

def get_service(db=Depends(get_db)):
    """Injects the database service."""
    return FirestoreService(db)

@router.post("/notifications/", response_model=NotificationResponse)
async def send_notification(notification: NotificationCreate, service: FirestoreService = Depends(get_service)):
    """
    DATA FLOW: Admin Logic -> This Handler -> Firestore.
    Creates a new manual alert for a specific user.
    """
    doc_id = await service.create_notification(notification.dict())
    return {**notification.dict(), "id": doc_id}

@router.get("/users/{user_id}/notifications/", response_model=List[NotificationResponse])
async def list_notifications(user_id: str, service: FirestoreService = Depends(get_service)):
    """
    DATA FLOW: Bell Icon (App) -> This Handler -> Fetches latest user alerts.
    Provides the list of read/unread notifications to the frontend.
    """
    return await service.list_user_notifications(user_id)
