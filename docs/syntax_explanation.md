# Flutter & Dart Syntax Explanation Guide

This guide explains the mission-critical code patterns used in the Blood Bank Finder app.

## 1. Provider (State Management)
We use `Provider` to keep the UI in sync with the data.

```dart
// Dependency Injection: Wrapping the app with AuthProvider
ChangeNotifierProvider(
  create: (_) => AuthProvider(),
  child: const MyApp(),
)

// Accessing the provider in UI
final auth = context.read<AuthProvider>(); // For actions (one-time)
final user = context.watch<AuthProvider>().user; // For UI updates (listening)
```

## 2. Models & JSON Serialization
Dart classes represent our Firestore documents. `fromMap` and `toMap` are used to convert data.

```dart
class UserModel {
  final String uid;
  // ... fields
  
  // Factory constructor for creating a model from Firestore data
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'],
      // ... initialization
    );
  }
}
```

## 3. Repository Pattern (DatabaseService)
Instead of putting Firestore logic in the UI, we centralize it in `DatabaseService`.

```dart
class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Stream: Returns a real-time flow of data
  Stream<List<HospitalModel>> streamHospitals() {
    return _db.collection('hospitals').snapshots().map(...);
  }
}
```

## 4. Async/Await (Handling Time)
Used for operations that take time, such as logging in or saving to the database.

```dart
Future<void> login() async {
  try {
    await auth.signIn(...); // Wait for the login to finish
  } catch (e) {
    print(e); // Handle errors
  }
}
```

## 5. Streams & StreamBuilder
Used for real-time UI updates (e.g., Global Log or User Listing).

```dart
StreamBuilder<List<UserModel>>(
  stream: db.streamAllUsers(),
  builder: (context, snapshot) {
    if (snapshot.hasData) {
      return ListView(...); // Rebuilds automatically when data changes in Firestore
    }
    return CircularProgressIndicator();
  }
)
```
