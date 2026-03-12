import 'package:flutter/material.dart';
import '../../core/models/hospital_model.dart';
import '../../core/services/database_service.dart';
import '../../core/utils/ph_locations.dart';

class HospitalPickerSheet extends StatefulWidget {
  final Function(HospitalModel) onHospitalSelected;

  const HospitalPickerSheet({super.key, required this.onHospitalSelected});

  @override
  State<HospitalPickerSheet> createState() => _HospitalPickerSheetState();
}

class _HospitalPickerSheetState extends State<HospitalPickerSheet> {
  final DatabaseService _db = DatabaseService();
  String _searchQuery = '';
  String? _selectedIsland;
  String? _selectedCity;
  String? _selectedBarangay;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) => Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Text(
                  'Select Hospital',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  onChanged: (v) => setState(() => _searchQuery = v),
                  decoration: InputDecoration(
                    hintText: 'Search Hospital Name...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip(
                        label: _selectedIsland ?? 'Island Group',
                        isSelected: _selectedIsland != null,
                        onTap: () => _showLocationPicker(context, 'island'),
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
          Expanded(
            child: StreamBuilder<List<HospitalModel>>(
              stream: _db.streamHospitals(
                islandGroup: _selectedIsland,
                city: _selectedCity,
                barangay: _selectedBarangay,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final hospitals = (snapshot.data ?? [])
                    .where(
                      (h) => h.name.toLowerCase().contains(
                        _searchQuery.toLowerCase(),
                      ),
                    )
                    .toList();

                if (hospitals.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 64,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No hospitals found in this location.',
                          style: TextStyle(color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: hospitals.length,
                  itemBuilder: (context, index) {
                    final h = hospitals[index];
                    return Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: Colors.grey.shade200),
                      ),
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(12),
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: theme.primaryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.local_hospital,
                            color: theme.primaryColor,
                          ),
                        ),
                        title: Text(
                          h.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text('${h.barangay}, ${h.city}'),
                        onTap: () {
                          widget.onHospitalSelected(h);
                          Navigator.pop(context);
                        },
                      ),
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

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? theme.primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? theme.primaryColor : Colors.grey.shade300,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey.shade700,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 13,
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 4),
              const Icon(Icons.close, size: 14, color: Colors.white),
            ],
          ],
        ),
      ),
    );
  }

  void _showLocationPicker(BuildContext context, String type) {
    List<String> items = [];
    String title = '';

    if (type == 'island') {
      items = PhLocationData.islandGroups;
      title = 'Select Island Group';
    } else if (type == 'city') {
      if (_selectedIsland == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select an Island Group first')),
        );
        return;
      }
      items = PhLocationData.getCitiesForIsland(_selectedIsland!);
      title = 'Select City';
    } else if (type == 'barangay') {
      if (_selectedCity == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a City first')),
        );
        return;
      }
      items = PhLocationData.getBarangaysForCity(_selectedCity!);
      title = 'Select Barangay';
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
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
        );
      },
    );
  }
}
