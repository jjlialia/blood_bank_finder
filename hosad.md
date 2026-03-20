# Hospital Admin Operations Mapping

This document provides a comprehensive, step-by-step breakdown of all administrative operations available to the **Hospital Admin** role. It traces the data journey from the initial Flutter UI interaction to the final database persistence and automated user notifications.

---

## 1. Inventory Management Flow
**File:** `inventory_management_screen.dart`
**Goal:** Maintain accurate stock levels for all blood groups at the assigned facility.

### A. Updating Blood Stock
1.  **USER INPUT**: Admin identifies a blood type (e.g., "A+") and enters a new number in the "Qty" text field.
2.  **STEP 1 (Trigger)**: Admin presses 'Enter' or 'Done' on the keyboard (`onSubmitted`).
3.  **STEP 2 (Validation)**: The UI validates that the input is a non-negative number.
4.  **STEP 3 (Submission)**:
    - **FRONTEND**: `ApiService.updateInventory(hospitalId, type, newUnits)`
    - **BACKEND**: `/inventory/{hospital_id}` (PUT) -> `inventory.py` router.
5.  **STEP 4 (Persistence)**:
    - **SERVICE**: `FirestoreService.update_inventory`
    - **DATABASE**: Executes a **Transactional Update** on the specific blood type document within the hospital's inventory sub-collection. This ensures data integrity if multiple admins update simultaneously.
6.  **FEEDBACK**: SnackBar shows "Updated [Type] to [Units] via FastAPI".

---

## 2. Blood Request & Donation Management
**File:** `blood_requests_list_screen.dart`
**Goal:** Process patient requests and donation pledges specifically for the admin's hospital.

### A. Reviewing and Filtering Requests
1.  **DATA SOURCE**: `DatabaseService.streamHospitalRequests(hospitalId)`
2.  **FLOW**:
    - **DATABASE**: Reads the **'blood_requests'** collection, filtered where `hospitalId` matches the admin's assigned ID.
    - **FRONTEND**: Returns a `Stream<List<BloodRequestModel>>`.
3.  **PROCESSING**: Admin uses the Filter Chips (Pending, On Progress, etc.) to sort the list locally for quick action.

### B. Updating Request Status (Quick Swipe)
1.  **USER ACTION**: Admin swipes a request card to the Right (Approve) or Left (Reject).
2.  **STEP 1 (Submission)**:
    - **FRONTEND**: `ApiService.updateRequestStatus(requestId, status)`
    - **BACKEND**: `/blood-requests/{request_id}/status` (PATCH).
3.  **STEP 2 (Persistence & Trigger)**:
    - **SERVICE**: `FirestoreService.update_request_status`
    - **DATABASE**: Updates the `status` field in the request document.
    - **AUTOMATION**: The backend automatically triggers a new notification for the requesting user.
4.  **FEEDBACK**: The card is dismissed from the current list view.

### C. Detailed Status Update (with Admin Note)
1.  **USER ACTION**: Admin taps a request -> Modal Bottom Sheet opens.
2.  **STEP 1 (Form)**: Admin selects a new Status from the dropdown and optionally types a "Message for patient".
3.  **STEP 2 (Submit)**: Admin clicks "Confirm Changes".
    - **FRONTEND**: `ApiService.updateRequestStatus(requestId, status, adminMessage: "...")`
    - **BACKEND**: Sends a PATCH request with the `admin_message` body.
4.  **STEP 3 (Persistence)**:
    - **DATABASE**: Updates the request document with both the new `status` and the `adminMessage`.
    - **AUTOMATION**: The backend sends a notification to the user containing the specific admin message.

---

## 3. Hospital Site Monitoring
**Goal:** Real-time visibility into the facility's operational status.

### A. Dashboard Stat Cards
1.  **UI**: `hospital_admin_dashboard.dart`
2.  **DATA JOURNEY**:
    - **Pending Requests**: Firestore -> `streamHospitalRequests` -> Filters for `status == 'pending'` -> UI Display.
    - **Low Stock Alerts**: Firestore -> `streamInventory` -> Filters for `units < 5` -> UI Display.

### B. Visual Inventory Summary
1.  **UI**: `hospital_admin_dashboard.dart` (Progress Bars)
2.  **DATA SOURCE**: `DatabaseService.streamInventory(hospitalId)`
3.  **PROCESSING**: The UI maps the raw unit count to a percentage (relative to a 20-unit full capacity) to render visual progress bars. Red bars indicate critical low stock.

---
**END OF HOSPITAL ADMIN MAPPING**
