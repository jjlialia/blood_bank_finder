/**
 * FILE: location_service.dart
 * 
 * DESCRIPTION:
 * This file handles the retrieval of administrative geographical data (Regions, Cities, Barangays)
 * specifically for the Philippines using the PSGC (Philippine Standard Geographic Code) API.
 * It is used for filtering hospitals and donors by location.
 * 
 * DATA FLOW OVERVIEW:
 * 1. RECEIVES DATA FROM: 
 *    - The PSGC Cloud API (https://psgc.cloud/api/v2).
 * 2. PROCESSING:
 *    - Fetches raw JSON data for regions, cities, and municipalities.
 *    - Filters regions based on Island Group (Luzon, Visayas, Mindanao) using hardcoded PSGC codes.
 *    - Caches results in-memory ('_cache') to avoid redundant network calls and speed up the UI.
 *    - Sorts all lists alphabetically by name for a better user experience in dropdowns.
 * 3. SENDS DATA TO:
 *    - UI Screens with location dropdowns (e.g., FindBloodBankScreen, ProfileScreen, ManageHospitalsScreen).
 * 4. OUTPUTS/RESPONSES:
 *    - Returns 'List<Map<String, dynamic>>' containing geographic details (name, code, etc.).
 * 
 * KEY COMPONENTS:
 * - islandGroupMapping: A dictionary that links major islands (Luzon/Visayas/Mindanao) to their respective region PSGC codes.
 * - _cache: A simple in-memory map to store previous API responses.
 * - getBarangays: The most granular level of location filtering in the app.
 */

import 'dart:convert';
import 'package:http/http.dart' as http;

class LocationService {
  // The external "brain" for Philippine geography.
  static const String baseUrl = 'https://psgc.cloud/api/v2';

  // In-memory cache to prevent the app from asking the internet for the same thing twice.
  final Map<String, List<Map<String, dynamic>>> _cache = {};

  // Updated with 10-digit PSGC codes for psgc.cloud v2.
  // STEP: This mapping tells the app which Region Codes belong to which Island Group.
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

  /**
   * STEP: Fetches all 17 regions of the Philippines from the API.
   */
  Future<List<Map<String, dynamic>>> getRegions() async {
    return _fetchData('/regions');
  }

  /**
   * STEP 1: Receives the island name (Luzon, Visayas, or Mindanao).
   * STEP 2: Fetches ALL regions and filters them using the 'islandGroupMapping'.
   */
  Future<List<Map<String, dynamic>>> getRegionsByIsland(String island) async {
    final allRegions = await getRegions();
    final allowedCodes = islandGroupMapping[island] ?? [];
    return allRegions.where((r) => allowedCodes.contains(r['code'])).toList();
  }

  /**
   * STEP: A helper method that finds all cities belonging to a specific island.
   * This is used for broader searches or initializing the app state.
   */
  Future<List<Map<String, dynamic>>> getCitiesByIsland(String island) async {
    // Note: psgc.cloud doesn't have a direct 'cities by island' endpoint.
    // We'll fetch all cities and filter them by the regions in that island.
    final regions = await getRegionsByIsland(island);
    final regionCodes = regions.map((r) => r['code']).toList();
    
    // Fetch all cities (this is expensive but needed for legacy initialization)
    // We'll use a large per_page to get all common cities
    final allCities = await _fetchData('/cities-municipalities?per_page=1700');
    return allCities.where((c) => regionCodes.contains(c['code']?.substring(0, 2) + '00000000')).toList();
  }

  /**
   * STEP 1: Receives a 'regionCode'.
   * STEP 2: Fetches only the cities/municipalities within that specific region.
   */
  Future<List<Map<String, dynamic>>> getCitiesAndMunicipalities(String regionCode) async {
    return _fetchData('/regions/$regionCode/cities-municipalities?per_page=100');
  }

  /**
   * STEP 1: Receives a 'cityCode'.
   * STEP 2: Fetches the most specific location data: the Barangays.
   */
  Future<List<Map<String, dynamic>>> getBarangays(String cityCode) async {
    return _fetchData('/cities-municipalities/$cityCode/barangays?per_page=500');
  }

  /**
   * CORE LOGIC: The private worker method for all API calls.
   * 1. Checks if we already have the data in '_cache'.
   * 2. If not, sends an HTTP GET request to PSGC Cloud.
   * 3. Parses the response, extracts the 'data' list.
   * 4. Sorts the names alphabetically (A-Z).
   * 5. Saves the result in cache and returns it to the caller.
   */
  Future<List<Map<String, dynamic>>> _fetchData(String endpoint) async {
    if (_cache.containsKey(endpoint)) {
      return _cache[endpoint]!;
    }

    try {
      final response = await http.get(Uri.parse('$baseUrl$endpoint'));
      if (response.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(response.body);
        final List<dynamic> data = body['data'] ?? [];
        final List<Map<String, dynamic>> results = data.cast<Map<String, dynamic>>();
        
        // Sort alphabetically by name
        results.sort((a, b) => (a['name'] as String).compareTo(b['name'] as String));
        
        _cache[endpoint] = results;
        return results;
      } else {
        throw Exception('Failed to load location data (Status: ${response.statusCode})');
      }
    } catch (e) {
      print('LocationService Error: $e');
      return [];
    }
  }
}
