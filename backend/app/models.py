from pydantic import BaseModel, Field
from typing import Optional, List
from datetime import datetime

class UserBase(BaseModel):
    uid: str
    email: str
    role: str = "user"
    firstName: str
    lastName: str
    fatherName: str
    mobile: str
    gender: str
    bloodGroup: str
    islandGroup: str
    city: str
    barangay: str
    address: str
    hospitalId: Optional[str] = None
    isBanned: bool = False
    createdAt: datetime = Field(default_factory=datetime.now)

class UserCreate(UserBase):
    pass

class UserResponse(UserBase):
    pass

class HospitalBase(BaseModel):
    name: str
    email: str
    islandGroup: str
    city: str
    barangay: str
    address: str
    contactNumber: str
    latitude: float
    longitude: float
    availableBloodTypes: List[str]
    isActive: bool = True
    createdAt: datetime = Field(default_factory=datetime.now)

class HospitalCreate(HospitalBase):
    pass

class HospitalResponse(HospitalBase):
    id: str

class BloodRequestBase(BaseModel):
    userId: str
    userName: str
    type: str # 'Request' or 'Donate'
    bloodType: str
    status: str = "pending"
    hospitalId: str
    hospitalName: str
    contactNumber: str
    quantity: float
    createdAt: datetime = Field(default_factory=datetime.now)

class BloodRequestCreate(BloodRequestBase):
    pass

class BloodRequestResponse(BloodRequestBase):
    id: str

class InventoryBase(BaseModel):
    blood_type: str
    units: float
    last_updated: datetime = Field(default_factory=datetime.now)

class InventoryCreate(InventoryBase):
    pass

class InventoryResponse(InventoryBase):
    pass

class NotificationBase(BaseModel):
    userId: str
    message: str
    isRead: bool = False
    createdAt: datetime = Field(default_factory=datetime.now)
    type: Optional[str] = None
    title: Optional[str] = None
    body: Optional[str] = None

class NotificationCreate(NotificationBase):
    pass

class NotificationResponse(NotificationBase):
    id: str
