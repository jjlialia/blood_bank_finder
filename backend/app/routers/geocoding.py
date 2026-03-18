"""
FILE: geocoding.py (FastAPI Router)

DESCRIPTION:
This router acts as a bridge to the Google Maps Geocoding API. Since the 
Flutter Web app cannot easily call Google Maps directly without exposing keys, 
this backend route handles the conversion of text addresses into GPS coordinates.

DATA FLOW OVERVIEW:
1. RECEIVES DATA FROM: 
   - 'ManageHospitalsScreen' (Admin) or 'FindBloodBankScreen' (User).
   - INPUT: A string address (e.g., '123 Main St, Cebu City').
2. PROCESSING:
   - API Secret: Retrieves the 'GOOGLE_MAPS_API_KEY' from the environment.
   - HTTP Request: Calls Google's servers to translate the text.
   - Parsing: Extracts the 'lat' and 'lng' from Google's complex JSON response.
3. SENDS DATA TO:
   - Google Maps API (External).
4. OUTPUTS:
   - Simple JSON: {"latitude": X, "longitude": Y}.
"""

from fastapi import APIRouter, HTTPException, Query
import urllib.request
import urllib.parse
import json
from ..config import get_google_maps_key

router = APIRouter(prefix="/geocoding", tags=["geocoding"])

@router.get("/")
async def get_coordinates(address: str = Query(..., description="The address to geocode")):
    """
    USER INPUT: Admin clicks "Fetch Coordinates from Address".
    DATA FLOW: Flutter -> This Backend Handler -> Google Maps API -> Coordinates returned to Flutter.
    """
    api_key = get_google_maps_key()
    # Ensure the address is URL-safe (converts spaces to %20, etc.)
    encoded_address = urllib.parse.quote(address)
    url = f"https://maps.googleapis.com/maps/api/geocode/json?address={encoded_address}&key={api_key}"
    
    try:
        # STEP: Direct HTTP call to Google's servers.
        with urllib.request.urlopen(url) as response:
            data = json.loads(response.read().decode())
            
            # STEP: Validate Google's response status.
            if data["status"] == "OK":
                location = data["results"][0]["geometry"]["location"]
                return {
                    "latitude": location["lat"],
                    "longitude": location["lng"]
                }
            elif data["status"] == "ZERO_RESULTS":
                raise HTTPException(status_code=404, detail="No coordinates found for this address")
            else:
                raise HTTPException(status_code=400, detail=f"Google Maps API error: {data['status']}")
                
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
