import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/blood_request_model.dart';
import '../models/hospital_model.dart';
import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart';

class ApiService {
  // Use http://10.0.2.2:8000 for Android Emulator
  // Use http://localhost:8000 for Web/Desktop
  static String get baseUrl {
    if (kIsWeb) return 'http://localhost:8000';
    return 'http://10.0.2.2:8000';
  }

  // --- Blood Requests ---

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

  // --- Hospitals ---

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

  Future<void> deleteHospital(String id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/hospitals/$id'),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete hospital: ${response.body}');
    }
  }

  Future<Location?> getCoordinatesFromAddress(String address) async {
    if (kIsWeb) {
      try {
        final response = await http.get(
          Uri.parse('$baseUrl/geocoding/?address=${Uri.encodeComponent(address)}'),
          headers: {'Accept': 'application/json'},
        );
        
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          return Location(
            latitude: data['latitude'],
            longitude: data['longitude'],
            timestamp: DateTime.now(),
          );
        } else {
          print('Backend Geocoding Error: ${response.body}');
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
