library;

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';
import '../models/blood_request_model.dart';
import '../models/hospital_model.dart';
import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart';
import 'package:url_launcher/url_launcher.dart';

class ApiService {
  // Use http://10.0.2.2:8000 for Android Emulator
  // Use http://localhost:8000 for Web/Desktop
  // allows the app to know where the "brain" (backend) is located.
  static String get baseUrl {
    if (kIsWeb) return 'http://127.0.0.1:8000';
    return 'http://10.0.2.2:8000';
  }

  // --- Blood Requests ---
  //receive gikan sa blood request og donate blood screens
  //ihatag padung sa backend para ma save sa database
  // mo post sa blood request
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

  /// r: InventoryManagementScreen (UI TextField).
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

  /// gkan SignupScreen og profile screen.
  ///r: usermodel s: Post request dayun sa backend
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
  /// DATA JOURNEY: Flutter -> Backend (/users/{uid}/ban) -> Firestore.
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
  /// DATA JOURNEY: Flutter -> Backend (/users/{uid}/role) -> Firestore.
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
  
  /// Utility to initiate a phone call using url_launcher
  Future<void> callUser(String contactNumber) async {
    final Uri telUri = Uri.parse('tel:$contactNumber');
    if (await canLaunchUrl(telUri)) {
      await launchUrl(telUri);
    } else {
      throw 'Could not launch $telUri';
    }
  }

  ///r:profile screen and from manage hospital screen screen
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

  /// r: ManageHospitalsScreen (Edit Mode). s: Backend (/hospitals/{id}) -> Firestore.
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

  /// r: ManageHospitalsScreen (Delete Icon).
  Future<void> deleteHospital(String id) async {
    final response = await http.delete(Uri.parse('$baseUrl/hospitals/$id'));

    if (response.statusCode != 200) {
      throw Exception('Failed to delete hospital: ${response.body}');
    }
  }

  /// Receives a text address ("123 Main St, City").
  /// Returns Latitude & Longitude to pin on the map.
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
