import 'package:flutter/material.dart';
import '../../../models/hospital_model.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import '../../../services/database_service.dart';
import '../../../core/providers/location_provider.dart';

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
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LocationProvider>().fetchIslandGroups();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Find Blood Bank')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: TextField(
                    onChanged: (v) => setState(() => _searchQuery = v),
                    decoration: InputDecoration(
                      hintText: 'Search Hospital or Location...',
                      prefixIcon: const Icon(Icons.search),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
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
                        leading: CircleAvatar(
                          backgroundColor: Theme.of(context).primaryColor,
                          child: const Icon(
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
              child: ElevatedButton.icon(
                onPressed: () async {
                  final url = Uri.parse(
                    'https://www.google.com/maps/search/?api=1&query=${h.latitude},${h.longitude}',
                  );
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url);
                  } else {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Could not open map')),
                      );
                    }
                  }
                },
                icon: const Icon(Icons.map),
                label: const Text('Show on Map'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
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
          Icon(icon, size: 20, color: Theme.of(context).primaryColor),
          const SizedBox(width: 12),
          Expanded(child: Text('$label: $value')),
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
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: theme.primaryColor.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
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

  void _showLocationPicker(BuildContext context, String type) async {
    final locationProvider = context.read<LocationProvider>();
    List<String> items = [];
    String title = '';

    if (type == 'island') {
      items = locationProvider.islandGroups;
      title = 'Select Island';
    } else if (type == 'city') {
      if (_selectedIsland == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select an Island first')),
        );
        return;
      }
      items = await locationProvider.getCities(_selectedIsland!);
      title = 'Select City';
    } else if (type == 'barangay') {
      if (_selectedCity == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a City first')),
        );
        return;
      }
      items = await locationProvider.getBarangays(_selectedCity!);
      title = 'Select Barangay';
    }

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
      ),
    );
  }
}
