
from fastapi import APIRouter, Depends, HTTPException
from typing import List
from app.models import InventoryCreate, InventoryResponse
from app.services.firestore_service import FirestoreService
from app.config import get_db
from datetime import datetime

router = APIRouter(prefix="/hospitals", tags=["inventory"])

def get_service(db=Depends(get_db)):
    """Injects the database service."""
    return FirestoreService(db)

@router.post("/{hospital_id}", response_model=InventoryResponse)
async def add_inventory(hospital_id: str, inventory: InventoryCreate, service: FirestoreService = Depends(get_service)):
    """
    r: (Legacy) Initial Setup. s: `FirestoreService.update_inventory`.
    """
    await service.update_inventory(hospital_id, inventory.blood_type, inventory.units)
    return {**inventory.dict(), "hospital_id": hospital_id}

@router.put("/{hospital_id}/inventory/{blood_type}", response_model=InventoryResponse)
async def update_inventory(hospital_id: str, blood_type: str, units: float, 
                           service: FirestoreService = Depends(get_service)):
    """
    r: InventoryManagementScreen. s: `FirestoreService.update_inventory`.
    """
    await service.update_inventory(hospital_id, blood_type, units)
    return {"blood_type": blood_type, "units": units, "last_updated": datetime.now()}

@router.get("/{hospital_id}", response_model=List[InventoryResponse])
async def get_inventory(hospital_id: str, service: FirestoreService = Depends(get_service)):
    """
    r: InventoryManagementScreen. s: `FirestoreService.get_inventory`.
    """
    return await service.get_inventory(hospital_id)































"""
FILE: inventory.py (FastAPI Router)

DESCRIPTION:
This router manages the stock levels of different blood types within 
individual hospitals. It is primarily used by Hospital Admins.

DATA FLOW OVERVIEW:
1. RECEIVES DATA FROM: 
   - 'ManageInventoryScreen' in the Flutter app.
2. PROCESSING:
   - Hospital Association: All inventory items are stored as sub-collections 
     under a specific hospital document in Firestore.
   - Transactional Safety: Handled at the service layer to prevent math errors.
3. SENDS DATA TO:
   - 'FirestoreService': To update the 'inventory' sub-collection of a hospital.
4. OUTPUTS:
   - 'InventoryResponse': Current units and last updated timestamp for a blood type.
"""
