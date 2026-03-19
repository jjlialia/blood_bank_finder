# Blood Bank Finder: Donating Blood Lifecycle

This guide explains the step-by-step procedure for a user to donate blood, including the eligibility quiz, hospital selection, and final submission.

---

## 1. Start: The Eligibility Quiz (Step 0)

Before donating, the user must pass a health screening.

### Step 1: User checks the eligibility boxes
**File:** [lib/features/user/screens/donate_blood_screen.dart](file:///c:/Users/The%20Chosen%20One/OneDrive/Documents/blood%20bank%20finder/lib/features/user/screens/donate_blood_screen.dart)
The user must check all 5 health criteria (Age, Weight, Travel, Meds, Feeling Well).
```dart
onChanged: (v) => setState(() => _ageOk = v ?? false),
// ... same for weight, travel, meds, well
```

### Step 2: Validation Gate
**File:** [lib/features/user/screens/donate_blood_screen.dart](file:///c:/Users/The%20Chosen%20One/OneDrive/Documents/blood%20bank%20finder/lib/features/user/screens/donate_blood_screen.dart)
When clicking "Continue", the app ensures all boxes are checked:
```dart
if (_currentStep == 0) {
  if (!(_ageOk && _weightOk && _travelOk && _medsOk && _wellOk)) {
    // Shows error: "You must meet all eligibility criteria."
    return;
  }
}
```

---

## 2. Selection: Blood Type and Hospital (Steps 1 & 2)

### Step 3: Selecting Blood Type
The user picks their blood group from a dropdown list.

### Step 4: Selecting a Hospital (Custom Picker)
**File:** [lib/shared/widgets/hospital_picker_sheet.dart](file:///c:/Users/The%20Chosen%20One/OneDrive/Documents/blood%20bank%20finder/lib/shared/widgets/hospital_picker_sheet.dart)
A bottom sheet opens where the user can search for a hospital or filter by geography.
```dart
// Fetching live hospitals from the database
stream: _db.streamHospitals(
  islandGroup: _selectedIsland,
  region: _selectedRegion,
  city: _selectedCity,
),
```

---

## 3. Submission: Sending the Data (Step 3 & 4)

### Step 5: Preparing the Data Model
**File:** [lib/features/user/screens/donate_blood_screen.dart](file:///c:/Users/The%20Chosen%20One/OneDrive/Documents/blood%20bank%20finder/lib/features/user/screens/donate_blood_screen.dart)
The app gathers all inputs (User UID, Blood Type, Hospital ID, Units) into a `BloodRequestModel`.
```dart
final request = BloodRequestModel(
  userId: auth.user!.uid,
  type: 'Donate',
  bloodType: _selectedBloodType!,
  status: 'pending',
  hospitalId: _selectedHospital!.id!,
  // ...
);
```

### Step 6: Calling the API Service
**File:** [lib/core/services/api_service.dart](file:///c:/Users/The%20Chosen%20One/OneDrive/Documents/blood%20bank%20finder/lib/core/services/api_service.dart)
The app sends the request to the **FastAPI** backend:
```dart
Future<void> createBloodRequest(BloodRequestModel request) async {
  final response = await http.post(
    Uri.parse('$baseUrl/blood-requests/'),
    body: jsonEncode(request.toJson()), // Converts data to text
  );
}
```

### Step 7: Saving to Firestore (Backend)
**File (Backend):** [backend/app/services/firestore_service.py](file:///c:/Users/The%20Chosen%20One/OneDrive/Documents/blood%20bank%20finder/backend/app/services/firestore_service.py)
The FastAPI server receives the request and saves it in the `blood_requests` collection.
```python
async def create_blood_request(self, request_data: dict) -> str:
    # Adds the record to the database
    _, doc_ref = self.db.collection('blood_requests').add(request_data)
    return doc_ref.id
```

---

### Summary of Files Involved:
1.  **UI Level**: `donate_blood_screen.dart`, `hospital_picker_sheet.dart`
2.  **Logic Level**: `auth_provider.dart`, `api_service.dart`
3.  **Backend Level**: `requests.py` (Router), `firestore_service.py` (Database Engine)
