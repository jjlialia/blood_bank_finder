"""
FILE: hospitals.py (FastAPI Router)

DESCRIPTION:
This router defines the 'Department of Hospitals' for the API. It exposes 
endpoints that the Flutter app calls to perform CRUD operations on hospital data.

DATA FLOW OVERVIEW:
1. RECEIVES DATA FROM: 
   - The Flutter 'ApiService' (HTTP POST/PUT/DELETE/GET).
2. PROCESSING:
   - Dependency Injection: Uses 'get_db' to ensure a live connection to Firestore.
   - Serialization: Automatically converts the incoming JSON into 'HospitalCreate' 
     Python objects for validation.
3. SENDS DATA TO:
   - 'FirestoreService': The internal layer that does the actual work of 
     talking to the Firestore database.
4. OUTPUTS/RESPONSES:
   - 'HospitalResponse': A sanitized JSON object returned to the Flutter app.
   - 200 OK / 404 (handled by service) / 500 etc.

ENDPOINTS:
- POST /hospitals/: Registers a new hospital.
- PUT /hospitals/{id}: Updates existing hospital details.
- DELETE /hospitals/{id}: Removes a hospital record.
- GET /hospitals/: Returns a filtered list of hospitals (by Island, Region, etc.).
"""

from fastapi import APIRouter, Depends, HTTPException
from typing import List, Optional
from ..models import HospitalCreate, HospitalResponse
from ..services.firestore_service import FirestoreService
from ..config import get_db

# STEP: Create the router with a prefix so all URLs start with /hospitals.
router = APIRouter(prefix="/hospitals", tags=["hospitals"])

# HELPER: Injects the database service into our route handlers.
def get_service(db=Depends(get_db)):
    return FirestoreService(db)

@router.post("/", response_model=HospitalResponse)
async def add_hospital(hospital: HospitalCreate, service: FirestoreService = Depends(get_service)):
    # DATA FLOW: Flutter (POST) -> This Handler -> FirestoreService -> FIRESTORE.
    doc_id = await service.add_hospital(hospital.dict())
    return {**hospital.dict(), "id": doc_id}

@router.put("/{hospital_id}", response_model=HospitalResponse)
async def update_hospital(hospital_id: str, hospital: HospitalCreate, service: FirestoreService = Depends(get_service)):
    # DATA FLOW: Flutter (PUT) -> This Handler -> Updates specific hospital document.
    await service.update_hospital(hospital_id, hospital.dict())
    return {**hospital.dict(), "id": hospital_id}

@router.delete("/{hospital_id}")
async def delete_hospital(hospital_id: str, service: FirestoreService = Depends(get_service)):
    # DATA FLOW: Admin selects Delete -> This Handler -> Removes document from Firestore.
    await service.delete_hospital(hospital_id)
    return {"message": "Hospital deleted successfully"}

@router.get("/", response_model=List[HospitalResponse])
async def list_hospitals(
    is_active: bool = True,
    island_group: Optional[str] = None,
    region: Optional[str] = None,
    city: Optional[str] = None,
    barangay: Optional[str] = None,
    service: FirestoreService = Depends(get_service)
):
    # DATA FLOW: User Filter (GUI) -> API Query Params -> Firestore Query -> List of Hospitals.
    return await service.list_hospitals(is_active, island_group, region, city, barangay)
