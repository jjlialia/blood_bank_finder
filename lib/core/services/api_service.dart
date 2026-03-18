/**
 * FILE: api_service.dart
 * 
 * DESCRIPTION:
 * This file serves as the central communication hub between the Flutter frontend and the FastAPI backend.
 * It manages all outbound HTTP requests for data persistence and administrative actions that require
 * server-side logic (like banning users or updating roles).
 * 
 * DATA FLOW OVERVIEW:
 * 1. RECEIVES DATA FROM: 
 *    - UI Screens (e.g., RequestBloodScreen, DonateBloodScreen, ManageHospitalsScreen) in the form of 
 *      Model objects (UserModel, BloodRequestModel, HospitalModel) or primitive types (strings, IDs).
 * 2. PROCESSING:
 *    - Encodes data into JSON format using 'jsonEncode'.
 *    - Constructs dynamic URLs with query parameters for specific API endpoints.
 *    - Handles platform-specific base URLs (AVD vs. Web).
 * 3. SENDS DATA TO:
 *    - FastAPI Backend (running on localhost:8000 or 10.0.2.2:8000).
 * 4. OUTPUTS/RESPONSES:
 *    - Returns 'void' for most operations, throwing 'Exception' if the server returns a non-success status code.
 *    - Returns 'Location' objects for geocoding requests.
 * 
 * KEY COMPONENTS:
 * - baseUrl: Determines the API's root address based on the running platform.
 * - CRUD Operations: Methods for creating, updating, and deleting blood requests, users, and hospitals.
 * - Geocoding: Converts physical addresses to geographic coordinates (lat/lng) for map integration.
 */

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

  /**
   * STEP 1: Receives a 'BloodRequestModel' from the RequestBloodScreen.
   * STEP 2: Encodes the request data into a JSON string.
   * STEP 3: Sends a POST request to the '/blood-requests/' endpoint on the FastAPI server.
   * STEP 4: FastAPI then saves this data into the Firebase Firestore database.
   */
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

  /**
   * STEP 1: Receives 'requestId', 'status', and an optional 'adminMessage' from Admin screens.
   * STEP 2: Constructs a URL with query parameters to tell the server WHICH request to update and HOW.
   * STEP 3: Sends a PATCH request to the server.
   * STEP 4: Output: The request status is updated in Firestore, and the user might be notified.
   */
  Future<void> updateRequestStatus(String requestId, String status, {String? adminMessage}) async {
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

  /**
   * STEP 1: Receives hospital ID, blood type, and the number of units to add/subtract.
   * STEP 2: Sends a PUT request to the specific hospital's inventory endpoint.
   * STEP 3: FastAPI updates the specific inventory document in Firestore.
   */
  Future<void> updateInventory(
    String hospitalId,
    String bloodType,
    double units,
  ) async {
    final response = await http.put(
      Uri.parse('$baseUrl/hospitals/$hospitalId/inventory/$bloodType?units=$units'),
      headers: {'Accept': 'application/json'},
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update inventory: ${response.body}');
    }
  }

  // --- Users ---

  /**
   * STEP 1: Receives a 'UserModel' containing user profile data (name, email, etc.).
   * STEP 2: Sends a POST request to '/users/'.
   * STEP 3: FastAPI ensures the user exists in Firestore and updates their info if necessary.
   */
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

  /**
   * STEP 1: Receives the user's unique 'uid' and a boolean 'isBanned'.
   * STEP 2: Sends a PATCH request to the server to restrict or restore user access.
   */
  Future<void> toggleUserBan(String uid, bool isBanned) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/users/$uid/ban?is_banned=$isBanned'),
      headers: {'Accept': 'application/json'},
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update ban status: ${response.body}');
    }
  }

  /**
   * STEP 1: Receives UID, the new 'role' (e.g., 'hospital_admin'), and an optional 'hospitalId'.
   * STEP 2: Sends a PATCH request to promote or demote a user.
   * STEP 3: Output: User permissions are updated in the system.
   */
  Future<void> updateUserRole(String uid, String role, {String? hospitalId}) async {
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

  /**
   * STEP 1: Receives a 'HospitalModel' from the Super Admin's "Add Hospital" screen.
   * STEP 2: Sends a POST request to '/hospitals/'.
   * STEP 3: FastAPI creates a new hospital record in Firestore.
   */
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

  /**
   * STEP 1: Receives the hospital ID and updated 'HospitalModel' data.
   * STEP 2: Sends a PUT request to update the hospital's details (address, contact, etc.).
   */
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

  /**
   * STEP 1: Receives the hospital ID to be removed.
   * STEP 2: Sends a DELETE request to effectively remove the hospital from the platform.
   */
  Future<void> deleteHospital(String id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/hospitals/$id'),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete hospital: ${response.body}');
    }
  }

  /**
   * STEP 1: Receives a text address (e.g., "123 Main St, City").
   * STEP 2: Depending on the platform (Web vs Mobile), it uses different geocoding methods.
   * STEP 3: On Web, it calls the Google Maps Geocoding API directly.
   * STEP 4: On Mobile, it uses the 'geocoding' package to talk to system services.
   * STEP 5: OUTPUT: Returns a 'Location' object (Latitude & Longitude) so the app can place a pin on the map.
   */
  Future<Location?> getCoordinatesFromAddress(String address) async {
    if (kIsWeb) {
      try {
        const String apiKey = 'AIzaSyATOwPz7vmqd5SgaCorsCLHCC4_yqeA7VQ';
        final query = Uri.encodeComponent(address);
        final url = 'https://maps.googleapis.com/maps/api/geocode/json?address=$query&key=$apiKey';
        
        final response = await http.get(Uri.parse(url));
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data['status'] == 'OK') {
            final loc = data['results'][0]['geometry']['location'];
            return Location(
              latitude: loc['lat'].toDouble(),
              longitude: loc['lng'].toDouble(),
              timestamp: DateTime.now(),
            );
          } else {
            print('Google Geocoding API Error: ${data['status']}');
          }
        } else {
          print('HTTP error fetching coordinates: ${response.statusCode}');
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
