from fastapi import APIRouter, Depends, HTTPException
from typing import List
from ..models import BloodRequestCreate, BloodRequestResponse
from ..services.firestore_service import FirestoreService
from ..config import get_db

router = APIRouter(prefix="/blood-requests", tags=["blood-requests"])

def get_service(db=Depends(get_db)):
    return FirestoreService(db)

@router.post("/", response_model=BloodRequestResponse)
async def create_request(request: BloodRequestCreate, service: FirestoreService = Depends(get_service)):
    doc_id = await service.create_blood_request(request.dict())
    return {**request.dict(), "id": doc_id}

@router.get("/", response_model=List[BloodRequestResponse])
async def list_requests(service: FirestoreService = Depends(get_service)):
    return await service.list_all_requests()

@router.get("/hospital/{hospital_id}", response_model=List[BloodRequestResponse])
async def list_hospital_requests(hospital_id: str, service: FirestoreService = Depends(get_service)):
    return await service.list_hospital_requests(hospital_id)

@router.patch("/{request_id}/status")
async def update_status(request_id: str, status: str, admin_message: Optional[str] = None, service: FirestoreService = Depends(get_service)):
    await service.update_request_status(request_id, status, admin_message)
    return {"message": f"Request status updated to {status}"}
