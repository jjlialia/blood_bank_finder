library;

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/models/hospital_model.dart';
import '../../../core/services/database_service.dart';
import '../../../core/services/location_service.dart';
import '../../../core/services/api_service.dart';
import '../widgets/hospital_map_view.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../chat/services/chat_service.dart';
import '../../chat/screens/chat_room_screen.dart';

class FindBloodBankScreen extends StatefulWidget {
  const FindBloodBankScreen({super.key});

  @override
  State<FindBloodBankScreen> createState() => _FindBloodBankScreenState();
}

class _FindBloodBankScreenState extends State<FindBloodBankScreen> {
  // SERVICE TOOLS: Our links to the backend and data sources.
  final DatabaseService _db = DatabaseService();
  final LocationService _locationSvc = LocationService();
  final ApiService _api = ApiService();

  // LOCAL STATE: Things that change as the user interacts with the GUI.
  String _searchQuery = '';
  String? _selectedIsland;
  String? _selectedRegion;
  String? _selectedCity;
  String? _selectedBarangay;
  bool _isMapView = false; // Toggles between the list and the map.
  LatLng? _mapCenter;
  double _mapZoom = 12;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Find Blood Bank'),
        actions: [
          // STEP: User taps this to switch between visual Map and text List.
          IconButton(
            icon: Icon(_isMapView ? Icons.list : Icons.map),
            onPressed: () => setState(() => _isMapView = !_isMapView),
            tooltip: _isMapView ? 'Show List' : 'Show Map',
          ),
        ],
      ),
      body: Column(
        children: [
          // --- TOP SECTION: SEARCH & FILTERS ---
          // Here, the user provides INPUT that determines what data we see.
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // SEARCH BAR: Receives text input from the user.
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
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
                // FILTER CHIPS: Trigger location pickers for hierarchical selection.
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
          // --- MAIN SECTION: DATA DISPLAY ---
          // This uses StreamBuilder to reactively show data from Firestore.
          Expanded(
            child: StreamBuilder<List<HospitalModel>>(
              // STEP: We send our location filters to the Database Service.
              stream: _db.streamHospitals(
                islandGroup: _selectedIsland,
                region: _selectedRegion,
                city: _selectedCity,
                barangay: _selectedBarangay,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                // STEP: We further filter the database results based on the Search Text.
                final hospitals = (snapshot.data ?? [])
                    .where(
                      (h) => h.name.toLowerCase().contains(
                        _searchQuery.toLowerCase(),
                      ),
                    )
                    .toList();

                if (hospitals.isEmpty) {
                  // Even if empty, we might show an empty Map.
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

                // GUI STEP: Use IndexedStack to keep both Map and List alive but only show one.
                return IndexedStack(
                  index: _isMapView ? 1 : 0,
                  children: [
                    // --- LIST VIEW ---
                    ListView.builder(
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
                            subtitle: Text(h.city),
                            trailing: const Icon(
                              Icons.arrow_forward_ios,
                              size: 16,
                            ),
                            onTap: () => _showHospitalDetails(context, h),
                          ),
                        );
                      },
                    ),
                    // --- MAP VIEW ---
                    // Passes the data to the interactive Map Widget.
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

  /// GUI STEP: Shows a bottom sheet with detailed hospital info when selected.
  /// Receives a 'HospitalModel' to display its properties (address, email, etc.).
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
            const SizedBox(height: 24),
            // OPTION: User can jump from the details directly to the Map location.
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _mapCenter = LatLng(h.latitude, h.longitude);
                    _mapZoom = 15;
                    _isMapView = true;
                  });
                  Navigator.pop(context);
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
                  
                  final chatService = ChatService();
                  final chatId = await chatService.createOrGetChat(
                    auth.user!.uid, 
                    h.id!,
                    {
                      auth.user!.uid: auth.user!.firstName,
                      h.id!: h.name,
                    }
                  );
                  // Close bottom sheet
                  if (!context.mounted) return;
                  Navigator.pop(context);
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

  // --- UI HELPER: Reusable row for details ---
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

  // --- UI HELPER: The Filter Chip visual widget ---
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
                    color: theme.primaryColor.withValues(alpha: 0.3),
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

  /// STEP 1: Receives the 'type' of location to pick (e.g., 'region').
  /// STEP 2: Asks 'LocationService' for the specific list of places.
  /// STEP 3: Displays a selectable list to the user.
  /// STEP 4: When picked, updates local state and tells the Map to fly to that place.
  Future<void> _showLocationPicker(BuildContext context, String type) async {
    List<String> items = [];
    String title = '';
    bool isLoading = true;

    // Logic to determine which list to fetch based on previous selections.
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

    // DATA FLOW: Calling external services to populate the selection list.
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

    // GUI: Present the choices to the user.
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
                // Option to Clear filters.
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
                    // STEP: Update the local state with the user's choice.
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
                    // STEP: Immediately move the map to this new area.
                    _updateMapLocation(type, item);
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

  /// DATA FLOW: Converting a text location into Map coordinates.
  /// 1. Receives the area name (e.g., "Cebu City").
  /// 2. Formats it into a searchable address string.
  /// 3. Sends it to 'ApiService.getCoordinatesFromAddress'.
  /// 4. Receives back a Lat/Lng.
  /// 5. Updates state to move the Map camera.
  Future<void> _updateMapLocation(String type, String itemName) async {
    String query = '';
    double targetZoom = 12.0;

    if (type == 'island') {
      query = '$itemName Island, Philippines';
      targetZoom = 6.0;
    } else if (type == 'region') {
      query = '$itemName, $_selectedIsland Island, Philippines';
      targetZoom = 8.0;
    } else if (type == 'city') {
      query = '$itemName, $_selectedRegion, Philippines';
      targetZoom = 12.0;
    } else if (type == 'barangay') {
      query = 'Barangay $itemName, $_selectedCity, Philippines';
      targetZoom = 15.0;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Locating $itemName...'),
        duration: const Duration(seconds: 1),
      ),
    );

    final loc = await _api.getCoordinatesFromAddress(query);
    if (loc != null && mounted) {
      setState(() {
        _mapCenter = LatLng(loc.latitude, loc.longitude);
        _mapZoom = targetZoom;
      });
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not find exact coordinates, map unchanged.'),
        ),
      );
    }
  }
}

/// FILE: find_blood_bank_screen.dart
///
/// DESCRIPTION:
/// This screen is the main interface for users to locate blood banks and hospitals.
/// It provides both a List View and a Map View, with advanced filtering by
/// geographical location (Island, Region, City, Barangay) and name search.
///
/// DATA FLOW OVERVIEW:
/// 1. RECEIVES DATA FROM:
///    - 'DatabaseService.streamHospitals': A real-time stream of all active hospitals.
///    - 'LocationService': Provides the lists of Islands, Regions, Cities, etc., for the filter chips.
///    - 'ApiService.getCoordinatesFromAddress': Fetches Lat/Lng to move the map when a location is selected.
/// 2. PROCESSING:
///    - Local State Management: Tracks search queries, selected filters, and Map/List toggle.
///    - Filtering Logic: Client-side filtering of the hospital stream based on the 'searchQuery'.
///    - Coordinate Conversion: When a user selects a City, it asks the API for coordinates to center the map there.
/// 3. SENDS DATA TO:
///    - 'HospitalMapView': Passes the filtered list of hospitals and map center to the custom map widget.
///    - Hospital Detail Modal: Displays specific hospital data when a user taps a card or marker.
/// 4. OUTPUTS/GUI:
///    - A searchable, filterable list of cards or interactive map pins.
