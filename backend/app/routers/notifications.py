from fastapi import APIRouter, Depends, HTTPException
from typing import List
from ..models import NotificationCreate, NotificationResponse
from ..services.firestore_service import FirestoreService
from ..config import get_db

router = APIRouter(tags=["notifications"])

def get_service(db=Depends(get_db)):
    return FirestoreService(db)

@router.post("/notifications/", response_model=NotificationResponse)
async def send_notification(notification: NotificationCreate, service: FirestoreService = Depends(get_service)):
    doc_id = await service.create_notification(notification.dict())
    return {**notification.dict(), "id": doc_id}

@router.get("/users/{user_id}/notifications/", response_model=List[NotificationResponse])
async def list_notifications(user_id: str, service: FirestoreService = Depends(get_service)):
    return await service.list_user_notifications(user_id)
