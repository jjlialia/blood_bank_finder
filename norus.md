# Normal User Operations Mapping

This document provides a comprehensive, step-by-step breakdown of all operations available to a standard **User** role. It traces the data journey from discovery and search to the submission of medical requests and donation pledges.

---

## 1. Discovery: Find Blood Bank Flow
**File:** `find_blood_bank_screen.dart`
**Goal:** Locate facilities and blood inventory using geographical filters.

### A. Hierarchical Location Filtering
1.  **USER INPUT**: User selects a location level (Island -> Region -> City -> Barangay).
2.  **STEP 1 (Data Fetch)**: 
    - **SERVICE**: `LocationService` (PSGC API).
    - **FLOW**: Based on the previous selection (e.g., "Luzon"), the next dropdown is populated with relevant options (e.g., "NCR", "CALABARZON").
3.  **STEP 2 (Map Synchronization)**: 
    - **FRONTEND**: `ApiService.getCoordinatesFromAddress("City, Region, Philippines")`
    - **BACKEND**: `/geocoding/` (GET) bridge to Google Maps.
    - **RESULT**: The map camera immediately flies to the selected area's coordinates.
4.  **STEP 3 (Hospital Refresh)**:
    - **DATABASE**: `DatabaseService.streamHospitals(filters)` reads Firestore reactively.
    - **GUI**: The Map markers and List cards update instantly to show hospitals in that specific area.

### B. Viewing Hospital Details
1.  **USER ACTION**: User taps a Hospital Card or Map Marker.
2.  **GUI**: A Modal Bottom Sheet opens, populated with data from the `HospitalModel`.
3.  **DATA POINTS**: Address, Contact Number, Email, and GPS distance (if location is enabled).

---

## 2. Emergency: Request Blood Flow
**File:** `request_blood_screen.dart`
**Goal:** Post an urgent request for blood units to a specific hospital.

### A. Submitting the Request
1.  **USER INPUT**: User selects Blood Type, Quantity, and Contact Details.
2.  **STEP 1 (Hospital Picker)**: User opens the `HospitalPickerSheet` and selects a destination facility.
    - **DATA SOURCE**: `DatabaseService.streamHospitals()`.
3.  **STEP 2 (Legal Declaration)**: User must check the "Sworn Statement" box confirming medical need.
4.  **STEP 3 (Submission)**:
    - **FRONTEND**: `ApiService.createBloodRequest(model)`
    - **BACKEND**: `/blood-requests/` (POST) -> `requests.py` router.
5.  **STEP 4 (Persistence)**:
    - **SERVICE**: `FirestoreService.create_blood_request`
    - **DATABASE**: Writes a new document to the **'blood_requests'** collection with `type: "Request"` and `status: "pending"`.
6.  **FEEDBACK**: Screen closes and shows "Blood request posted successfully!".

---

## 3. Altruism: Donate Blood Flow
**File:** `donate_blood_screen.dart`
**Goal:** A guided process for pledging a blood donation.

### A. Eligibility & Selection (Stepper)
1.  **STEP 0 (Health Quiz)**: User must answer "Yes" to 5 health criteria (Age, Weight, Travel, etc.).
2.  **STEP 1 (Blood Type)**: User selects their blood group from a dropdown.
3.  **STEP 2 (Hospital Selection)**: User picks where they want to donate using the interactive picker.
4.  **STEP 3 (Submission)**:
    - **FRONTEND**: `ApiService.createBloodRequest(model)`
    - **BACKEND**: Transmits the request with `type: "Donate"`.
5.  **STEP 4 (Persistence)**:
    - **DATABASE**: A new document is created in Firestore. Hospital Admins will see this "Pledge" in their dashboard to approve or schedule.

---

## 4. Notifications & History
**Files:** `notifications_screen.dart`, `my_requests_screen.dart`
**Goal:** Track the progress of active requests and receive site updates.

### A. Receiving Status Alerts
1.  **TRIGGER**: A Hospital Admin updates a request from "pending" to "on progress" or "completed".
2.  **BACKEND ACTION**: The FastAPI router triggers a notification document creation in Firestore.
3.  **DATA JOURNEY**: 
    - **DATABASE**: Writes to **'notifications'** collection linked to the `userId`.
    - **FRONTEND**: `DatabaseService.streamUserNotifications(uid)` detects the change.
4.  **GUI**: A red dot or badge appears on the Dashboard, and the `NotificationsScreen` lists the update with the Admin's message.

---
**END OF NORMAL USER MAPPING**
