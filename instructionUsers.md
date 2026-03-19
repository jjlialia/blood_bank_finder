# Blood Bank Finder: User Authentication Lifecycle

This guide explains the step-by-step operations for **Registering (SignUp)**, **Logging In**, and **Signing Out** as a user, including the file locations and the code that handles each step.

---

## 1. Registering (SignUp Operation)

This process creates a new account in the system and saves the user's detailed profile.

### Step 1: User fills the registration form
**File:** [lib/features/auth/screens/signup_screen.dart](file:///c:/Users/The%20Chosen%20One/OneDrive/Documents/blood%20bank%20finder/lib/features/auth/screens/signup_screen.dart)
The user enters their name, email, password, blood group, and location. When they click **"Sign Up"**, the following happens:
```dart
void _signup() async {
  if (_formKey.currentState!.validate()) {
    _formKey.currentState!.save();
    // STEP: Passes the collected data to the AuthProvider
    final error = await auth.signup(_formData, _formData['password']);
  }
}
```

### Step 2: Creating the Authentication Account (Firebase)
**File:** [lib/core/providers/auth_provider.dart](file:///c:/Users/The%20Chosen%20One/OneDrive/Documents/blood%20bank%20finder/lib/core/providers/auth_provider.dart)
The app calls `FirebaseAuth` to create the email/password account.
```dart
UserCredential credential = await _auth.createUserWithEmailAndPassword(
  email: data['email'],
  password: password,
);
```

### Step 3: Saving Profile to Backend
**File:** [lib/core/services/api_service.dart](file:///c:/Users/The%20Chosen%20One/OneDrive/Documents/blood%20bank%20finder/lib/core/services/api_service.dart)
Immediately after the account is created, the app sends the profile details to the **FastAPI** backend:
```dart
Future<void> saveUser(UserModel user) async {
  final response = await http.post(
    Uri.parse('$baseUrl/users/'), // Sends to the backend "Brain"
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode(user.toJson()),
  );
}
```

### Step 4: Storing in Firestore (Database)
**File (Backend):** [backend/app/services/firestore_service.py](file:///c:/Users/The%20Chosen%20One/OneDrive/Documents/blood%20bank%20finder/backend/app/services/firestore_service.py)
The FastAPI server receives the data and saves it as a document in the `users` collection.
```python
async def create_or_update_user(self, user_id: str, user_data: dict):
    # Saves the profile permanently in the cloud
    self.db.collection('users').document(user_id).set(user_data)
```

---

## 2. Logging In Operation

This process identifies who you are and prepares your personalized dashboard.

### Step 1: User enters credentials
**File:** [lib/features/auth/screens/login_screen.dart](file:///c:/Users/The%20Chosen%20One/OneDrive/Documents/blood%20bank%20finder/lib/features/auth/screens/login_screen.dart)
The user provides their email and password and clicks **"Login"**.

### Step 2: Verification and Profile Sync
**File:** [lib/core/providers/auth_provider.dart](file:///c:/Users/The%20Chosen%20One/OneDrive/Documents/blood%20bank%20finder/lib/core/providers/auth_provider.dart)
The app checks your password and then fetches your profile from the database to see your role (e.g., if you are an Admin or a regular User).
```dart
// 1. Check password
UserCredential credential = await _auth.signInWithEmailAndPassword(email, password);
// 2. Fetch profile details
final userData = await _db.getUser(credential.user!.uid);
// 3. Security check: Is this user banned?
if (userData.isBanned) { await logout(); ... }
```

### Step 3: Entering the Dashboard
**File:** [lib/features/auth/screens/splash_screen.dart](file:///c:/Users/The%20Chosen%20One/OneDrive/Documents/blood%20bank%20finder/lib/features/auth/screens/splash_screen.dart)
The app redirects you based on your **Role**:
*   **Role User:** Goes to `UserHomeScreen`
*   **Role Admin:** Goes to `HospitalAdminDashboard`

---

## 3. Signing Out (Logout Operation)

This process ends your current session safely.

### Step 1: User clicks Logout
**File:** [lib/features/user/widgets/user_drawer.dart](file:///c:/Users/The%20Chosen%20One/OneDrive/Documents/blood%20bank%20finder/lib/features/user/widgets/user_drawer.dart) (Also in Admin drawers)
The user opens the side menu and taps the RED logout button.

### Step 2: Clearing the Session
**File:** [lib/core/providers/auth_provider.dart](file:///c:/Users/The%20Chosen%20One/OneDrive/Documents/blood%20bank%20finder/lib/core/providers/auth_provider.dart)
The app tells Firebase to sign out and clears all the user's data from the phone's memory.
```dart
Future<void> logout() async {
  await _auth.signOut(); // Tells Firebase to end the session
  _stopUserListener();   // Stops listening to database updates
  _user = null;          // Forgets the user profile in the app
  notifyListeners();     // Redraws the screen (back to Login)
}
```

### Step 3: Redirection
**File:** [lib/features/user/widgets/user_drawer.dart](file:///c:/Users/The%20Chosen%20One/OneDrive/Documents/blood%20bank%20finder/lib/features/user/widgets/user_drawer.dart)
The app removes all previous screens and shows the `LoginScreen`.
```dart
Navigator.pushAndRemoveUntil(
  context,
  MaterialPageRoute(builder: (context) => const LoginScreen()),
  (route) => false, // This makes sure the user can't "Go Back" without logging in again
);
```

---

### Summary of Files Involved:
1.  **UI Level**: `signup_screen.dart`, `login_screen.dart`, `user_drawer.dart`
2.  **Logic Level**: `auth_provider.dart`, `api_service.dart`
3.  **Backend Level**: `users.py` (Router), `firestore_service.py` (Database Engine)
