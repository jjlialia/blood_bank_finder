from google.cloud import firestore
from datetime import datetime
from typing import List, Optional
from app.models import (
    UserCreate, UserResponse, HospitalCreate, HospitalResponse, 
    BloodRequestCreate, BloodRequestResponse, InventoryCreate, 
    InventoryResponse, NotificationCreate, NotificationResponse
)

class FirestoreService:
    def __init__(self, db: firestore.Client):
        self.db = db

    # --- USERS SECTION ---
    # Handled by routers/users.py

    async def create_or_update_user(self, user_id: str, user_data: dict):
        """
        r:users.py s:firestore
        """
        doc_ref = self.db.collection('users').document(user_id)
        doc = doc_ref.get()
        
        if doc.exists:
            existing_data = doc.to_dict()
            user_data['role'] = existing_data.get('role', 'user')
            user_data['isBanned'] = existing_data.get('isBanned', False)
            user_data['hospitalId'] = existing_data.get('hospitalId')
            
        doc_ref.set(user_data)
        return user_data

    async def get_user(self, user_id: str) -> Optional[dict]:
        """Fetches a single user. DATA DESTINATION: AuthProvider in Flutter."""
        doc = self.db.collection('users').document(user_id).get()
        if doc.exists:
            return doc.to_dict()
        return None

    async def list_all_users(self) -> List[dict]:
        """Super Admin only: Lists everyone in the system."""
        docs = self.db.collection('users').stream()
        return [doc.to_dict() for doc in docs]

    async def toggle_user_ban(self, user_id: str, is_banned: bool):
        """Security logic for Super Admins to restrict access."""
        try:
            self.db.collection('users').document(user_id).update({'isBanned': is_banned})
        except Exception as e:
            print(f"Error toggling user ban: {e}")
            raise

    async def update_user_role(self, user_id: str, role: str, hospital_id: Optional[str]):
        """Promotes a user to Hospital Admin and links them to a specific site."""
        self.db.collection('users').document(user_id).update({
            'role': role,
            'hospitalId': hospital_id
        })

    # --- HOSPITALS SECTION ---
    # Handled by routers/hospitals.py

    async def add_hospital(self, hospital_data: dict) -> str:
        """Registers a new site. r: ManageHospitalsScreen."""
        _, doc_ref = self.db.collection('hospitals').add(hospital_data)
        return doc_ref.id

    async def delete_hospital(self, hospital_id: str):
        """Permanently removes a hospital documented site."""
        self.db.collection('hospitals').document(hospital_id).delete()

    async def update_hospital(self, hospital_id: str, hospital_data: dict):
        """Updates metadata (contact, address)."""
        self.db.collection('hospitals').document(hospital_id).update(hospital_data)

    async def list_hospitals(self, is_active: Optional[bool] = True, island_group: Optional[str] = None, 
                             region: Optional[str] = None, city: Optional[str] = None, barangay: Optional[str] = None) -> List[dict]:
        """
        Advanced Querying: Filters hospitals based on geographical hierarchies.
        DATA DESTINATION: FindBloodBankScreen (GUI).
        """
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

    # --- BLOOD REQUESTS SECTION ---
    # Handled by routers/requests.py

    async def create_blood_request(self, request_data: dict) -> str:
        """new Request or Donation.r DonateBloodScreen / RequestBloodScreen."""
        _, doc_ref = self.db.collection('blood_requests').add(request_data)
        return doc_ref.id

    async def list_all_requests(self) -> List[dict]:
        """Super Admin view of all transactions globally."""
        docs = self.db.collection('blood_requests').order_by('createdAt', direction=firestore.Query.DESCENDING).stream()
        requests = []
        for doc in docs:
            data = doc.to_dict()
            data['id'] = doc.id
            requests.append(data)
        return requests

    async def list_hospital_requests(self, hospital_id: str) -> List[dict]:
        """Hospital Admin view of transactions specifically for their site."""
        docs = self.db.collection('blood_requests').where('hospitalId', '==', hospital_id).order_by('createdAt', direction=firestore.Query.DESCENDING).stream()
        requests = []
        for doc in docs:
            data = doc.to_dict()
            data['id'] = doc.id
            requests.append(data)
        return requests

    async def update_request_status(self, request_id: str, status: str, admin_message: Optional[str] = None):
        """
        Admin selects 'approved', 'rejected', etc.
        triggers automatically builds a 'Notification' object.
        Creates a new record in the 'notifications' collection for the user.
        """
        doc_ref = self.db.collection('blood_requests').document(request_id)
        update_data = {'status': status}
        if admin_message:
            update_data['adminMessage'] = admin_message
        doc_ref.update(update_data)
        
        # STEP: Automatic Notification Logic
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
                # Append the custom admin message if provided.
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
                # DATA DESTINATION: 'notifications' collection in Firestore.
                self.db.collection('notifications').add(notification_data)

    # --- INVENTORY SECTION ---
    # Handled by routers/inventory.py

    async def update_inventory(self, hospital_id: str, blood_type: str, units: float):
        try:
            doc_ref = self.db.collection('hospitals').document(hospital_id).collection('inventory').document(blood_type)
            
            @firestore.transactional
            def update_in_transaction(transaction):
                transaction.set(doc_ref, {
                    'blood_type': blood_type,
                    'units': units,
                    'last_updated': datetime.now()
                }, merge=True)

            transaction = self.db.transaction()
            update_in_transaction(transaction)
        except Exception as e:
            print(f"Error updating inventory: {e}")
            raise

    async def get_inventory(self, hospital_id: str) -> List[dict]:
        """Fetches all stock levels for a specific hospital site."""
        docs = self.db.collection('hospitals').document(hospital_id).collection('inventory').stream()
        return [doc.to_dict() for doc in docs]

    # --- NOTIFICATIONS SECTION ---
    # Handled by routers/notifications.py

    async def create_notification(self, notification_data: dict) -> str:
        """Generic endpoint to send an alert to a user."""
        _, doc_ref = self.db.collection('notifications').add(notification_data)
        return doc_ref.id

    async def list_user_notifications(self, user_id: str) -> List[dict]:
        """Fetches all unread/past alerts for a user account."""
        docs = self.db.collection('notifications').where('userId', '==', user_id).order_by('createdAt', direction=firestore.Query.DESCENDING).stream()
        notifications = []
        for doc in docs:
            data = doc.to_dict()
            data['id'] = doc.id
            notifications.append(data)
        return notifications
