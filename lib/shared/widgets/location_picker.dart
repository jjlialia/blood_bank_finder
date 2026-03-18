/**
 * FILE: location_picker.dart (Shared Widget)
 * 
 * DESCRIPTION:
 * A cascading selection widget specialized for Philippine geographic 
 * hierarchy (Island -> Region -> City -> Barangay). 
 * 
 * DATA FLOW OVERVIEW:
 * 1. RECEIVES DATA FROM: 
 *    - 'LocationService': Fetches JSON-based location data from the 
 *      PSGC (Philippine Standard Geographic Code).
 * 2. PROCESSING:
 *    - Cascading Logic: Selecting an Island triggers a 'Region' fetch. 
 *      Selecting a Region triggers a 'City' fetch, etc.
 *    - State Reset: Whenever a parent selection changes, all child 
 *      selections are cleared to maintain data integrity.
 * 3. SENDS DATA TO:
 *    - 'onLocationChanged' Callback: Bubbles the selected names (not codes) 
 *      up to the parent screen (e.g., Signup or Hospital Registration).
 * 4. OUTPUTS/GUI:
 *    - A column of 4 Dropdown fields, with loading indicators during 
 *      asynchronous API/JSON fetches.
 */

import 'package:flutter/material.dart';
import '../../core/services/location_service.dart';

class PhLocationPicker extends StatefulWidget {
  // Callback: Returns the human-readable text for the full address.
  final Function(String? island, String? region, String? city, String? barangay) onLocationChanged;

  const PhLocationPicker({super.key, required this.onLocationChanged});

  @override
  State<PhLocationPicker> createState() => _PhLocationPickerState();
}

class _PhLocationPickerState extends State<PhLocationPicker> {
  final LocationService _locationSvc = LocationService();
  
  // STATE: Holding the current selections (names and internal codes).
  String? _selectedIsland;
  String? _selectedRegion;
  String? _selectedCity;
  String? _selectedBarangay;

  List<Map<String, dynamic>> _regions = [];
  List<Map<String, dynamic>> _cities = [];
  List<Map<String, dynamic>> _barangays = [];
  
  bool _isLoadingRegions = false;
  bool _isLoadingCities = false;
  bool _isLoadingBarangays = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // STEP 1: Island Selection (Manual)
        DropdownButtonFormField<String>(
          value: _selectedIsland,
          decoration: const InputDecoration(labelText: 'Island Group'),
          items: ['Luzon', 'Visayas', 'Mindanao'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: (v) async {
            // Logic: Wipe child state and trigger next fetch.
            widget.onLocationChanged(v, null, null, null);
            setState(() {
              _selectedIsland = v; _selectedRegion = null; _selectedCity = null; _selectedBarangay = null;
              _regions = []; _cities = []; _barangays = []; _isLoadingRegions = true;
            });
            if (v != null) {
              final fetched = await _locationSvc.getRegionsByIsland(v);
              setState(() { _regions = fetched; _isLoadingRegions = false; });
            }
          },
        ),
        const SizedBox(height: 16),

        // STEP 2: Region Selection (Fetched based on Island)
        if (_isLoadingRegions) const LinearProgressIndicator() 
        else if (_selectedIsland != null)
          DropdownButtonFormField<String>(
            value: _selectedRegion,
            decoration: const InputDecoration(labelText: 'Region'),
            items: _regions.map((e) => DropdownMenuItem<String>(value: e['code'], child: Text(e['name']))).toList(),
            onChanged: (v) async {
              final regionName = _regions.firstWhere((r) => r['code'] == v)['name'];
              setState(() { _selectedRegion = v; _selectedCity = null; _selectedBarangay = null; _isLoadingCities = true; });
              widget.onLocationChanged(_selectedIsland, regionName, null, null);
              if (v != null) {
                final fetched = await _locationSvc.getCitiesAndMunicipalities(v);
                setState(() { _cities = fetched; _isLoadingCities = false; });
              }
            },
          ),
        const SizedBox(height: 16),

        // STEP 3: City Selection (Fetched based on Region)
        if (_isLoadingCities) const LinearProgressIndicator()
        else if (_selectedRegion != null)
          DropdownButtonFormField<String>(
            value: _selectedCity,
            decoration: const InputDecoration(labelText: 'City / Municipality'),
            items: _cities.map((e) => DropdownMenuItem<String>(value: e['code'], child: Text(e['name']))).toList(),
            onChanged: (v) async {
              final cityName = _cities.firstWhere((c) => c['code'] == v)['name'];
              final regionName = _regions.firstWhere((r) => r['code'] == _selectedRegion)['name'];
              setState(() { _selectedCity = v; _selectedBarangay = null; _isLoadingBarangays = true; });
              widget.onLocationChanged(_selectedIsland, regionName, cityName, null);
              if (v != null) {
                final fetched = await _locationSvc.getBarangays(v);
                setState(() { _barangays = fetched; _isLoadingBarangays = false; });
              }
            },
          ),
        const SizedBox(height: 16),

        // STEP 4: Barangay Selection (Fetched based on City)
        if (_isLoadingBarangays) const LinearProgressIndicator()
        else if (_selectedCity != null)
          DropdownButtonFormField<String>(
            value: _selectedBarangay,
            decoration: const InputDecoration(labelText: 'Barangay'),
            items: _barangays.map((e) => DropdownMenuItem<String>(value: e['code'], child: Text(e['name']))).toList(),
            onChanged: (v) {
              final bName = _barangays.firstWhere((b) => b['code'] == v)['name'];
              final regionName = _regions.firstWhere((r) => r['code'] == _selectedRegion)['name'];
              final cityName = _cities.firstWhere((c) => c['code'] == _selectedCity)['name'];
              setState(() => _selectedBarangay = v);
              // CORE OUTPUT: Full location string emitted.
              widget.onLocationChanged(_selectedIsland, regionName, cityName, bName);
            },
          ),
      ],
    );
  }
}
