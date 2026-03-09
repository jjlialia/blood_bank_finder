from fastapi import APIRouter, Depends, HTTPException
from typing import List, Optional
from ..models import HospitalCreate, HospitalResponse
from ..services.firestore_service import FirestoreService
from ..config import get_db

router = APIRouter(prefix="/hospitals", tags=["hospitals"])

def get_service(db=Depends(get_db)):
    return FirestoreService(db)

@router.post("/", response_model=HospitalResponse)
async def add_hospital(hospital: HospitalCreate, service: FirestoreService = Depends(get_service)):
    doc_id = await service.add_hospital(hospital.dict())
    return {**hospital.dict(), "id": doc_id}

@router.delete("/{hospital_id}")
async def delete_hospital(hospital_id: str, service: FirestoreService = Depends(get_service)):
    await service.delete_hospital(hospital_id)
    return {"message": "Hospital deleted"}

@router.put("/{hospital_id}", response_model=HospitalResponse)
async def update_hospital(hospital_id: str, hospital: HospitalCreate, service: FirestoreService = Depends(get_service)):
    # Need to update service to handle this
    await service.update_hospital(hospital_id, hospital.dict())
    return {**hospital.dict(), "id": hospital_id}

@router.get("/", response_model=List[HospitalResponse])
async def list_hospitals(
    is_active: bool = True,
    island_group: Optional[str] = None,
    city: Optional[str] = None,
    barangay: Optional[str] = None,
    service: FirestoreService = Depends(get_service)
):
    return await service.list_hospitals(is_active, island_group, city, barangay)
