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

    async def get_user(self, user_id: str) -> Optional[dict]:
        doc = self.db.collection('users').document(user_id).get()
        if doc.exists:
            return doc.to_dict()
        return None

    async def list_all_users(self) -> List[dict]:
        docs = self.db.collection('users').stream()
        return [doc.to_dict() for doc in docs]

    async def toggle_user_ban(self, user_id: str, is_banned: bool):
        try:
            self.db.collection('users').document(user_id).update({'isBanned': is_banned})
        except Exception as e:
            print(f"Error toggling user ban: {e}")
            raise

    async def update_user_role(self, user_id: str, role: str, hospital_id: Optional[str]):
        self.db.collection('users').document(user_id).update({
            'role': role,
            'hospitalId': hospital_id
        })

    # --- Hospitals ---
    async def add_hospital(self, hospital_data: dict) -> str:
        _, doc_ref = self.db.collection('hospitals').add(hospital_data)
        return doc_ref.id

    async def delete_hospital(self, hospital_id: str):
        self.db.collection('hospitals').document(hospital_id).delete()

    async def update_hospital(self, hospital_id: str, hospital_data: dict):
        self.db.collection('hospitals').document(hospital_id).update(hospital_data)

    async def list_hospitals(self, is_active: bool = True, island_group: str = None, region: str = None, city: str = None, barangay: str = None) -> List[dict]:
        try:
            query = self.db.collection('hospitals')
            if is_active is not None:
                query = query.where('isActive', '==', is_active)
            if island_group:
                query = query.where('islandGroup', '==', island_group)
            if region:
                query = query.where('region', '==', region)
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
        except Exception as e:
            print(f"Error listing hospitals: {e}")
            return []

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

    async def update_request_status(self, request_id: str, status: str, admin_message: Optional[str] = None):
        doc_ref = self.db.collection('blood_requests').document(request_id)
        update_data = {'status': status}
        if admin_message:
            update_data['adminMessage'] = admin_message
        doc_ref.update(update_data)
        
        # Trigger notification logic
        doc = doc_ref.get()
        if doc.exists:
            request_data = doc.to_dict()
            
            title = ""
            body = ""
            notif_type = ""

            if status == 'approved':
                title = "Request Approved!"
                body = f"Your {request_data['type']} for {request_data['bloodType']} at {request_data['hospitalName']} has been approved."
                notif_type = "request_approved"
            elif status == 'on progress':
                title = "Request is now On Progress"
                body = f"Your {request_data['type']} for {request_data['bloodType']} at {request_data['hospitalName']} is now being processed."
                notif_type = "request_on_progress"
            elif status == 'completed':
                title = "Request Completed"
                body = f"Your {request_data['type']} for {request_data['bloodType']} at {request_data['hospitalName']} is now complete. Thank you!"
                notif_type = "request_completed"
            elif status == 'rejected':
                title = "Request Rejected"
                body = f"Sorry, your {request_data['type']} for {request_data['bloodType']} at {request_data['hospitalName']} was rejected."
                notif_type = "request_rejected"

            if title:
                if admin_message:
                    body += f"\n\nMessage from hospital: \"{admin_message}\""
                
                notification_data = {
                    'userId': request_data['userId'],
                    'message': body,
                    'isRead': False,
                    'createdAt': datetime.now(),
                    'type': notif_type,
                    'title': title,
                    'body': body
                }
                self.db.collection('notifications').add(notification_data)

    # --- Inventory ---
    async def update_inventory(self, hospital_id: str, blood_type: str, units: float):
        try:
            doc_ref = self.db.collection('hospitals').document(hospital_id).collection('inventory').document(blood_type)
            
            @firestore.transactional
            def update_in_transaction(transaction, doc_ref, blood_type, units):
                # Using a transaction ensures that the inventory is updated safely,
                # avoiding race conditions.
                transaction.set(doc_ref, {
                    'blood_type': blood_type,
                    'units': units,
                    'last_updated': datetime.now()
                })

            transaction = self.db.transaction()
            update_in_transaction(transaction, doc_ref, blood_type, units)
        except Exception as e:
            print(f"Error updating inventory: {e}")
            raise

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
