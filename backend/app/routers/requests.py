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

from fastapi import APIRouter, Depends, HTTPException
from typing import List, Optional
from ..models import BloodRequestCreate, BloodRequestResponse
from ..services.firestore_service import FirestoreService
from ..config import get_db

router = APIRouter(prefix="/blood-requests", tags=["blood-requests"])

def get_service(db=Depends(get_db)):
    """Injects the Firestore service."""
    return FirestoreService(db)

@router.post("/", response_model=BloodRequestResponse)
async def create_request(request: BloodRequestCreate, service: FirestoreService = Depends(get_service)):
    """
    DATA FLOW: Submit Button (Form) -> This Handler -> Adds to 'blood_requests' collection.
    Initializes a new request with 'status: pending'.
    """
    doc_id = await service.create_blood_request(request.dict())
    return {**request.dict(), "id": doc_id}

@router.get("/", response_model=List[BloodRequestResponse])
async def list_requests(service: FirestoreService = Depends(get_service)):
    """
    DATA DESTINATION: Super Admin Dashboard.
    Fetches every single request regardless of hospital.
    """
    return await service.list_all_requests()

@router.get("/hospital/{hospital_id}", response_model=List[BloodRequestResponse])
async def list_hospital_requests(hospital_id: str, service: FirestoreService = Depends(get_service)):
    """
    DATA DESTINATION: Hospital Admin Requests Screen.
    Filters transactions to only show those relevant to one specific site.
    """
    return await service.list_hospital_requests(hospital_id)

@router.patch("/{request_id}/status")
async def update_status(request_id: str, status: str, admin_message: Optional[str] = None, 
                        service: FirestoreService = Depends(get_service)):
    """
    USER INPUT: Hospital Admin selects a new status from a dropdown.
    DATA FLOW: UI -> This Handler -> Updates Doc -> Automatically Notifies User via Service.
    """
    await service.update_request_status(request_id, status, admin_message)
    return {"message": f"Request status updated to {status}"}
