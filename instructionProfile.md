# Blood Bank Finder: User Profile Lifecycle

This guide explains the step-by-step procedures for viewing and updating your user profile, including the code and file locations for each step.

---

## 1. Viewing Your Profile (Read Mode)

### Step 1: Loading data from local state
**File:** [lib/features/user/screens/profile_screen.dart](file:///c:/Users/The%20Chosen%20One/OneDrive/Documents/blood%20bank%20finder/lib/features/user/screens/profile_screen.dart)
The app retrieves the logged-in user's information from the `AuthProvider`:
```dart
final auth = context.watch<AuthProvider>();
final user = auth.user;
```

### Step 2: Displaying details
**File:** [lib/features/user/screens/profile_screen.dart](file:///c:/Users/The%20Chosen%20One/OneDrive/Documents/blood%20bank%20finder/lib/features/user/screens/profile_screen.dart)
Each piece of information (Blood Type, Phone, City, etc.) is rendered using a helper widget:
```dart
_buildProfileItem(Icons.bloodtype, 'Blood Group', user.bloodGroup),
```

---

## 2. Updating Your Profile (Edit Mode)

### Step 3: Toggling the Form
**File:** [lib/features/user/screens/profile_screen.dart](file:///c:/Users/The%20Chosen%20One/OneDrive/Documents/blood%20bank%20finder/lib/features/user/screens/profile_screen.dart)
When the user clicks the "Edit" icon, the app switches `_isEditing` to `true`, replacing text cards with editable `TextFormField`s:
```dart
setState(() => _isEditing = !_isEditing);
```

### Step 4: Initializing the Inputs
**File:** [lib/features/user/screens/profile_screen.dart](file:///c:/Users/The%20Chosen%20One/OneDrive/Documents/blood%20bank%20finder/lib/features/user/screens/profile_screen.dart)
The current user data is copied into the text controllers to allow for modifications:
```dart
_firstNameCtrl.text = user.firstName;
_lastNameCtrl.text = user.lastName;
```

---

## 3. Saving: Persisting the Changes

### Step 5: Repackaging the Data
**File:** [lib/features/user/screens/profile_screen.dart](file:///c:/Users/The%20Chosen%20One/OneDrive/Documents/blood%20bank%20finder/lib/features/user/screens/profile_screen.dart)
When clicking "Save Changes", the app creates a new `UserModel` with the updated text from the inputs:
```dart
final updatedUser = UserModel(
  uid: currentUser.uid,
  firstName: _firstNameCtrl.text.trim(),
  // ... copies other fields like email and role which are NOT editable
);
```

### Step 6: Triggering the API Flow
**File:** [lib/core/services/api_service.dart](file:///c:/Users/The%20Chosen%20One/OneDrive/Documents/blood%20bank%20finder/lib/core/services/api_service.dart)
The app calls the `saveUser` method to sync with the backend:
```dart
await _api.saveUser(updatedUser);
```

### Step 7: Backend Storage
**File (Backend):** [backend/app/services/firestore_service.py](file:///c:/Users/The%20Chosen%20One/OneDrive/Documents/blood%20bank%20finder/backend/app/services/firestore_service.py)
The FastAPI backend receives the updated JSON and overwrites the document in Firestore:
```python
async def create_or_update_user(self, user_id: str, user_data: dict):
    # Uses .set() to ensure the existing profile is updated in the database
    self.db.collection('users').document(user_id).set(user_data)
```

---

### Summary of Files Involved:
1.  **UI Level**: `profile_screen.dart`
2.  **Logic Level**: `auth_provider.dart`, `api_service.dart`
3.  **Backend Level**: `users.py` (Router), `firestore_service.py` (Database Engine)
