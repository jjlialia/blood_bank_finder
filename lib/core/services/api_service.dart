/// FILE: api_service.dart
///
/// DESCRIPTION:
/// This file serves as the central communication hub between the Flutter frontend and the FastAPI backend.
/// It manages all outbound HTTP requests for data persistence and administrative actions that require
/// server-side logic (like banning users or updating roles).
///
/// DATA FLOW OVERVIEW:
/// 1. RECEIVES DATA FROM:
///    - UI Screens (e.g., RequestBloodScreen, DonateBloodScreen, ManageHospitalsScreen) in the form of
///      Model objects (UserModel, BloodRequestModel, HospitalModel) or primitive types (strings, IDs).
/// 2. PROCESSING:
///    - Encodes data into JSON format using 'jsonEncode'.
///    - Constructs dynamic URLs with query parameters for specific API endpoints.
///    - Handles platform-specific base URLs (AVD vs. Web).
/// 3. SENDS DATA TO:
///    - FastAPI Backend (running on localhost:8000 or 10.0.2.2:8000).
/// 4. OUTPUTS/RESPONSES:
///    - Returns 'void' for most operations, throwing 'Exception' if the server returns a non-success status code.
///    - Returns 'Location' objects for geocoding requests.
///
/// KEY COMPONENTS:
/// - baseUrl: Determines the API's root address based on the running platform.
/// - CRUD Operations: Methods for creating, updating, and deleting blood requests, users, and hospitals.
/// - Geocoding: Converts physical addresses to geographic coordinates (lat/lng) for map integration.
library;

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';
import '../models/blood_request_model.dart';
import '../models/hospital_model.dart';
import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart';

class ApiService {
  // Use http://10.0.2.2:8000 for Android Emulator
  // Use http://localhost:8000 for Web/Desktop
  // STEP: This allows the app to know where the "brain" (FastAPI) is located.
  static String get baseUrl {
    if (kIsWeb) return 'http://127.0.0.1:8000';
    return 'http://10.0.2.2:8000';
  }

  // --- Blood Requests ---

  /// DATA SOURCE: RequestBloodScreen / DonateBloodScreen (UI).
  /// DATA JOURNEY: Flutter -> FastAPI (/blood-requests/) -> Firestore.
  /// STEP 1: Receives a 'BloodRequestModel' containing form data.
  /// STEP 2: Sends a POST request to the backend.
  Future<void> createBloodRequest(BloodRequestModel request) async {
    final response = await http.post(
      Uri.parse('$baseUrl/blood-requests/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(request.toJson()),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to create blood request: ${response.body}');
    }
  }

  /// DATA SOURCE: HospitalAdminRequestsScreen (UI Action).
  /// DATA JOURNEY: Flutter -> FastAPI (/blood-requests/{id}/status) -> Firestore.
  /// STEP 1: Receives 'requestId' and the new 'status'.
  /// STEP 2: Sends a PATCH request to trigger the status update and user notification.
  Future<void> updateRequestStatus(
    String requestId,
    String status, {
    String? adminMessage,
  }) async {
    final queryParams = adminMessage != null
        ? '?status=$status&admin_message=${Uri.encodeComponent(adminMessage)}'
        : '?status=$status';

    final response = await http.patch(
      Uri.parse('$baseUrl/blood-requests/$requestId/status$queryParams'),
      headers: {'Accept': 'application/json'},
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update request status: ${response.body}');
    }
  }

  // --- Inventory ---

  /// DATA SOURCE: InventoryManagementScreen (UI TextField).
  /// DATA JOURNEY: Flutter -> FastAPI (/hospitals/{id}/inventory/) -> Firestore Transaction.
  /// STEP 1: Receives hospital ID, blood type, and the new unit count.
  /// STEP 2: Sends a PUT request to perform a safe inventory update.
  Future<void> updateInventory(
    String hospitalId,
    String bloodType,
    double units,
  ) async {
    final response = await http.put(
      Uri.parse(
        '$baseUrl/hospitals/$hospitalId/inventory/$bloodType?units=$units',
      ),
      headers: {'Accept': 'application/json'},
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update inventory: ${response.body}');
    }
  }

