import 'package:flutter/material.dart';
import '../../services/database_service.dart';

class LocationProvider with ChangeNotifier {
  final DatabaseService _db = DatabaseService();

  List<String> _islandGroups = [];
  Map<String, List<String>> _cities = {};
  Map<String, List<String>> _barangays = {};

  bool _isLoading = false;

  List<String> get islandGroups => _islandGroups;
  bool get isLoading => _isLoading;

  Future<void> fetchIslandGroups() async {
    if (_islandGroups.isNotEmpty) return;
    _isLoading = true;
    notifyListeners();
    _islandGroups = await _db.getIslandGroups();
    _isLoading = false;
    notifyListeners();
  }

  Future<List<String>> getCities(String islandGroup) async {
    if (_cities.containsKey(islandGroup)) return _cities[islandGroup]!;
    final cities = await _db.getCities(islandGroup);
    _cities[islandGroup] = cities;
    return cities;
  }

  Future<List<String>> getBarangays(String city) async {
    if (_barangays.containsKey(city)) return _barangays[city]!;
    final barangays = await _db.getBarangays(city);
    _barangays[city] = barangays;
    return barangays;
  }
}
