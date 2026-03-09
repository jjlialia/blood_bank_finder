import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import '../models/user_model.dart';
import '../models/hospital_model.dart';
import '../models/blood_request_model.dart';
import '../models/inventory_model.dart';
import '../models/notification_model.dart';
import 'api_service.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final ApiService _api = ApiService();

  // --- Users Repository ---
  Future<void> saveUser(UserModel user) async {
    // Sync to Backend (which handles Firestore persistence)
    final response = await _api.post('/users/', user.toMap());
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to save user: ${response.body}');
    }
  }

  Future<void> updateUser(UserModel user) async {
    final response = await _api.put('/users/${user.uid}', user.toMap());
    if (response.statusCode != 200) {
      throw Exception('Failed to update user: ${response.body}');
    }
  }

  Future<UserModel?> getUser(String uid) async {
    final response = await _api.get('/users/$uid');
    if (response.statusCode == 200) {
      return UserModel.fromMap(jsonDecode(response.body));
    }

    // Fallback to Firestore for now
    final doc = await _db.collection('users').doc(uid).get();
    if (doc.exists && doc.data() != null) {
      return UserModel.fromMap(doc.data()!);
    }
    return null;
  }

  Stream<UserModel?> streamUser(String uid) {
    return _db.collection('users').doc(uid).snapshots().map((doc) {
      if (doc.exists && doc.data() != null) {
        return UserModel.fromMap(doc.data()!);
      }
      return null;
    });
  }

  Stream<List<UserModel>> streamAllUsers() {
    return _db.collection('users').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => UserModel.fromMap(doc.data())).toList();
    });
  }

  Future<void> toggleUserBan(String uid, bool isBanned) async {
    final response = await _api.patch(
      '/users/$uid/ban?is_banned=$isBanned',
      {},
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to toggle ban: ${response.body}');
    }
  }

  Future<void> updateUserRoleAndHospital({
    required String uid,
    required String role,
    String? hospitalId,
  }) async {
    final url =
        '/users/$uid/role?role=$role${hospitalId != null ? '&hospital_id=$hospitalId' : ''}';
    final response = await _api.patch(url, {});
    if (response.statusCode != 200) {
      throw Exception('Failed to update role: ${response.body}');
    }
  }

  // --- Hospitals Repository ---
  Future<void> addHospital(HospitalModel hospital) async {
    final response = await _api.post('/hospitals/', hospital.toMap());
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to add hospital: ${response.body}');
    }
  }

  Future<void> deleteHospital(String hospitalId) async {
    final response = await _api.delete('/hospitals/$hospitalId');
    if (response.statusCode != 200) {
      throw Exception('Failed to delete hospital: ${response.body}');
    }
  }

  Future<void> updateHospital(String hospitalId, HospitalModel hospital) async {
    final response = await _api.put('/hospitals/$hospitalId', hospital.toMap());
    if (response.statusCode != 200) {
      throw Exception('Failed to update hospital: ${response.body}');
    }
  }

  Stream<List<HospitalModel>> streamHospitals({
    String? islandGroup,
    String? city,
    String? barangay,
    bool allowAll = false, // Added to show inactive hospitals to Super Admin
  }) {
    Query query = _db.collection('hospitals');

    if (!allowAll) {
      query = query.where('isActive', isEqualTo: true);
    }

    if (islandGroup != null && islandGroup.isNotEmpty) {
      query = query.where('islandGroup', isEqualTo: islandGroup);
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
  Future<void> createBloodRequest(BloodRequestModel request) async {
    final response = await _api.post('/blood-requests/', request.toMap());
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to create blood request: ${response.body}');
    }
  }

  Stream<List<BloodRequestModel>> streamAllBloodRequests() {
    // For "Full Migration", we should eventually use WebSockets or Polling.
    // For now, I'll keep the Firestore stream to maintain real-time UI,
    // but the writes are already going through the API.
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

  Stream<List<BloodRequestModel>> streamHospitalRequests(String hospitalId) {
    return _db
        .collection('blood_requests')
        .where('hospitalId', isEqualTo: hospitalId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => BloodRequestModel.fromMap(doc.data(), doc.id))
              .toList();
        });
  }

  Future<void> updateRequestStatus(
    String requestId,
    String status, {
    String? adminMessage,
  }) async {
    final response = await _api.patch(
      '/blood-requests/$requestId/status?status=$status',
      {},
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to update request status: ${response.body}');
    }
  }

  Future<void> updateRequestStatusWithNotification({
    required BloodRequestModel request,
    required String newStatus,
    String? adminMessage,
  }) async {
    // The backend now handles notification creation within the status update endpoint.
    await updateRequestStatus(
      request.id!,
      newStatus,
      adminMessage: adminMessage,
    );
  }

  Future<HospitalModel?> getHospital(String id) async {
    final doc = await _db.collection('hospitals').doc(id).get();
    if (doc.exists && doc.data() != null) {
      return HospitalModel.fromMap(doc.data()!, doc.id);
    }
    return null;
  }

  // --- Inventory Repository ---
  Future<void> updateInventory(
    String hospitalId,
    String bloodType,
    double units,
  ) async {
    final response = await _api.put(
      '/hospitals/$hospitalId/inventory/$bloodType',
      {'units': units},
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to update inventory: ${response.body}');
    }
  }

  Stream<List<InventoryModel>> streamInventory(String hospitalId) {
    // Keep Firestore stream for real-time for now
    return _db
        .collection('hospitals')
        .doc(hospitalId)
        .collection('inventory')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => InventoryModel.fromMap(doc.data()))
              .toList();
        });
  }

  // --- Notifications Repository ---
  Future<void> sendNotification(NotificationModel notification) async {
    final response = await _api.post('/notifications/', notification.toMap());
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to send notification: ${response.body}');
    }
  }

  Stream<List<NotificationModel>> streamUserNotifications(String userId) {
    // Keep Firestore stream for real-time for now
    return _db
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => NotificationModel.fromMap(doc.data(), doc.id))
              .toList();
        });
  }

  // --- Locations Repository ---
  Future<List<String>> getIslandGroups() async {
    final response = await _api.get('/locations/island-groups');
    if (response.statusCode == 200) {
      return List<String>.from(jsonDecode(response.body));
    }
    return [];
  }

  Future<List<String>> getCities(String islandGroup) async {
    final response = await _api.get('/locations/cities/$islandGroup');
    if (response.statusCode == 200) {
      return List<String>.from(jsonDecode(response.body));
    }
    return [];
  }

  Future<List<String>> getBarangays(String city) async {
    final response = await _api.get('/locations/barangays/$city');
    if (response.statusCode == 200) {
      return List<String>.from(jsonDecode(response.body));
    }
    return [];
  }
}
