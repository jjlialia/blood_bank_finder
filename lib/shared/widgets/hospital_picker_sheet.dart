library;

import 'package:flutter/material.dart';
import '../../core/models/hospital_model.dart';
import '../../core/services/database_service.dart';
import '../../core/services/location_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class HospitalPickerSheet extends StatefulWidget {
  final Function(HospitalModel) onHospitalSelected;

  const HospitalPickerSheet({super.key, required this.onHospitalSelected});

  @override
  State<HospitalPickerSheet> createState() => _HospitalPickerSheetState();
}

class _HospitalPickerSheetState extends State<HospitalPickerSheet> {
  final DatabaseService _db = DatabaseService();
  final LocationService _locationSvc = LocationService();

  String _searchQuery = '';
  String? _selectedIsland;
  String? _selectedRegion;
  String? _selectedCity;
  String? _selectedBarangay;
  Position? _userPosition;

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  Future<void> _initLocation() async {
    try {
      final pos = await _locationSvc.getCurrentPosition();
      if (mounted) {
        setState(() => _userPosition = pos);
      }
    } catch (e) {
      debugPrint('Error getting location for picker: $e');
    }
  }

  double _calculateDistance(double lat, double lng) {
    if (_userPosition == null) return 0;
    const distance = Distance();
    return distance.as(
      LengthUnit.Kilometer,
      LatLng(_userPosition!.latitude, _userPosition!.longitude),
      LatLng(lat, lng),
    );
  }

