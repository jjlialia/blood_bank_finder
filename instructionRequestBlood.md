# Blood Bank Finder: Blood Request Lifecycle

This guide explains the step-by-step procedure for a user to post an emergency blood request, including the hospital selection and API submission.

---

## 1. Input: Details and Selection

### Step 1: User fills the request form
**File:** [lib/features/user/screens/request_blood_screen.dart](file:///c:/Users/The%20Chosen%20One/OneDrive/Documents/blood%20bank%20finder/lib/features/user/screens/request_blood_screen.dart)
The user selects a "Blood Type", enters the "Quantity" (units), and provides "Contact Details".

### Step 2: Selecting a Hospital
**File:** [lib/shared/widgets/hospital_picker_sheet.dart](file:///c:/Users/The%20Chosen%20One/OneDrive/Documents/blood%20bank%20finder/lib/shared/widgets/hospital_picker_sheet.dart)
The user taps the "Select Hospital" field. A bottom sheet appears, allowing them to search for a facility or filter by location (Island, Region, City).
```dart
onHospitalSelected: (h) {
  setState(() => _selectedHospital = h); // Saves the picked hospital
},
```

---

## 2. Verification: The Sworn Statement

### Step 3: Medical Urgency Check
**File:** [lib/features/user/screens/request_blood_screen.dart](file:///c:/Users/The%20Chosen%20One/OneDrive/Documents/blood%20bank%20finder/lib/features/user/screens/request_blood_screen.dart)
To prevent misuse, the user MUST check the "Sworn Statement" box. If not checked, the button is disabled:
```dart
onPressed: _isSworn ? () => _submitRequest(auth) : null,
```

---

## 3. Submission: Sending the Request

### Step 4: Gathering the Data
**File:** [lib/features/user/screens/request_blood_screen.dart](file:///c:/Users/The%20Chosen%20One/OneDrive/Documents/blood%20bank%20finder/lib/features/user/screens/request_blood_screen.dart)
The app creates a `BloodRequestModel` containing the User ID, Hospital ID, and the details entered.
```dart
final request = BloodRequestModel(
  userId: auth.user!.uid,
  type: 'Request',
  bloodType: _selectedBloodType!,
  status: 'pending',
  hospitalId: _selectedHospital!.id!,
  // ...
);
```

### Step 5: Sending to the Backend (FastAPI)
**File:** [lib/core/services/api_service.dart](file:///c:/Users/The%20Chosen%20One/OneDrive/Documents/blood%20bank%20finder/lib/core/services/api_service.dart)
The request is sent to the FastAPI server:
```dart
Future<void> createBloodRequest(BloodRequestModel request) async {
  await http.post(
    Uri.parse('$baseUrl/blood-requests/'),
    body: jsonEncode(request.toJson()), // Transmits data to backend
  );
}
```

### Step 6: Storing globally in Firestore
**File (Backend):** [backend/app/services/firestore_service.py](file:///c:/Users/The%20Chosen%20One/OneDrive/Documents/blood%20bank%20finder/backend/app/services/firestore_service.py)
The FastAPI backend saves the record into the `blood_requests` collection, where admins can see it.
```python
self.db.collection('blood_requests').add(request_data)
```

---

### Summary of Files Involved:
1.  **UI Level**: `request_blood_screen.dart`, `hospital_picker_sheet.dart`
2.  **Logic Level**: `api_service.dart`, `auth_provider.dart`
3.  **Backend Level**: `requests.py` (Router), `firestore_service.py` (Database Engine)
