from fastapi import APIRouter, Depends, HTTPException
from typing import List
from ..services.firestore_service import FirestoreService
from ..config import get_db
from google.cloud import firestore

router = APIRouter(prefix="/locations", tags=["locations"])

@router.get("/island-groups", response_model=List[str])
async def get_island_groups(db: firestore.Client = Depends(get_db)):
    service = FirestoreService(db)
    return await service.get_island_groups()

@router.get("/cities/{island_group}", response_model=List[str])
async def get_cities(island_group: str, db: firestore.Client = Depends(get_db)):
    service = FirestoreService(db)
    return await service.get_cities(island_group)

@router.get("/barangays/{city}", response_model=List[str])
async def get_barangays(city: str, db: firestore.Client = Depends(get_db)):
    service = FirestoreService(db)
    return await service.get_barangays(city)
