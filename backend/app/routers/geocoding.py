from fastapi import APIRouter, HTTPException, Query
import urllib.request
import urllib.parse
import json
from ..config import get_google_maps_key

router = APIRouter(prefix="/geocoding", tags=["geocoding"])

@router.get("/")
async def get_coordinates(address: str = Query(..., description="The address to geocode")):
    api_key = get_google_maps_key()
    encoded_address = urllib.parse.quote(address)
    url = f"https://maps.googleapis.com/maps/api/geocode/json?address={encoded_address}&key={api_key}"
    
    try:
        with urllib.request.urlopen(url) as response:
            data = json.loads(response.read().decode())
            
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
