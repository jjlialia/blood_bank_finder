# Blood Bank Finder: Notification Lifecycle

This guide explains the step-by-step procedure for how system alerts are generated, received, and read by users.

---

## 1. Trigger: Admin Action (Backend)

Notifications are automatically generated in the backend when a blood request is updated.

### Step 1: Admin updates request status
**File (Backend):** [backend/app/services/firestore_service.py](file:///c:/Users/The%20Chosen%20One/OneDrive/Documents/blood%20bank%20finder/backend/app/services/firestore_service.py)
When a Hospital Admin clicks "Approve", "Reject", or "On Progress", the following logic runs:
```python
async def update_request_status(self, request_id: str, status: str, admin_message: Optional[str] = None):
    # 1. Update the status in the 'blood_requests' collection
    doc_ref.update({'status': status})
    
    # 2. Automatically build a 'Notification' object
    notification_data = {
        'userId': request_data['userId'],
        'title': "Request Approved!",
        'body': "Your request for O+ at City Hospital has been approved.",
        'isRead': False,
        'createdAt': datetime.now(),
    }
    
    # 3. Add to the 'notifications' collection in Firestore
    self.db.collection('notifications').add(notification_data)
```

---

## 2. Delivery: Real-time Sync (App)

### Step 2: Streaming to the UI
**File:** [lib/features/user/screens/notifications_screen.dart](file:///c:/Users/The%20Chosen%20One/OneDrive/Documents/blood%20bank%20finder/lib/features/user/screens/notifications_screen.dart)
The app listens specifically for notifications belonging to the logged-in user:
```dart
stream: FirebaseFirestore.instance
    .collection('notifications')
    .where('userId', isEqualTo: userId)
    .orderBy('createdAt', descending: true)
    .snapshots(),
```

---

## 3. Interaction: Reading the Alert

### Step 3: User taps the notification
**File:** [lib/features/user/screens/notifications_screen.dart](file:///c:/Users/The%20Chosen%20One/OneDrive/Documents/blood%20bank%20finder/lib/features/user/screens/notifications_screen.dart)
When the user taps an item in the list, the app performs two actions:

1.  **Mark as Read**: Updates the database so the item no longer looks "new":
    ```dart
    FirebaseFirestore.instance
        .collection('notifications')
        .doc(docId)
        .update({'isRead': true});
    ```

2.  **Show Details**: Opens a bottom sheet with the full message:
    ```dart
    _showNotificationDetails(context, data); // Displays title, date, and admin message
    ```

---

### Summary of Files Involved:
1.  **Backend Level**: `firestore_service.py` (The Trigger), `requests.py` (Router)
2.  **Database Level**: `notifications` collection (Firestore)
3.  **UI Level**: `notifications_screen.dart`
