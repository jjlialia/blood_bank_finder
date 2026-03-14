import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/hospital_model.dart';
import '../models/blood_request_model.dart';
import '../models/inventory_model.dart';
import '../models/notification_model.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // --- Users Repository ---

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



  // --- Hospitals Repository ---


  Stream<List<HospitalModel>> streamHospitals({
    String? islandGroup,
    String? region,
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


  Future<HospitalModel?> getHospital(String id) async {
    final doc = await _db.collection('hospitals').doc(id).get();
    if (doc.exists && doc.data() != null) {
      return HospitalModel.fromMap(doc.data()!, doc.id);
    }
    return null;
  }

  // --- Inventory Repository ---


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
