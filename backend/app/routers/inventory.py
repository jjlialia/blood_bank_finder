from fastapi import APIRouter, Depends, HTTPException
from typing import List
from ..models import InventoryCreate, InventoryResponse
from ..services.firestore_service import FirestoreService
from ..config import get_db

router = APIRouter(prefix="/hospitals", tags=["inventory"])

def get_service(db=Depends(get_db)):
    return FirestoreService(db)

@router.put("/{hospital_id}/inventory/{blood_type}", response_model=InventoryResponse)
async def update_inventory(hospital_id: str, blood_type: str, units: float, service: FirestoreService = Depends(get_service)):
    await service.update_inventory(hospital_id, blood_type, units)
    return {"blood_type": blood_type, "units": units, "last_updated": None} # None will be replaced by actual data in response_model if needed

@router.get("/{hospital_id}/inventory/", response_model=List[InventoryResponse])
async def get_inventory(hospital_id: str, service: FirestoreService = Depends(get_service)):
    return await service.get_inventory(hospital_id)
