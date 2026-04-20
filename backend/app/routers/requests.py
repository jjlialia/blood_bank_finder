
from fastapi import APIRouter, Depends, HTTPException
from typing import List, Optional
from app.models import BloodRequestCreate, BloodRequestResponse
from app.services.firestore_service import FirestoreService
from app.config import get_db

router = APIRouter(prefix="/blood-requests", tags=["blood-requests"])

def get_service(db=Depends(get_db)):
    """Injects the Firestore service."""
    return FirestoreService(db)

@router.post("/", response_model=BloodRequestResponse)
async def create_request(request: BloodRequestCreate, service: FirestoreService = Depends(get_service)):
    """
    r : RequestBloodScreen / DonateBloodScreen. s: `FirestoreService.create_blood_request` -> 'blood_requests' collection.
    """
    request_id = await service.create_blood_request(request.dict())
    return {**request.dict(), "id": request_id}

@router.get("/", response_model=List[BloodRequestResponse])
async def list_requests(hospital_id: Optional[str] = None, service: FirestoreService = Depends(get_service)):
    # This endpoint is dual-purpose: Super Admin (all) or Hospital Admin (one site).
    if hospital_id:
        """
        RECEIVED FROM: HospitalAdmin Dashboard (Provider).
        SENT TO: `FirestoreService.list_hospital_requests`.
        """
        return await service.list_hospital_requests(hospital_id)
    """
    RECEIVED FROM: Super Admin History Screen.
    SENT TO: `FirestoreService.list_all_requests`.
    """
    return await service.list_all_requests()

@router.patch("/{request_id}/status")
async def update_status(
    request_id: str, 
    status: str, 
    admin_message: Optional[str] = None, 
    service: FirestoreService = Depends(get_service)
):
    """
    RECEIVED FROM: HospitalAdmin Dashboard (Action Button).
    SENT TO: `FirestoreService.update_request_status` -> Firestore & Notifications.
    """
    await service.update_request_status(request_id, status, admin_message)
    return {"message": "Request status updated"}


























"""
FILE: requests.py (FastAPI Router)

DESCRIPTION:
This router is the heart of the "Blood Transaction" system. It manages 
all requests from users looking for blood and all donation pledges.

DATA FLOW OVERVIEW:
1. RECEIVES DATA FROM: 
   - 'DonateBloodScreen' or 'RequestBloodScreen' in the Flutter app.
2. PROCESSING:
   - Status Updates: Allows Hospital Admins to move a request from 
     'pending' to 'on progress' or 'completed'.
   - Trigger Logic: Note that 'FirestoreService' automatically sends 
     notifications when these status updates happen.
3. SENDS DATA TO:
   - 'FirestoreService': To manage the 'blood_requests' collection.
4. OUTPUTS:
   - 'BloodRequestResponse': The record of the request, including its unique ID.
"""