  // --- Users ---

  /// DATA SOURCE: SignupScreen (Auth Flow).
  /// DATA JOURNEY: Flutter -> FastAPI (/users/) -> Firestore.
  /// STEP 1: Receives a 'UserModel' after Firebase Auth creation.
  /// STEP 2: Sends a POST request to save the full profile to the backend db.
  Future<void> saveUser(UserModel user) async {
    final response = await http.post(
      Uri.parse('$baseUrl/users/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(user.toJson()),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to save user: ${response.body}');
    }
  }

  /// DATA SOURCE: ManageUsersScreen (Admin Toggle).
  /// DATA JOURNEY: Flutter -> FastAPI (/users/{uid}/ban) -> Firestore.
  Future<void> toggleUserBan(String uid, bool isBanned) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/users/$uid/ban?is_banned=$isBanned'),
      headers: {'Accept': 'application/json'},
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update ban status: ${response.body}');
    }
  }

  /// DATA SOURCE: UserRolesScreen (Admin Action).
  /// DATA JOURNEY: Flutter -> FastAPI (/users/{uid}/role) -> Firestore.
  Future<void> updateUserRole(
    String uid,
    String role, {
    String? hospitalId,
  }) async {
    final queryParams = hospitalId != null
        ? '?role=$role&hospital_id=$hospitalId'
        : '?role=$role';

    final response = await http.patch(
      Uri.parse('$baseUrl/users/$uid/role$queryParams'),
      headers: {'Accept': 'application/json'},
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update user role: ${response.body}');
    }
  }

  // --- Hospitals ---

  /// DATA SOURCE: ManageHospitalsScreen (Registration Form).
  /// DATA JOURNEY: Flutter -> FastAPI (/hospitals/) -> Firestore.
  Future<void> addHospital(HospitalModel hospital) async {
    final response = await http.post(
      Uri.parse('$baseUrl/hospitals/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(hospital.toJson()),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to add hospital: ${response.body}');
    }
  }

  /// DATA SOURCE: ManageHospitalsScreen (Edit Mode).
  /// DATA JOURNEY: Flutter -> FastAPI (/hospitals/{id}) -> Firestore.
  Future<void> updateHospital(String id, HospitalModel hospital) async {
    final response = await http.put(
      Uri.parse('$baseUrl/hospitals/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(hospital.toJson()),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update hospital: ${response.body}');
    }
  }

  /// DATA SOURCE: ManageHospitalsScreen (Delete Icon).
  /// DATA JOURNEY: Flutter -> FastAPI (/hospitals/{id}) -> Firestore.
  Future<void> deleteHospital(String id) async {
    final response = await http.delete(Uri.parse('$baseUrl/hospitals/$id'));

    if (response.statusCode != 200) {
      throw Exception('Failed to delete hospital: ${response.body}');
    }
  }

  /// STEP 1: Receives a text address (e.g., "123 Main St, City").
  /// STEP 2: On Web, it calls the FastAPI backend's '/geocoding' endpoint to
  ///         securely convert the address without exposing API keys in the JS bundle.
  /// STEP 3: On Mobile, it uses the 'geocoding' package to talk to system services.
  /// OUTPUT: Returns a 'Location' object (Latitude & Longitude) so the app can place a pin on the map.
  Future<Location?> getCoordinatesFromAddress(String address) async {
    if (kIsWeb) {
      try {
        final query = Uri.encodeComponent(address);
        final response = await http.get(
          Uri.parse('$baseUrl/geocoding/?address=$query'),
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          return Location(
            latitude: data['latitude'].toDouble(),
            longitude: data['longitude'].toDouble(),
            timestamp: DateTime.now(),
          );
        } else {
          print(
            'Backend Geocoding Error: ${response.statusCode} - ${response.body}',
          );
        }
      } catch (e) {
        print('Web Geocoding Error: $e');
      }
      return null;
    }

    try {
      List<Location> locations = await locationFromAddress(address);
      if (locations.isNotEmpty) {
        return locations.first;
      }
    } catch (e) {
      print('Geocoding error: $e');
    }
    return null;
  }
}
