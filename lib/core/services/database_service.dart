library;

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/hospital_model.dart';
import '../models/blood_request_model.dart';
import '../models/inventory_model.dart';
import '../models/notification_model.dart';
import '../models/audit_log_model.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // --- Users Repository ---

  /// DATA SOURCE: 'users' collection (Firestore).
  /// DATA DESTINATION: AuthProvider (for one-time profile checks).
  /// STEP 1: Receives a 'uid'.
  /// STEP 2: Fetches the user document from Firestore once.
  Future<UserModel?> getUser(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (doc.exists && doc.data() != null) {
      return UserModel.fromMap(doc.data()!);
    }
    return null;
  }

  /// DATA SOURCE: 'users' collection (Firestore Stream).
  /// DATA DESTINATION: AuthProvider (keeps memory model synced).
  /// STEP 1: Receives a 'uid'.
  /// STEP 2: Opens a persistent connection (Stream) to the user's document.
  Stream<UserModel?> streamUser(String uid) {
    return _db.collection('users').doc(uid).snapshots().map((doc) {
      if (doc.exists && doc.data() != null) {
        return UserModel.fromMap(doc.data()!);
      }
      return null;
    });
  }

  /// DATA SOURCE: 'users' collection (Firestore).
  /// DATA DESTINATION: ManageUsersScreen (Super Admin List).
  Stream<List<UserModel>> streamAllUsers() {
    return _db.collection('users').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => UserModel.fromMap(doc.data())).toList();
    });
  }

  // --- Hospitals Repository ---

  ///r:'hospitals' collection (Firestore).
  ///s: FindBloodBankScreen / ManageHospitalsScreen/hospital_picker_sheet.dart
  ///Builds and executes a Firestore Query.
  Stream<List<HospitalModel>> streamHospitals({
    String? islandGroup,
    String? region,
    String? city,
    String? barangay,
    bool allowAll = false,
  }) {
    Query query = _db.collection('hospitals');

    if (!allowAll) {
      query = query.where('isActive', isEqualTo: true);
    }

    if (islandGroup != null && islandGroup.isNotEmpty) {
      query = query.where('islandGroup', isEqualTo: islandGroup);
    }

    if (region != null && region.isNotEmpty) {
      query = query.where('region', isEqualTo: region);
    }

    if (city != null && city.isNotEmpty) {
      query = query.where('city', isEqualTo: city);
    }

    if (barangay != null && barangay.isNotEmpty) {
      query = query.where('barangay', isEqualTo: barangay);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs
          .map(
            (doc) => HospitalModel.fromMap(
              doc.data() as Map<String, dynamic>,
              doc.id,
            ),
          )
          .toList();
    });
  }

  // --- Blood Requests Repository ---

  /// r: 'blood_requests' collection (Firestore). s: Super Admin Dashboard / HistoryScreen.
  Stream<List<BloodRequestModel>> streamAllBloodRequests() {
    return _db
        .collection('blood_requests')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => BloodRequestModel.fromMap(doc.data(), doc.id))
              .toList();
        });
  }

  /// r: 'blood_requests' collection (Firestore Filtered). s: MyRequestsScreen (user history).
  /// Streams all requests/donations submitted by a specific user, newest first.
  Stream<List<BloodRequestModel>> streamUserRequests(String userId) {
    return _db
        .collection('blood_requests')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => BloodRequestModel.fromMap(doc.data(), doc.id))
          .toList();
      // Client-side sort to avoid requiring a composite index
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  /// r: 'blood_requests' collection (Firestore Filtered). s: blood_request_list_screen.dart and HospitalAdminDashboard.
  Stream<List<BloodRequestModel>> streamHospitalRequests(String hospitalId) {
    return _db
        .collection('blood_requests')
        .where('hospitalId', isEqualTo: hospitalId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => BloodRequestModel.fromMap(doc.data(), doc.id))
          .toList();
      // Client-side sort to avoid requiring a composite index
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  /// DATA SOURCE: 'blood_requests' collection (Firestore).
  /// DATA DESTINATION: NotificationsScreen / DetailedView.
  Future<BloodRequestModel?> getRequest(String id) async {
    final doc = await _db.collection('blood_requests').doc(id).get();
    if (doc.exists && doc.data() != null) {
      return BloodRequestModel.fromMap(doc.data()!, doc.id);
    }
    return null;
  }

  /// DATA SOURCE: 'hospitals' collection (Firestore).
  /// DATA DESTINATION: ProfileScreen / HospitalDetails.
  Future<HospitalModel?> getHospital(String id) async {
    final doc = await _db.collection('hospitals').doc(id).get();
    if (doc.exists && doc.data() != null) {
      return HospitalModel.fromMap(doc.data()!, doc.id);
    }
    return null;
  }

  // --- Inventory Repository ---

  /// r: 'hospitals/{id}/inventory' collection (Firestore). s: InventoryManagementScreen.dart.
  Stream<List<InventoryModel>> streamInventory(String hospitalId) {
    return _db
        .collection('hospitals')
        .doc(hospitalId)
        .collection('inventory')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => InventoryModel.fromMap(doc.data(), doc.id))
              .toList();
        });
  }

  // --- Notifications Repository ---

  /// DATA SOURCE: 'notifications' collection (Firestore).
  /// DATA DESTINATION: NotificationsScreen.
  Stream<List<NotificationModel>> streamUserNotifications(String userId) {
    return _db
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => NotificationModel.fromMap(doc.data(), doc.id))
          .toList();
      // Client-side sort to avoid requiring a composite index
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  // --- Audit Logs Repository ---

  /// DATA SOURCE: 'audit_logs' collection (Firestore).
  /// STEP 1: Receives an AuditLogModel.
  /// STEP 2: Adds the log to the 'audit_logs' collection.
  Future<void> logAction(AuditLogModel log) async {
    try {
      await _db.collection('audit_logs').add(log.toMap());
    } catch (e) {
      print('Error logging action: $e');
    }
  }

  /// DATA SOURCE: 'audit_logs' collection (Firestore Stream).
  /// Streams all audit logs, newest first.
  Stream<List<AuditLogModel>> streamAuditLogs() {
    return _db
        .collection('audit_logs')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => AuditLogModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }
}

/// FILE: database_service.dart
///
/// DESCRIPTION:
/// This file is responsible for all DIRECT read operations from Firebase Firestore.
/// While 'api_service.dart' handles writing data through the FastAPI backend, this service
/// focuses on retrieving that data in real-time using Streams and one-time Gets.
///
/// DATA FLOW OVERVIEW:
/// 1. RECEIVES DATA FROM:
///    - Firebase Firestore (Cloud Database) via the 'cloud_firestore' package.
/// 2. PROCESSING:
///    - Listens to document/collection snapshots (real-time updates).
///    - Maps raw Firestore Map data into structured Flutter models (UserModel, HospitalModel, etc.).
///    - Filters hospital data based on geographical location (Island Group, Region, etc.).
/// 3. SENDS DATA TO:
///    - UI Screens (e.g., FindBloodBankScreen, HistoryScreen, Dashboard) via Streams and Futures.
/// 4. OUTPUTS/RESPONSES:
///    - Returns structured 'Model' objects or 'List<Model>' for the UI to display.
///
/// KEY COMPONENTS:
/// - streamUser: Provides real-time profile updates for the currently logged-in user.
/// - streamHospitals: Fetches and filters hospitals for the map and list views.
/// - streamAllBloodRequests: Allows admins to monitor all donation/request activity.
/// - streamInventory: Shows current blood supply levels for specific hospitals.
