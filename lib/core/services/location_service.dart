library;

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';

class LocationService {
  // ang external brain for Philippine geography.
  static const String baseUrl = 'https://psgc.cloud/api/v2';

  /// Fetches current GPS position of the user.
  /// Handles permission checks and service status.
  Future<Position?> getCurrentPosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return null;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return null;
    }

    // When we reach here, permissions are granted and we can
    // continue accessing the position of the device.
    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  // In-memory cache to prevent the app from asking the internet for the same thing twice.
  final Map<String, List<Map<String, dynamic>>> _cache = {};

  static const Map<String, List<String>> islandGroupMapping = {
    'Luzon': [
      '1300000000', // NCR
      '1400000000', // CAR
      '0100000000', // Reg I
      '0200000000', // Reg II
      '0300000000', // Reg III
      '0400000000', // Reg IV-A
      '1700000000', // MIMAROPA
      '0500000000', // Reg V
    ],
    'Visayas': [
      '0600000000', // Reg VI
      '0700000000', // Reg VII
      '0800000000', // Reg VIII
    ],
    'Mindanao': [
      '0900000000', // Reg IX
      '1000000000', // Reg X
      '1100000000', // Reg XI
      '1200000000', // Reg XII
      '1600000000', // Reg XIII (Caraga)
      '1900000000', // BARMM
    ],
  };

  /// r:  PSGC Cloud API (/regions). s: Internal Cache / `getRegionsByIsland`.
  Future<List<Map<String, dynamic>>> getRegions() async {
    return _fetchData('/regions');
  }

  ///r: `getRegions` / `islandGroupMapping`.s: UI Dropdowns (Signup/Hospitals).
  /// rr: (Luzon, Visayas, or Mindanao).
  Future<List<Map<String, dynamic>>> getRegionsByIsland(String island) async {
    final allRegions = await getRegions();
    final allowedCodes = islandGroupMapping[island] ?? [];
    return allRegions.where((r) => allowedCodes.contains(r['code'])).toList();
  }

  /// r: PSGC Cloud API (/cities-municipalities). s: UI Dropdowns / `BackfillService`.
  Future<List<Map<String, dynamic>>> getCitiesByIsland(String island) async {
    final regions = await getRegionsByIsland(island);
    final regionCodes = regions.map((r) => r['code']).toList();

    final allCities = await _fetchData('/cities-municipalities?per_page=1700');
    return allCities
        .where(
          (c) => regionCodes.contains(c['code']?.substring(0, 2) + '00000000'),
        )
        .toList();
  }

  /// r: PSGC Cloud API (/regions/{code}/cities-municipalities). s: UI Dropdowns (Cascading Logic).
  Future<List<Map<String, dynamic>>> getCitiesAndMunicipalities(
    String regionCode,
  ) async {
    return _fetchData(
      '/regions/$regionCode/cities-municipalities?per_page=100',
    );
  }

  /// r: PSGC Cloud API (/cities-municipalities/{code}/barangays). s: UI Dropdowns (Cascading Logic).
  Future<List<Map<String, dynamic>>> getBarangays(String cityCode) async {
    return _fetchData(
      '/cities-municipalities/$cityCode/barangays?per_page=500',
    );
  }

  /// CORE LOGIC: The private worker method for all API calls.
  /// r: `_cache` (In-memory) OR PSGC Cloud API. s: `_cache` (Persistence) and the requesting Method.
  Future<List<Map<String, dynamic>>> _fetchData(String endpoint) async {
    if (_cache.containsKey(endpoint)) {
      return _cache[endpoint]!;
    }

    try {
      final response = await http.get(Uri.parse('$baseUrl$endpoint'));
      if (response.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(response.body);
        final List<dynamic> data = body['data'] ?? [];
        final List<Map<String, dynamic>> results = data
            .cast<Map<String, dynamic>>();

        // Sort alphabetically by name
        results.sort(
          (a, b) => (a['name'] as String).compareTo(b['name'] as String),
        );

        _cache[endpoint] = results;
        return results;
      } else {
        throw Exception(
          'Failed to load location data (Status: ${response.statusCode})',
        );
      }
    } catch (e) {
      print('LocationService Error: $e');
      return [];
    }
  }
}
