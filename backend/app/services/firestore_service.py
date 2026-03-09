from google.cloud import firestore
from datetime import datetime
from typing import List, Optional
from ..models import UserCreate, UserResponse, HospitalCreate, HospitalResponse, BloodRequestCreate, BloodRequestResponse, InventoryCreate, InventoryResponse, NotificationCreate, NotificationResponse

class FirestoreService:
    def __init__(self, db: firestore.Client):
        self.db = db

    # --- Users ---
    async def create_or_update_user(self, user_id: str, user_data: dict):
        self.db.collection('users').document(user_id).set(user_data)
        return user_data

    async def update_user(self, user_id: str, user_data: dict):
        self.db.collection('users').document(user_id).update(user_data)

    async def get_user(self, user_id: str) -> Optional[dict]:
        doc = self.db.collection('users').document(user_id).get()
        if doc.exists:
            return doc.to_dict()
        return None

    async def get_user_by_email(self, email: str) -> Optional[dict]:
        docs = self.db.collection('users').where('email', '==', email).limit(1).stream()
        for doc in docs:
            data = doc.to_dict()
            data['uid'] = doc.id
            return data
        return None

    async def list_all_users(self) -> List[dict]:
        docs = self.db.collection('users').stream()
        return [doc.to_dict() for doc in docs]

    async def toggle_user_ban(self, user_id: str, is_banned: bool):
        self.db.collection('users').document(user_id).update({'isBanned': is_banned})

    async def update_user_role(self, user_id: str, role: str, hospital_id: Optional[str]):
        self.db.collection('users').document(user_id).update({
            'role': role,
            'hospitalId': hospital_id
        })

    # --- Hospitals ---
    async def add_hospital(self, hospital_data: dict) -> str:
        _, doc_ref = self.db.collection('hospitals').add(hospital_data)
        return doc_ref.id

    async def update_hospital(self, hospital_id: str, hospital_data: dict):
        self.db.collection('hospitals').document(hospital_id).set(hospital_data, merge=True)

    async def delete_hospital(self, hospital_id: str):
        self.db.collection('hospitals').document(hospital_id).delete()

    async def list_hospitals(self, is_active: bool = True, island_group: str = None, city: str = None, barangay: str = None) -> List[dict]:
        query = self.db.collection('hospitals')
        if is_active is not None:
            query = query.where('isActive', '==', is_active)
        if island_group:
            query = query.where('islandGroup', '==', island_group)
        if city:
            query = query.where('city', '==', city)
        if barangay:
            query = query.where('barangay', '==', barangay)
        
        docs = query.stream()
        hospitals = []
        for doc in docs:
            data = doc.to_dict()
            data['id'] = doc.id
            hospitals.append(data)
        return hospitals

    # --- Blood Requests ---
    async def create_blood_request(self, request_data: dict) -> str:
        _, doc_ref = self.db.collection('blood_requests').add(request_data)
        return doc_ref.id

    async def list_all_requests(self) -> List[dict]:
        docs = self.db.collection('blood_requests').order_by('createdAt', direction=firestore.Query.DESCENDING).stream()
        requests = []
        for doc in docs:
            data = doc.to_dict()
            data['id'] = doc.id
            requests.append(data)
        return requests

    async def list_hospital_requests(self, hospital_id: str) -> List[dict]:
        docs = self.db.collection('blood_requests').where('hospitalId', '==', hospital_id).order_by('createdAt', direction=firestore.Query.DESCENDING).stream()
        requests = []
        for doc in docs:
            data = doc.to_dict()
            data['id'] = doc.id
            requests.append(data)
        return requests

    async def update_request_status(self, request_id: str, status: str):
        doc_ref = self.db.collection('blood_requests').document(request_id)
        doc_ref.update({'status': status})
        
        # Trigger notification logic
        doc = doc_ref.get()
        if doc.exists:
            request_data = doc.to_dict()
            if status in ['approved', 'rejected']:
                title = "Request Approved!" if status == 'approved' else "Request Rejected"
                message = f"Your {request_data['type']} for {request_data['bloodType']} at {request_data['hospitalName']} has been {status}."
                
                notification_data = {
                    'userId': request_data['userId'],
                    'message': message,
                    'isRead': False,
                    'createdAt': datetime.now(),
                    'type': f"request_{status}",
                    'title': title,
                    'body': message
                }
                self.db.collection('notifications').add(notification_data)

    # --- Inventory ---
    async def update_inventory(self, hospital_id: str, blood_type: str, units: float):
        self.db.collection('hospitals').document(hospital_id).collection('inventory').document(blood_type).set({
            'blood_type': blood_type,
            'units': units,
            'last_updated': datetime.now()
        })

    async def get_inventory(self, hospital_id: str) -> List[dict]:
        docs = self.db.collection('hospitals').document(hospital_id).collection('inventory').stream()
        return [doc.to_dict() for doc in docs]

    # --- Notifications ---
    async def create_notification(self, notification_data: dict) -> str:
        _, doc_ref = self.db.collection('notifications').add(notification_data)
        return doc_ref.id

    async def list_user_notifications(self, user_id: str) -> List[dict]:
        docs = self.db.collection('notifications').where('userId', '==', user_id).order_by('createdAt', direction=firestore.Query.DESCENDING).stream()
        notifications = []
        for doc in docs:
            data = doc.to_dict()
            data['id'] = doc.id
            notifications.append(data)
        return notifications

    # --- Locations (Dynamic) ---
    async def get_island_groups(self) -> List[str]:
        # This could be from a collection 'locations'
        return ["Luzon", "Visayas", "Mindanao"]

    async def get_cities(self, island_group: str) -> List[str]:
        # In a real app, fetch from PSGC data stored in Firestore
        docs = self.db.collection('cities').where('islandGroup', '==', island_group).stream()
        return [doc.id for doc in docs]

    async def get_barangays(self, city: str) -> List[str]:
        # Fetch from PSGC data
        docs = self.db.collection('barangays').where('city', '==', city).stream()
        return [doc.id for doc in docs]
