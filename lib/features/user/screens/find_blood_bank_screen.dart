import 'package:flutter/material.dart';
import '../../../models/hospital_model.dart';
import '../../../services/database_service.dart';
import '../../../shared/widgets/custom_text_field.dart';
import '../../../core/utils/ph_locations.dart';

class FindBloodBankScreen extends StatefulWidget {
  const FindBloodBankScreen({super.key});

  @override
  State<FindBloodBankScreen> createState() => _FindBloodBankScreenState();
}

class _FindBloodBankScreenState extends State<FindBloodBankScreen> {
  final DatabaseService _db = DatabaseService();
  String _searchQuery = '';
  String? _selectedIsland;
  String? _selectedCity;
  String? _selectedBarangay;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Find Blood Bank')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                CustomTextField(
                  label: 'Search Hospital Name',
                  prefixIcon: Icons.search,
                  onChanged: (v) => setState(() => _searchQuery = v),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedIsland,
                        decoration: const InputDecoration(
                          labelText: 'Island',
                          isDense: true,
                        ),
                        items: PhLocationData.islandGroups
                            .map(
                              (e) => DropdownMenuItem(value: e, child: Text(e)),
                            )
                            .toList(),
                        onChanged: (v) => setState(() {
                          _selectedIsland = v;
                          _selectedCity = null;
                          _selectedBarangay = null;
                        }),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedCity,
                        decoration: const InputDecoration(
                          labelText: 'City',
                          isDense: true,
                        ),
                        items:
                            (_selectedIsland == null
                                    ? []
                                    : PhLocationData.getCitiesForIsland(
                                        _selectedIsland!,
                                      ))
                                .map(
                                  (e) => DropdownMenuItem<String>(
                                    value: e,
                                    child: Text(
                                      e,
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ),
                                )
                                .toList(),
                        onChanged: (v) => setState(() {
                          _selectedCity = v;
                          _selectedBarangay = null;
                        }),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedBarangay,
                        decoration: const InputDecoration(
                          labelText: 'Barangay',
                          isDense: true,
                        ),
                        items:
                            (_selectedCity == null
                                    ? []
                                    : PhLocationData.getBarangaysForCity(
                                        _selectedCity!,
                                      ))
                                .map(
                                  (e) => DropdownMenuItem<String>(
                                    value: e,
                                    child: Text(
                                      e,
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ),
                                )
                                .toList(),
                        onChanged: (v) => setState(() => _selectedBarangay = v),
                      ),
                    ),
                    IconButton(
                      onPressed: () => setState(() {
                        _selectedIsland = null;
                        _selectedCity = null;
                        _selectedBarangay = null;
                      }),
                      icon: const Icon(Icons.clear),
                    ),
                  ],
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
                  return const Center(
                    child: Text('No hospitals found matching criteria.'),
                  );
                }

                return ListView.builder(
                  itemCount: hospitals.length,
                  itemBuilder: (context, index) {
                    final h = hospitals[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Colors.redAccent,
                          child: Icon(
                            Icons.local_hospital,
                            color: Colors.white,
                          ),
                        ),
                        title: Text(
                          h.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          '${h.city} | ${h.availableBloodTypes.join(", ")}',
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () => _showHospitalDetails(context, h),
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

  void _showHospitalDetails(BuildContext context, HospitalModel h) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(h.name, style: Theme.of(context).textTheme.titleLarge),
            const Divider(height: 32),
            _detailRow(Icons.location_on, 'Address', h.address),
            _detailRow(Icons.phone, 'Contact', h.contactNumber),
            _detailRow(Icons.email, 'Email', h.email),
            _detailRow(
              Icons.bloodtype,
              'Available',
              h.availableBloodTypes.join(", "),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.redAccent),
          const SizedBox(width: 12),
          Expanded(child: Text('$label: $value')),
        ],
      ),
    );
  }
}
