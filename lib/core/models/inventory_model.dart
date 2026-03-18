/**
 * FILE: inventory_model.dart
 * 
 * DESCRIPTION:
 * This file defines the 'InventoryModel', which tracks the stock levels of a 
 * specific blood type (e.g., A+, B-) within a hospital.
 * 
 * DATA FLOW OVERVIEW:
 * 1. RECEIVES DATA FROM: 
 *    - Firestore (via 'fromMap'): Fetches from the 'inventory' sub-collection of a hospital.
 *    - Hospital Admin UI: When updating stock levels.
 * 2. PROCESSING:
 *    - Manages the 'units' count (amount of blood available).
 *    - Tracks 'lastUpdated' to ensure data freshness.
 * 3. SENDS DATA TO:
 *    - Firestore (via 'toMap'): Directly updates the hospital's inventory sub-collection.
 *    - FastAPI: Used when the backend needs to validate stock before approving a request.
 *    - Dashboard UI: Shows admins and users what blood is currently available.
 */

import 'package:cloud_firestore/cloud_firestore.dart';

class InventoryModel {
  // E.g., "A+", "O-", "AB+".
  final String bloodType;
  // Number of bags or units available.
  final int units;
  final DateTime lastUpdated;

  InventoryModel({
    required this.bloodType,
    required this.units,
    required this.lastUpdated,
  });

  /**
   * STEP: Converts raw Firestore data into an 'InventoryModel'.
   */
  factory InventoryModel.fromMap(Map<String, dynamic> data) {
    return InventoryModel(
      bloodType: data['blood_type'] ?? '',
      units: data['units'] ?? 0,
      lastUpdated: (data['last_updated'] as Timestamp).toDate(),
    );
  }

  /**
   * STEP: Prepares the inventory data for saving back to Firestore.
   */
  Map<String, dynamic> toMap() {
    return {
      'blood_type': bloodType,
      'units': units,
      'last_updated': Timestamp.fromDate(lastUpdated),
    };
  }
}
