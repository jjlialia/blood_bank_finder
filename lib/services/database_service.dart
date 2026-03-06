import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/hospital_model.dart';
import '../models/blood_request_model.dart';
import '../models/inventory_model.dart';
import '../models/notification_model.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // --- Users Repository ---
  Future<void> saveUser(UserModel user) async {
    await _db.collection('users').doc(user.uid).set(user.toMap());
  }

  Future<void> updateUser(UserModel user) async {
    await _db.collection('users').doc(user.uid).update(user.toMap());
  }

  Future<UserModel?> getUser(String uid) async {
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
    await _db.collection('users').doc(uid).update({'isBanned': isBanned});
  }

  Future<void> updateUserRoleAndHospital({
    required String uid,
    required String role,
    String? hospitalId,
  }) async {
    await _db.collection('users').doc(uid).update({
      'role': role,
      'hospitalId': hospitalId,
    });
  }

  // --- Hospitals Repository ---
  Future<void> addHospital(HospitalModel hospital) async {
    await _db.collection('hospitals').add(hospital.toMap());
  }

  Future<void> deleteHospital(String hospitalId) async {
    await _db.collection('hospitals').doc(hospitalId).delete();
  }

  Future<void> updateHospital(String hospitalId, HospitalModel hospital) async {
    await _db.collection('hospitals').doc(hospitalId).update(hospital.toMap());
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
    await _db.collection('blood_requests').add(request.toMap());
  }

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
    await _db.collection('blood_requests').doc(requestId).update({
      'status': status,
      if (adminMessage != null) 'adminMessage': adminMessage,
    });
  }

  Future<void> updateRequestStatusWithNotification({
    required BloodRequestModel request,
    required String newStatus,
    String? adminMessage,
  }) async {
    // 1. Update the request status
    await updateRequestStatus(
      request.id!,
      newStatus,
      adminMessage: adminMessage,
    );

    // 2. Create a notification for the user
    String title = '';
    String body = '';
    String type = '';

    switch (newStatus) {
      case 'approved':
        title = 'Request Approved!';
        body =
            'Your ${request.type} for ${request.bloodType} at ${request.hospitalName} has been approved.';
        type = 'request_approved';
        break;
      case 'on progress':
        title = 'Request is now On Progress';
        body =
            'Your ${request.type} for ${request.bloodType} at ${request.hospitalName} is now being processed.';
        type = 'request_on_progress';
        break;
      case 'completed':
        title = 'Request Completed';
        body =
            'Your ${request.type} for ${request.bloodType} at ${request.hospitalName} is now complete. Thank you for using Blood Bank Finder!';
        type = 'request_completed';
        break;
      case 'rejected':
        title = 'Request Rejected';
        body =
            'Sorry, your ${request.type} for ${request.bloodType} at ${request.hospitalName} was rejected.';
        type = 'request_rejected';
        break;
    }

    if (adminMessage != null && adminMessage.isNotEmpty) {
      body += '\n\nMessage from hospital: "$adminMessage"';
    }

    if (title.isNotEmpty) {
      final notification = NotificationModel(
        userId: request.userId,
        message: body,
        isRead: false,
        createdAt: DateTime.now(),
      );

      final data = notification.toMap();
      data['type'] = type;
      data['title'] = title;
      data['body'] = body;

      await _db.collection('notifications').add(data);
    }
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
    await _db
        .collection('hospitals')
        .doc(hospitalId)
        .collection('inventory')
        .doc(bloodType)
        .set({
          'blood_type': bloodType,
          'units': units,
          'last_updated': FieldValue.serverTimestamp(),
        });
  }

  Stream<List<InventoryModel>> streamInventory(String hospitalId) {
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
    await _db.collection('notifications').add(notification.toMap());
  }

  Stream<List<NotificationModel>> streamUserNotifications(String userId) {
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
}
