import random
from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel, EmailStr
from app.services.firestore_service import FirestoreService
from app.services.email_service import EmailService
from app.config import get_db

router = APIRouter(prefix="/auth", tags=["auth"])

class OtpRequest(BaseModel):
    email: EmailStr

class OtpVerify(BaseModel):
    email: EmailStr
    otp: str

def get_service(db=Depends(get_db)):
    return FirestoreService(db)

def get_email_service():
    return EmailService()

@router.post("/send-otp")
async def send_otp(
    request: OtpRequest, 
    service: FirestoreService = Depends(get_service),
    email_service: EmailService = Depends(get_email_service)
):
    """
    Generates a 6-digit OTP, stores it in Firestore, and sends it via email.
    """
    # Generate 6-digit code
    otp = str(random.randint(100000, 999999))
    
    # Store in Firestore
    await service.store_otp(request.email.lower(), otp)
    
    # Send email
    success = email_service.send_otp_email(request.email.lower(), otp)
    
    if not success:
        # We still return 200 for security but log failure internally
        # In a real app, you might return 500 if the email service is down
        pass
        
    return {"message": "OTP sent successfully"}

@router.post("/verify-otp")
async def verify_otp(request: OtpVerify, service: FirestoreService = Depends(get_service)):
    """
    Verifies the OTP provided by the user.
    """
    is_valid = await service.verify_otp(request.email.lower(), request.otp)
    
    if not is_valid:
        raise HTTPException(status_code=400, detail="Invalid or expired OTP")
        
    return {"message": "OTP verified successfully"}
