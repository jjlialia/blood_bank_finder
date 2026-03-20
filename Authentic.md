# AUTHENTIC - Comprehensive Authentication Flows

This document provides a step-by-step mapping of the Login, Signup, and Logout procedures in the Blood Bank Finder system, tracing data from the user interface down to the backend database.

---

## 1. SIGNUP PROCEDURE (Registering a New User)

**STEP 1: User Submission**
- **File**: `lib/features/auth/screens/signup_screen.dart`
- **Code**: `void _signup() async { ... final error = await auth.signup(_formData, _formData['password']); }`
- **Action**: The user completes the registration form. Clicking "Sign Up" triggers `_signup()`, which aggregates all inputs (Personal, Location, Account) into a `_formData` map and passes it to the `AuthProvider`.

**STEP 2: Account Creation Initiated**
- **File**: `lib/core/providers/auth_provider.dart`
- **Code**: `Future<String?> signup(Map<String, dynamic> data, String password) async { ... await _auth.createUserWithEmailAndPassword(...) }`
- **Action**: The `AuthProvider` uses Firebase Authentication to create the user account with the provided email and password.

**STEP 3: Profile Persistence Request**
- **File**: `lib/core/providers/auth_provider.dart`
- **Code**: `final newUser = UserModel(...); await _api.saveUser(newUser);`
- **Action**: Upon successful Auth creation, the provider constructs a `UserModel` and sends it to the `ApiService` to persist the additional profile data (role, blood group, location) in the system.

**STEP 4: API Bridge**
- **File**: `lib/core/services/api_service.dart`
- **Code**: `Future<void> saveUser(UserModel user) async { final response = await http.post(Uri.parse('$baseUrl/users/'), ... body: jsonEncode(user.toJson())); }`
- **Action**: The `ApiService` acts as the outbound bridge, sending a HTTP POST request to the FastAPI backend.

**STEP 5: Backend Routing**
- **File**: `backend/app/routers/users.py`
- **Code**: `@router.post("/") async def create_user(user: UserCreate, service: FirestoreService = Depends(get_service)): return await service.create_or_update_user(...)`
- **Action**: The FastAPI router receives the JSON data, validates it using the `UserCreate` model, and passes it to the `FirestoreService`.

**STEP 6: Database Persistence**
- **File**: `backend/app/services/firestore_service.py`
- **Code**: `async def create_or_update_user(self, user_id: str, user_data: dict): self.db.collection('users').document(user_id).set(user_data)`
- **Action**: The service layer performs the final write to the Google Cloud Firestore `users` collection.

---

## 2. LOGIN PROCEDURE (Accessing an Account)

**STEP 1: Credential Submission**
- **File**: `lib/features/auth/screens/login_screen.dart`
- **Code**: `void _login() async { ... final error = await auth.login(_emailController.text, _passwordController.text); }`
- **Action**: The user enters their email and password. Clicking "Login" triggers `_login()`, which passes the credentials to the `AuthProvider`.

**STEP 2: Authentication Check & Bypass**
- **File**: `lib/core/providers/auth_provider.dart`
- **Code**: `Future<String?> login(String email, String password) async { ... if (email == 'admin@gmail.com' && password == '1234') { ... } ... await _auth.signInWithEmailAndPassword(...) }`
- **Action**: The provider first checks for the hardcoded admin bypass for development. If not found, it attempts to sign in via Firebase Auth.

**STEP 3: Profile Retrieval**
- **File**: `lib/core/providers/auth_provider.dart`
- **Code**: `final userData = await _db.getUser(credential.user!.uid);`
- **Action**: After Firebase validates the credentials, the provider fetches the user's full profile (including their role and ban status) from Firestore via the `DatabaseService`.

**STEP 4: Firestore Read**
- **File**: `lib/core/services/database_service.dart`
- **Code**: `Future<UserModel?> getUser(String uid) async { final doc = await _db.collection('users').doc(uid).get(); ... }`
- **Action**: The `DatabaseService` performs a direct read from the Firestore `users` collection.

**STEP 5: Security & Session Management**
- **File**: `lib/core/providers/auth_provider.dart`
- **Code**: `if (userData.isBanned) { await logout(); ... } _user = userData; _startUserListener(userData.uid);`
- **Action**: The provider checks if the user is banned. If safe, it stores the `UserModel` in memory and starts a persistent real-time listener for profile updates.

**STEP 6: Dynamic Navigation**
- **File**: `lib/features/auth/screens/login_screen.dart`
- **Code**: `switch (auth.user?.role) { case 'superadmin': nextScreen = SuperAdminDashboard(); ... } Navigator.pushReplacement(...)`
- **Action**: The UI evaluates the `role` property of the `UserModel` and redirects the user to their specific dashboard.

---

## 3. LOGOUT PROCEDURE (Ending a Session)

**STEP 1: Trigger**
- Typically triggered from the Sidebar/Drawer in various dashboard screens calling `auth.logout()`.

**STEP 2: Session Termination**
- **File**: `lib/core/providers/auth_provider.dart`
- **Code**: `Future<void> logout() async { await _auth.signOut(); _stopUserListener(); }`
- **Action**: The `AuthProvider` tells Firebase Auth to invalidate the session and immediately stops the real-time Firestore listener.

**STEP 3: Memory Cleanup**
- **File**: `lib/core/providers/auth_provider.dart`
- **Code**: `void _stopUserListener() { _userSubscription?.cancel(); _user = null; notifyListeners(); }`
- **Action**: All user-related data is wiped from the app's reactive state, causing the UI to automatically revert to the `LoginScreen` via the `main.dart` auth wrapper.
