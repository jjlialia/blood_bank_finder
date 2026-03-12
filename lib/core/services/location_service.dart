import 'dart:convert';
import 'package:http/http.dart' as http;

class LocationService {
  static const String baseUrl = 'https://psgc.cloud/api/v2';

  // In-memory cache
  final Map<String, List<Map<String, dynamic>>> _cache = {};

  // Updated with 10-digit PSGC codes for psgc.cloud v2
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

  Future<List<Map<String, dynamic>>> getRegions() async {
    return _fetchData('/regions');
  }

  Future<List<Map<String, dynamic>>> getRegionsByIsland(String island) async {
    final allRegions = await getRegions();
    final allowedCodes = islandGroupMapping[island] ?? [];
    return allRegions.where((r) => allowedCodes.contains(r['code'])).toList();
  }

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

  Future<List<Map<String, dynamic>>> getCitiesAndMunicipalities(String regionCode) async {
    return _fetchData('/regions/$regionCode/cities-municipalities?per_page=100');
  }

  Future<List<Map<String, dynamic>>> getBarangays(String cityCode) async {
    return _fetchData('/cities-municipalities/$cityCode/barangays?per_page=500');
  }

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
