import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../../hospital/domain/entities/hospital.dart';
import '../../hospital/presentation/providers/hospital_provider.dart';
import '../../../core/services/location_service.dart';
import '../widgets/hospital_map_view.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../chat/presentation/providers/chat_provider.dart';
import '../../chat/screens/chat_room_screen.dart';
import '../../hospital/domain/entities/inventory.dart';

class FindBloodBankScreen extends StatefulWidget {
  const FindBloodBankScreen({super.key});

  @override
  State<FindBloodBankScreen> createState() => _FindBloodBankScreenState();
}

class _FindBloodBankScreenState extends State<FindBloodBankScreen> {
  final LocationService _locationSvc = LocationService();

  String _searchQuery = '';
  String? _selectedIsland;
  String? _selectedRegion;
  String? _selectedCity;
  String? _selectedBarangay;
  String? _selectedBloodType; 
  bool _isMapView = false; 
  LatLng? _mapCenter;
  double _mapZoom = 12;
  Position? _userPosition;


  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  Future<void> _initLocation() async {
    final pos = await _locationSvc.getCurrentPosition();
    if (mounted) {
      setState(() => _userPosition = pos);
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
    final hospitalProvider = context.read<HospitalProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Find Blood Bank'),
        actions: [
          IconButton(
            icon: Icon(_isMapView ? Icons.list : Icons.map),
            onPressed: () => setState(() => _isMapView = !_isMapView),
            tooltip: _isMapView ? 'Show List' : 'Show Map',
          ),
        ],
      ),
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
                    decoration: const InputDecoration(
                      hintText: 'Search Hospital or Location...',
                      prefixIcon: Icon(Icons.search),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Availability Filter:',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      ['A+', 'A-', 'B+', 'B-', 'O+', 'O-', 'AB+', 'AB-']
                          .map((type) => Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: _buildFilterChip(
                                  label: type,
                                  isSelected: _selectedBloodType == type,
                                  onTap: () {
                                    setState(() {
                                      if (_selectedBloodType == type) {
                                        _selectedBloodType = null;
                                      } else {
                                        _selectedBloodType = type;
                                      }
                                    });
                                  },
                                ),
                              ))
                          .toList()
                    ].expand((i) => i).toList(),
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

