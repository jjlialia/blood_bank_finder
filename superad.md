# Super Admin Operations Mapping

This document provides a comprehensive, step-by-step breakdown of all administrative operations available to the **Super Admin** role. It traces the data journey from the initial Flutter UI interaction to the final database persistence in Firestore.

---

## 1. Hospital Management Flow
**File:** `manage_hospitals_screen.dart`
**Goal:** Oversee the lifecycle of hospital facilities in the system.

### A. Registering a New Hospital
1.  **USER INPUT**: Admin opens the "Add Hospital" dialog and fills in the name, address, contact, and location dropdowns.
2.  **STEP 1 (Validation)**: The form validates all required fields.
3.  **STEP 2 (Geocoding - Optional)**: Admin clicks "Fetch Coordinates".
    - **FRONTEND**: `ApiService.getCoordinatesFromAddress`
    - **BACKEND**: `/geocoding/` (GET) -> Communicates with Google Maps API.
    - **RESULT**: GPS coordinates are returned and populated in the form.
4.  **STEP 3 (Submission)**: Admin clicks "Register".
    - **FRONTEND**: `ApiService.addHospital(hospitalModel)`
    - **BACKEND**: `/hospitals/` (POST) -> `hospitals.py` router.
5.  **STEP 4 (Persistence)**:
    - **SERVICE**: `FirestoreService.add_hospital`
    - **DATABASE**: Writes a new document to the **'hospitals'** collection.
6.  **FEEDBACK**: SnackBar shows "Hospital registered successfully" and the dialog closes.

### B. Updating an Existing Hospital
1.  **USER INPUT**: Admin clicks the "Edit" icon on a hospital card.
2.  **STEP 1 (Load)**: The dialog is pre-populated with existing data from the `HospitalModel`.
3.  **STEP 2 (Submit)**: Admin clicks "Save Changes".
    - **FRONTEND**: `ApiService.updateHospital(hospitalId, hospitalModel)`
    - **BACKEND**: `/hospitals/{hospital_id}` (PUT) -> `hospitals.py` router.
4.  **STEP 3 (Persistence)**:
    - **SERVICE**: `FirestoreService.update_hospital`
    - **DATABASE**: Overwrites the existing document in the **'hospitals'** collection.
5.  **FEEDBACK**: SnackBar shows "Hospital updated successfully".

### C. Deleting a Hospital
1.  **USER INPUT**: Admin clicks the "Delete" icon (if implemented/accessible) or toggles the "Active Status" switch.
2.  **STEP 1 (Submission)**:
    - **FRONTEND**: `ApiService.deleteHospital(hospitalId)`
    - **BACKEND**: `/hospitals/{hospital_id}` (DELETE) -> `hospitals.py` router.
3.  **STEP 2 (Persistence)**:
    - **SERVICE**: `FirestoreService.delete_hospital`
    - **DATABASE**: Removes the document from the **'hospitals'** collection.

---

## 2. User Administration Flow
**File:** `manage_users_screen.dart`
**Goal:** Moderate the user base and assign platform roles.

### A. Listing and Searching Users
1.  **DATA SOURCE**: `DatabaseService.streamAllUsers()`
2.  **FLOW**: 
    - **DATABASE**: Reads the entire **'users'** collection.
    - **FRONTEND**: Returns a `Stream<List<UserModel>>`.
3.  **PROCESSING**: The UI filters the list in real-time based on the text entered in the "Search by name or email..." field.
4.  **SECURITY**: Other 'superadmin' accounts are explicitly hidden from the list to prevent accidental modification.

### B. Banning/Unbanning a User
1.  **USER INPUT**: Admin toggles the "Ban" switch next to a user's name.
2.  **STEP 1 (Submission)**:
    - **FRONTEND**: `ApiService.toggleUserBan(uid, isBanned)`
    - **BACKEND**: `/users/{user_id}/ban` (PATCH) -> `users.py` router.
3.  **STEP 2 (Persistence)**:
    - **SERVICE**: `FirestoreService.toggle_user_ban`
    - **DATABASE**: Updates the `isBanned` field in the user's document.
4.  **RESULT**: The user is immediately blocked from logging in (checked during the `AuthProvider.login` flow).

### C. Promoting to Hospital Admin
1.  **USER INPUT**: Admin clicks the "Edit" (pencil) icon -> Dialog opens.
2.  **STEP 1 (Select Role)**: Admin selects "Hospital Admin" from the dropdown.
3.  **STEP 2 (Assign Hospital)**: Admin selects a facility from the "Assign Hospital" dropdown.
    - **DATA SOURCE**: `DatabaseService.streamHospitals()` populates this list.
4.  **STEP 3 (Submit)**: Admin clicks "Save".
    - **FRONTEND**: `ApiService.updateUserRole(uid, role, hospitalId)`
    - **BACKEND**: `/users/{user_id}/role` (PATCH) -> `users.py` router.
5.  **STEP 4 (Persistence)**:
    - **SERVICE**: `FirestoreService.update_user_role`
    - **DATABASE**: Updates the `role` and `hospitalId` fields in the user's document.

---

## 3. Global System Monitoring
**Goal:** Maintain a macro-level view of platform activity.

### A. Dashboard Metrics
1.  **UI**: `super_admin_dashboard.dart`
2.  **DATA JOURNEY**:
    - **Users Count**: Firestore -> `streamAllUsers` -> UI (`length`).
    - **Hospitals Count**: Firestore -> `streamHospitals` -> UI (`length`).
    - **Requests Monitoring**: Firestore -> `streamAllBloodRequests` -> Filters in UI for `status == 'pending'`.
    - **Donation Totals**: Firestore -> `streamAllBloodRequests` -> Filters in UI for `type == 'Donate'`.

### B. Global Requests Log
1.  **UI**: `global_log_screen.dart`
2.  **DATA SOURCE**: `DatabaseService.streamAllBloodRequests()`
3.  **FLOW**: Reads the entire **'blood_requests'** collection and displays it in a reverse-chronological list, allowing the Super Admin to see every transaction occurring across the platform regardless of the hospital site.

---
**END OF SUPER ADMIN MAPPING**
