/**
 * FILE: hospital_picker_sheet.dart (Shared Widget)
 * 
 * DESCRIPTION:
 * A comprehensive bottom-sheet UI for selecting a hospital facility. 
 * Supports text search and advanced geographic filtering to help 
 * users find the nearest site.
 * 
 * DATA FLOW OVERVIEW:
 * 1. RECEIVES DATA FROM: 
 *    - 'DatabaseService.streamHospitals': Fetches filtered facilities 
 *       based on selected Island, Region, or City.
 *    - 'LocationService': Populates the location filter dropdowns.
 * 2. PROCESSING:
 *    - Dynamic Querying: Updates the Firestore stream whenever a 
 *      geographic filter is changed in the GUI.
 *    - Client-side Search: Filters the resulting list locally by 
 *      Hospital Name text matching.
 * 3. SENDS DATA TO:
 *    - 'onHospitalSelected' Callback: Returns a full 'HospitalModel' 
 *       object to the requesting screen (e.g., Blood Request).
 * 4. OUTPUTS/GUI:
 *    - A scrollable, searchable list within a draggable bottom sheet.
 *    - Visual chips for active geographic filters.
 */

import 'package:flutter/material.dart';
import '../../core/models/hospital_model.dart';
import '../../core/services/database_service.dart';
import '../../core/services/location_service.dart';

class HospitalPickerSheet extends StatefulWidget {
  final Function(HospitalModel) onHospitalSelected;

  const HospitalPickerSheet({super.key, required this.onHospitalSelected});

  @override
  State<HospitalPickerSheet> createState() => _HospitalPickerSheetState();
}

class _HospitalPickerSheetState extends State<HospitalPickerSheet> {
  final DatabaseService _db = DatabaseService();
  final LocationService _locationSvc = LocationService();
  
  // STATE: Holding GUI filters.
  String _searchQuery = '';
  String? _selectedIsland;
  String? _selectedRegion;
  String? _selectedCity;
  String? _selectedBarangay;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      builder: (context, scrollController) => Column(
        children: [
          // --- GUI: Header and Filters ---
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const Text('Select Hospital', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                // INPUT: Search by name.
                TextField(
                  onChanged: (v) => setState(() => _searchQuery = v),
                  decoration: InputDecoration(hintText: 'Search Hospital Name...', prefixIcon: const Icon(Icons.search)),
                ),
                const SizedBox(height: 12),
                // GUI: Geography Filter Chips.
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(children: [
                    _buildFilterChip(label: _selectedIsland ?? 'Island', isSelected: _selectedIsland != null, onTap: () => _showLocationPicker(context, 'island')),
                    const SizedBox(width: 8),
                    _buildFilterChip(label: _selectedRegion ?? 'Region', isSelected: _selectedRegion != null, onTap: () => _showLocationPicker(context, 'region')),
                    const SizedBox(width: 8),
                    _buildFilterChip(label: _selectedCity ?? 'City', isSelected: _selectedCity != null, onTap: () => _showLocationPicker(context, 'city')),
                  ]),
                ),
              ],
            ),
          ),
          
          // --- ACTION: The Resulting List ---
          Expanded(
            child: StreamBuilder<List<HospitalModel>>(
              // STEP: Subscribing to a dynamically filtered Firestore stream.
              stream: _db.streamHospitals(
                islandGroup: _selectedIsland,
                region: _selectedRegion,
                city: _selectedCity,
                barangay: _selectedBarangay,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

                // PROCESSING: Name filtering on top of the geographic stream.
                final hospitals = (snapshot.data ?? []).where((h) => h.name.toLowerCase().contains(_searchQuery.toLowerCase())).toList();

                if (hospitals.isEmpty) return const Center(child: Text('No hospitals found.'));

                return ListView.builder(
                  controller: scrollController,
                  itemCount: hospitals.length,
                  itemBuilder: (context, index) {
                    final h = hospitals[index];
                    return ListTile(
                      leading: const CircleAvatar(child: Icon(Icons.local_hospital)),
                      title: Text(h.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('${h.barangay}, ${h.city}'),
                      onTap: () {
                        // CORE OUTPUT: Returning data to the parent.
                        widget.onHospitalSelected(h);
                        Navigator.pop(context);
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // --- UI HELPER: Location Modal Selector ---
  // Note: Internal logic omitted for brevity, handles LocationService orchestration.
  Future<void> _showLocationPicker(BuildContext context, String type) async { /* Dynamic location selection logic here */ }

  Widget _buildFilterChip({required String label, required bool isSelected, required VoidCallback onTap}) {
    return ActionChip(
      label: Text(label),
      onPressed: onTap,
      backgroundColor: isSelected ? Theme.of(context).primaryColor : Colors.white,
      labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black),
    );
  }
}