          Expanded(
            child: StreamBuilder<List<HospitalEntity>>(
              stream: hospitalProvider.streamHospitals(
                islandGroup: _selectedIsland,
                region: _selectedRegion,
                city: _selectedCity,
                barangay: _selectedBarangay,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final hospitals = (snapshot.data ?? [])
                    .where((h) {
                      final matchesSearch = h.name.toLowerCase().contains(
                        _searchQuery.toLowerCase(),
                      );
                      final matchesBlood =
                          _selectedBloodType == null ||
                          h.availableBloodTypes.contains(_selectedBloodType);
                      return matchesSearch && matchesBlood;
                    })
                    .toList();

                if (_userPosition != null) {
                  hospitals.sort((a, b) {
                    final distA = _calculateDistance(a.latitude, a.longitude);
                    final distB = _calculateDistance(b.latitude, b.longitude);
                    return distA.compareTo(distB);
                  });
                }

                if (hospitals.isEmpty) {
                  if (_isMapView) {
                    return HospitalMapView(
                      hospitals: const [],
                      initialCenter: _mapCenter,
                      initialZoom: _mapZoom,
                      onHospitalTap: (_) {},
                    );
                  }
                  return const Center(
                    child: Text('No hospitals found matching criteria.'),
                  );
                }

                return IndexedStack(
                  index: _isMapView ? 1 : 0,
                  children: [
                    Column(
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
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(h.city),
                                      if (_userPosition != null)
                                        Text(
                                          '${_calculateDistance(h.latitude, h.longitude).toStringAsFixed(1)} km away',
                                          style: TextStyle(
                                            color: Theme.of(context).primaryColor,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                    ],
                                  ),
                                  trailing: const Icon(
                                    Icons.arrow_forward_ios,
                                    size: 16,
                                  ),
                                  onTap: () => _showHospitalDetails(context, h),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    HospitalMapView(
                      hospitals: hospitals,
                      initialCenter: _mapCenter,
                      initialZoom: _mapZoom,
                      onHospitalTap: (h) => _showHospitalDetails(context, h),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }


  void _showHospitalDetails(BuildContext context, HospitalEntity h) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.92,
        builder: (_, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: Theme.of(
                      context,
                    ).primaryColor.withOpacity(0.12),
                    child: Icon(
                      Icons.local_hospital,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          h.name,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (_userPosition != null)
                          Text(
                            '${_calculateDistance(h.latitude, h.longitude).toStringAsFixed(1)} km away',
                            style: TextStyle(
                              color: Theme.of(context).primaryColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 28),
              _detailRow(Icons.location_on, 'Address', h.address),
              _detailRow(Icons.phone, 'Contact', h.contactNumber),
              _detailRow(Icons.email, 'Email', h.email),
              const SizedBox(height: 20),
              Row(
                children: [
                  Icon(
                    Icons.bloodtype,
                    size: 20,
                    color: Theme.of(context).primaryColor,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Live Blood Inventory',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (h.id != null)
                Consumer<HospitalProvider>(
                  builder: (context, hospitalProvider, _) => StreamBuilder<List<InventoryEntity>>(
                    stream: hospitalProvider.streamInventory(h.id!),
                    builder: (context, snap) {
                      if (snap.connectionState == ConnectionState.waiting) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      final inventory = snap.data ?? [];
                      if (inventory.isEmpty) {
                        return Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'No inventory data available for this hospital.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey),
                          ),
                        );
                      }
                      const order = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];
                      inventory.sort((a, b) {
                        final ai = order.indexOf(a.bloodType);
                        final bi = order.indexOf(b.bloodType);
                        return (ai == -1 ? 99 : ai).compareTo(bi == -1 ? 99 : bi);
                      });
                      final latestUpdate = inventory
                          .map((e) => e.lastUpdated)
                          .reduce((a, b) => a.isAfter(b) ? a : b);
                      final updatedStr =
                          '${latestUpdate.day}/${latestUpdate.month}/${latestUpdate.year}'
                          '  ${latestUpdate.hour.toString().padLeft(2, '0')}:'
                          '${latestUpdate.minute.toString().padLeft(2, '0')}';
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  mainAxisSpacing: 8,
                                  crossAxisSpacing: 8,
                                  childAspectRatio: 2.6,
                                ),
                            itemCount: inventory.length,
                            itemBuilder: (context, i) {
                              final item = inventory[i];
                              final available = item.units > 0;
                              final isLow = item.isLowStock;
                              final color = available
                                  ? (isLow ? Colors.orange.shade600 : Colors.green.shade600)
                                  : Colors.red.shade700;
                              final bgColor = available
                                  ? (isLow ? Colors.orange.shade50 : Colors.green.shade50)
                                  : Colors.red.shade50;
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: bgColor,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: color.withOpacity(0.4),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Text(
                                      item.bloodType,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                        color: color,
                                      ),
                                    ),
                                    const Spacer(),
                                    Icon(
                                      available ? Icons.check_circle : Icons.cancel,
                                      size: 14,
                                      color: color,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      available ? '${item.units} u' : 'None',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: color,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              _legendDot(Colors.green.shade600, 'Available'),
                              const SizedBox(width: 12),
                              _legendDot(Colors.orange.shade600, 'Low (≤5)'),
                              const SizedBox(width: 12),
                              _legendDot(Colors.red.shade400, 'Empty'),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Updated: $updatedStr',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                )
              else
                const Text(
                  'Hospital ID missing — inventory unavailable.',
                  style: TextStyle(color: Colors.grey),
                ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _mapCenter = LatLng(h.latitude, h.longitude);
                      _mapZoom = 15;
                      _isMapView = true;
                    });
                    Navigator.pop(ctx);
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
                child: ElevatedButton.icon(
                  onPressed: () async {
                    if (h.id == null) return;
                    final auth = context.read<AuthProvider>();
                    if (auth.user == null) return;

                    final chatProvider = context.read<ChatProvider>();
                    final chatId = await chatProvider.createOrGetChat(
                      auth.user!.uid,
                      h.id!,
                      {auth.user!.uid: auth.user!.firstName, h.id!: h.name},
                    );
                    if (!context.mounted) return;
                    Navigator.pop(ctx);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatRoomScreen(
                          chatRoomId: chatId,
                          otherParticipantName: h.name,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.chat),
                  label: const Text('Message Hospital'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Theme.of(context).primaryColor,
                    side: BorderSide(color: Theme.of(context).primaryColor),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Close'),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
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
                  onTap: () async {
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

                    final searchStr = [
                      _selectedBarangay,
                      _selectedCity,
                      _selectedRegion,
                      _selectedIsland,
                      'Philippines'
                    ].where((e) => e != null).join(', ');

                    final coords = await _locationSvc.getCoordinatesFromAddress(searchStr);
                    if (coords != null) {
                      setState(() {
                        _mapCenter = LatLng(coords.latitude, coords.longitude);
                        _mapZoom = type == 'barangay' ? 15 : (type == 'city' ? 13 : 10);
                      });
                    }

                    if (mounted) Navigator.pop(context);
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