  @override
  Widget build(BuildContext context) {
    

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      builder: (context, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            //Header and Filters
            Container(
              padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const Text(
                  'Select Hospital',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                //Search by name.
                TextField(
                  onChanged: (v) => setState(() => _searchQuery = v),
                  decoration: InputDecoration(
                    hintText: 'Search Hospital Name...',
                    prefixIcon: const Icon(Icons.search),
                  ),
                ),
                const SizedBox(height: 12),
                //  Geography Filter Chips.
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip(
                        label: _selectedIsland ?? 'Island',
                        isSelected: _selectedIsland != null,
                        onTap: () => _showLocationPicker(context, 'island'),
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        label: _selectedRegion ?? 'Region',
                        isSelected: _selectedRegion != null,
                        onTap: () => _showLocationPicker(context, 'region'),
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        label: _selectedCity ?? 'City',
                        isSelected: _selectedCity != null,
                        onTap: () => _showLocationPicker(context, 'city'),
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        label: _selectedBarangay ?? 'Barangay',
                        isSelected: _selectedBarangay != null,
                        onTap: () => _showLocationPicker(context, 'barangay'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // action: The Resulting List
          Expanded(
            child: StreamBuilder<List<HospitalModel>>(
              //Subscribing to a dynamically filtered Firestore stream.
              stream: _db.streamHospitals(
                islandGroup: _selectedIsland,
                region: _selectedRegion,
                city: _selectedCity,
                barangay: _selectedBarangay,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting)
                  return const Center(child: CircularProgressIndicator());

                // processing: Name filtering on top of the geographic stream.
                final hospitals = (snapshot.data ?? [])
                    .where(
                      (h) => h.name.toLowerCase().contains(
                        _searchQuery.toLowerCase(),
                      ),
                    )
                    .toList();

                // SORT BY DISTANCE if GPS is available
                if (_userPosition != null) {
                  hospitals.sort((a, b) {
                    final distA = _calculateDistance(a.latitude, a.longitude);
                    final distB = _calculateDistance(b.latitude, b.longitude);
                    return distA.compareTo(distB);
                  });
                }

                if (hospitals.isEmpty)
                  return const Center(child: Text('No hospitals found.'));

                return Column(
                  children: [
                    if (_userPosition != null && hospitals.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Row(
                          children: [
                            Icon(Icons.near_me, size: 14, color: Theme.of(context).primaryColor),
                            const SizedBox(width: 6),
                            Text(
                              'Showing nearest hospitals to you',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    Expanded(
                      child: ListView.builder(
                        controller: scrollController,
                        itemCount: hospitals.length,
                        itemBuilder: (context, index) {
                    final h = hospitals[index];
                    final distance = _calculateDistance(h.latitude, h.longitude);

                    return ListTile(
                      leading: const CircleAvatar(
                        child: Icon(Icons.local_hospital),
                      ),
                      title: Text(
                        h.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${h.barangay}, ${h.city}'),
                          if (_userPosition != null)
                            Text(
                              '${distance.toStringAsFixed(1)} km away',
                              style: TextStyle(
                                color: Theme.of(context).primaryColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                        ],
                      ),
                      onTap: () {
                        //Returning data to the parent.
                        widget.onHospitalSelected(h);
                        Navigator.pop(context);
                      },
                    );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    ],
  ),
),
);
}

  // --- UI HELPER: Location Modal Selector ---
  // Note: Internal logic omitted for brevity, handles LocationService orchestration.
  Future<void> _showLocationPicker(BuildContext context, String type) async {
    List<String> items = [];
    String title = '';
    bool isLoading = true;

    if (type == 'island') {
      items = ['Luzon', 'Visayas', 'Mindanao'];
      title = 'Select Island';
      isLoading = false;
    } else if (type == 'region') {
      if (_selectedIsland == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select an Island first')),
        );
        return;
      }
      title = 'Select Region';
    } else if (type == 'city') {
      if (_selectedRegion == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a Region first')),
        );
        return;
      }
      title = 'Select City';
    } else if (type == 'barangay') {
      if (_selectedCity == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a City first')),
        );
        return;
      }
      title = 'Select Barangay';
    }

    if (isLoading) {
      if (type == 'region') {
        final fetched = await _locationSvc.getRegionsByIsland(_selectedIsland!);
        items = fetched.map((e) => e['name'] as String).toList();
      } else if (type == 'city') {
        final islandRegions = await _locationSvc.getRegionsByIsland(
          _selectedIsland!,
        );
        final regMatch = islandRegions.firstWhere(
          (r) => r['name'] == _selectedRegion,
          orElse: () => {},
        );
        if (regMatch.isNotEmpty) {
          final fetched = await _locationSvc.getCitiesAndMunicipalities(
            regMatch['code'],
          );
          items = fetched.map((e) => e['name'] as String).toList();
        }
      } else if (type == 'barangay') {
        final islandRegions = await _locationSvc.getRegionsByIsland(
          _selectedIsland!,
        );
        final regMatch = islandRegions.firstWhere(
          (r) => r['name'] == _selectedRegion,
          orElse: () => {},
        );
        if (regMatch.isNotEmpty) {
          final regionCities = await _locationSvc.getCitiesAndMunicipalities(
            regMatch['code'],
          );
          final cityMatch = regionCities.firstWhere(
            (c) => c['name'] == _selectedCity,
            orElse: () => {},
          );
          if (cityMatch.isNotEmpty) {
            final fetched = await _locationSvc.getBarangays(cityMatch['code']);
            items = fetched.map((e) => e['name'] as String).toList();
          }
        }
      }
      isLoading = false;
    }

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          const Divider(),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: items.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return ListTile(
                    title: const Text('All / Clear'),
                    onTap: () {
                      setState(() {
                        if (type == 'island') {
                          _selectedIsland = null;
                          _selectedRegion = null;
                          _selectedCity = null;
                          _selectedBarangay = null;
                        } else if (type == 'region') {
                          _selectedRegion = null;
                          _selectedCity = null;
                          _selectedBarangay = null;
                        } else if (type == 'city') {
                          _selectedCity = null;
                          _selectedBarangay = null;
                        } else {
                          _selectedBarangay = null;
                        }
                      });
                      Navigator.pop(context);
                    },
                  );
                }
                final item = items[index - 1];
                return ListTile(
                  title: Text(item),
                  onTap: () {
                    setState(() {
                      if (type == 'island') {
                        _selectedIsland = item;
                        _selectedRegion = null;
                        _selectedCity = null;
                        _selectedBarangay = null;
                      } else if (type == 'region') {
                        _selectedRegion = item;
                        _selectedCity = null;
                        _selectedBarangay = null;
                      } else if (type == 'city') {
                        _selectedCity = item;
                        _selectedBarangay = null;
                      } else {
                        _selectedBarangay = item;
                      }
                    });
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return ActionChip(
      label: Text(label),
      onPressed: onTap,
      backgroundColor: isSelected
          ? Theme.of(context).primaryColor
          : Colors.white,
      labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black),
    );
  }
}

/// FILE: hospital_picker_sheet.dart (Shared Widget)
///
/// DESCRIPTION:
/// A comprehensive bottom-sheet UI for selecting a hospital facility.
/// Supports text search and advanced geographic filtering to help
/// users find the nearest site.
///
/// DATA FLOW OVERVIEW:
/// 1. RECEIVES DATA FROM:
///    - 'DatabaseService.streamHospitals': Fetches filtered facilities
///       based on selected Island, Region, or City.
///    - 'LocationService': Populates the location filter dropdowns.
/// 2. PROCESSING:
///    - Dynamic Querying: Updates the Firestore stream whenever a
///      geographic filter is changed in the GUI.
///    - Client-side Search: Filters the resulting list locally by
///      Hospital Name text matching.
/// 3. SENDS DATA TO:
///    - 'onHospitalSelected' Callback: Returns a full 'HospitalModel'
///       object to the requesting screen (e.g., Blood Request).
/// 4. OUTPUTS/GUI:
///    - A scrollable, searchable list within a draggable bottom sheet.
///    - Visual chips for active geographic filters.
