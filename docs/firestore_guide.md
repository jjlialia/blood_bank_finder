# Firebase Firestore Guide (Blood Bank Finder)

Maayong adlaw! Kini nga guide magpasabut kung giunsa paggamit ang Firebase Firestore sa imong project, ang mga models nga atong gihimo, ug ang syntax nga gigamit.

> [!IMPORTANT]
> **Ayaw kalimot**: Gi-setup na nako ang Firebase initialization sa `lib/main.dart`. Siguradoa nga naka-install ang [Firebase CLI](https://firebase.google.com/docs/cli) kung gusto nimo i-test sa emulator.


---

## 🚀 Overview sa Setup

Gikonektar na nato ang imong Flutter app sa Firebase pinaagi sa:
1.  **`google-services.json`**: Gibutang sa `android/app/` para sa authentication.
2.  **Dependencies**: Gidugang ang `firebase_core` ug `cloud_firestore` sa `pubspec.yaml`.
3.  **Gradle Config**: Gi-update ang Android build files para ma-enable ang Google Services plugin.

---

## 📂 Firestore Collections & Models

Nagbuhat ta og mga **Model Classes** sa `lib/models/` para mas dali ang pag-handle sa data.

### 1. Users (`user_model.dart`)
Kini nagtipig sa profiles sa mga users (donors ug admins).
- **Syntax Tip**: Naggamit ta og `toMap()` para i-convert ang Dart object ngadto sa JSON format nga masabtan sa Firestore, ug `fromMap()` para mabalik ang JSON ngadto sa Dart object.

### 2. Hospitals (`hospital_model.dart`)
Nagtipig sa detalye sa mga blood banks ug hospitals.
- **Tip**: Ang `isActive` field gigamit para ma-filter ang mga hospitals nga aktibo pa.

### 3. Blood Requests (`blood_request_model.dart`)
Nag-track sa mga requests sa dugo ug pag-donate.
- **Syntax Tip**: Naggamit ta og `double` para sa `quantity` para accurate ang measurements.

### 4. Inventory (`inventory_model.dart`)
Sub-collection kini sa ilawom sa matag hospital para sa ilang stock sa dugo.

### 5. Notifications (`notification_model.dart`)
Para sa mga alerts sa users.

---

## 🛠️ Firestore Service (`firestore_service.dart`)

Kini ang kasing-kasing sa imong database operations. Ang mga syntax nga gigamit:

### **Pag-add og Data**
```dart
Future<void> createUser(UserModel user) async {
  await _db.collection('users').doc(user.uid).set(user.toMap());
}
```
- `collection('name')`: Magpili og table/collection.
- `doc(id)`: Magpili og specific nga document gamit ang ID.
- `set(data)`: Mag-save/overwrite og data.
- `add(data)`: Mag-save og data ug ang Firebase na ang maghimo og random ID.

### **Pag-read og Data (Streams)**
Naggamit ta og **Streams** para automatic nga ma-update ang UI kung naay mausab sa database.
```dart
Stream<List<HospitalModel>> streamHospitals() {
  return _db.collection('hospitals')
      .where('isActive', isEqualTo: true)
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => HospitalModel.fromMap(doc.data(), doc.id)).toList());
}
```
- `snapshots()`: Maminaw sa mga changes real-time.
- `map()`: I-transform ang data gikan sa Firestore format ngadto sa atong `HospitalModel`.

---

## 🔐 Security Rules (`firestore.rules`)

Importante kini para protektado ang imong data. I-copy kini ug i-paste sa **Firebase Console > Firestore Database > Rules**:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    match /hospitals/{hospitalId} {
      allow read: if true;
      allow write: if isAdmin(); // Custom function
    }
  }
}
```

---

## � Giunsa Paggamit (Practical Examples)

Ania ang mga sample codes kung unsaon paggamit ang `FirestoreService` sa imong mga widgets.

### 1. Pag-save sa Profile sa User
Paggamit ani panahon sa Sign Up:
```dart
final firestoreService = FirestoreService();

void signUpUser() async {
  UserModel newUser = UserModel(
    uid: "AUTH_UID_HERE",
    email: "user@example.com",
    role: "user",
    firstName: "Juan",
    lastName: "Dela Cruz",
    // ... add other fields
    isBanned: false,
    createdAt: DateTime.now(),
  );

  await firestoreService.createUser(newUser);
  print("User saved to Firestore!");
}
```

### 2. Pag-display sa Listahan sa Hospitals (Real-time)
Gamit og `StreamBuilder` para automatic mo-update ang UI:
```dart
StreamBuilder<List<HospitalModel>>(
  stream: firestoreService.streamHospitals(),
  builder: (context, snapshot) {
    if (snapshot.hasData) {
      final hospitals = snapshot.data!;
      return ListView.builder(
        itemCount: hospitals.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(hospitals[index].name),
            subtitle: Text(hospitals[index].address),
          );
        },
      );
    }
    return CircularProgressIndicator();
  },
)
```

### 3. Pag-create og Blood Request
```dart
void requestBlood() async {
  BloodRequestModel newRequest = BloodRequestModel(
    userId: "USER_ID",
    userName: "Juan",
    type: "Request",
    bloodType: "O+",
    status: "pending",
    hospitalId: "HOSPITAL_ID",
    hospitalName: "Cebu Blood Bank",
    contactNumber: "09123456789",
    quantity: 2.0,
    createdAt: DateTime.now(),
  );

  await firestoreService.createBloodRequest(newRequest);
}
```

---

## 📝 English Summary
- **Initialization**: Firebase is now initialized in `main.dart`.
- **Usage**: Use `FirestoreService` to call functions like `createUser` or `streamHospitals`.
- **Streams**: Use `StreamBuilder` in Flutter to listen to real-time data changes.
