/**
 * FILE: database_service.dart
 * 
 * DESCRIPTION:
 * This file is responsible for all DIRECT read operations from Firebase Firestore.
 * While 'api_service.dart' handles writing data through the FastAPI backend, this service 
 * focuses on retrieving that data in real-time using Streams and one-time Gets.
 * 
 * DATA FLOW OVERVIEW:
 * 1. RECEIVES DATA FROM: 
 *    - Firebase Firestore (Cloud Database) via the 'cloud_firestore' package.
 * 2. PROCESSING:
 *    - Listens to document/collection snapshots (real-time updates).
 *    - Maps raw Firestore Map data into structured Flutter models (UserModel, HospitalModel, etc.).
 *    - Filters hospital data based on geographical location (Island Group, Region, etc.).
 * 3. SENDS DATA TO:
 *    - UI Screens (e.g., FindBloodBankScreen, HistoryScreen, Dashboard) via Streams and Futures.
 * 4. OUTPUTS/RESPONSES:
 *    - Returns structured 'Model' objects or 'List<Model>' for the UI to display.
 * 
 * KEY COMPONENTS:
 * - streamUser: Provides real-time profile updates for the currently logged-in user.
 * - streamHospitals: Fetches and filters hospitals for the map and list views.
 * - streamAllBloodRequests: Allows admins to monitor all donation/request activity.
 * - streamInventory: Shows current blood supply levels for specific hospitals.
 */

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/hospital_model.dart';
import '../models/blood_request_model.dart';
import '../models/inventory_model.dart';
import '../models/notification_model.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // --- Users Repository ---

  /**
   * STEP 1: Receives a 'uid'.
   * STEP 2: Fetches the user document from the 'users' collection once.
   * STEP 3: Converts the raw Firestore data into a 'UserModel'.
   * OUTPUT: A 'UserModel' object for one-time profile checks.
   */
  Future<UserModel?> getUser(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (doc.exists && doc.data() != null) {
      return UserModel.fromMap(doc.data()!);
    }
    return null;
  }

  /**
   * STEP 1: Receives a 'uid'.
   * STEP 2: Opens a persistent connection (Stream) to the user's document.
   * STEP 3: Every time the user's data changes in Firestore (e.g., name update), this sends the new data.
   * OUTPUT: A Stream of 'UserModel' that keeps the UI updated automatically.
   */
  Stream<UserModel?> streamUser(String uid) {
    return _db.collection('users').doc(uid).snapshots().map((doc) {
      if (doc.exists && doc.data() != null) {
        return UserModel.fromMap(doc.data()!);
      }
      return null;
    });
  }

  /**
   * STEP: For Super Admins to see a list of every user registered in the system.
   */
  Stream<List<UserModel>> streamAllUsers() {
    return _db.collection('users').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => UserModel.fromMap(doc.data())).toList();
    });
  }

  // --- Hospitals Repository ---

  /**
   * STEP 1: Receives optional filters (Island, Region, City, etc.).
   * STEP 2: Builds a Firestore Query based on these filters.
   * STEP 3: Fetches hospitals that match the criteria.
   * STEP 4: Converts each document into a 'HospitalModel'.
   * OUTPUT: A Stream of hospitals to be displayed on the map or in search results.
   */
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

  /**
   * STEP: Retrieves every blood request ever made, sorted by date (newest first).
   * Used primarily by Super Admins for global monitoring.
   */
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

  /**
   * STEP: For Hospital Admins to see only the requests assigned to THEIR hospital.
   */
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

  /**
   * STEP: One-time fetch of a single hospital's details by its ID.
   */
  Future<HospitalModel?> getHospital(String id) async {
    final doc = await _db.collection('hospitals').doc(id).get();
    if (doc.exists && doc.data() != null) {
      return HospitalModel.fromMap(doc.data()!, doc.id);
    }
    return null;
  }

  // --- Inventory Repository ---

  /**
   * STEP 1: Receives 'hospitalId'.
   * STEP 2: Monitors the 'inventory' sub-collection inside that hospital's document.
   * OUTPUT: Real-time list of blood units available (A+, B-, etc.) for that specific hospital.
   */
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

  /**
   * STEP 1: Receives 'userId'.
   * STEP 2: Listens for any notifications where 'userId' matches the current user.
   * OUTPUT: A list of alerts (e.g., "Your blood request was approved") delivered to the user's phone.
   */
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
