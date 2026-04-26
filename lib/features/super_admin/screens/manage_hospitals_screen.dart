library;

import 'package:flutter/material.dart';
import '../../../core/models/hospital_model.dart';
import '../../../core/services/database_service.dart';
import '../../../core/services/api_service.dart';
import '../../../shared/widgets/custom_text_field.dart';
import '../../../core/services/location_service.dart';
import '../../../core/services/backfill_service.dart';
import '../widgets/super_admin_drawer.dart';

class ManageHospitalsScreen extends StatefulWidget {
  const ManageHospitalsScreen({super.key});

  @override
  State<ManageHospitalsScreen> createState() => _ManageHospitalsScreenState();
}

class _ManageHospitalsScreenState extends State<ManageHospitalsScreen> {
  final DatabaseService _db = DatabaseService();
  final ApiService _api = ApiService();
  final LocationService _locationSvc = LocationService();
  final BackfillService _backfillSvc = BackfillService();

  bool _isSyncing = false;
  final _formKey = GlobalKey<FormState>();
  String _searchQuery = '';
  String _statusFilter = 'All'; // All, Active, Inactive

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Hospitals'),
        actions: [
          //Sync button to update any hospitals that might have missing location metadata.
          if (_isSyncing)
            const Center(
              child: Padding(
                padding: EdgeInsets.only(right: 16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.sync),
              tooltip: 'Sync Missing Regions',
              onPressed: () async {
                setState(() => _isSyncing = true);
                final count = await _backfillSvc.syncAllHospitals();
                setState(() => _isSyncing = false);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Successfully synced $count hospitals.'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
            ),
        ],
      ),
      drawer: const SuperAdminDrawer(),
      body: Column(
        children: [
          _buildSearchAndFilter(),
          Expanded(
            child: StreamBuilder<List<HospitalModel>>(
              stream: _db.streamHospitals(allowAll: true),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No hospitals registered.'));
                }

                // Apply client-side search and filtering
                final hospitals = snapshot.data!.where((h) {
                  final matchesSearch =
                      h.name.toLowerCase().contains(
                        _searchQuery.toLowerCase(),
                      ) ||
                      h.city.toLowerCase().contains(_searchQuery.toLowerCase());

                  final matchesStatus =
                      _statusFilter == 'All' ||
                      (_statusFilter == 'Active' && h.isActive) ||
                      (_statusFilter == 'Inactive' && !h.isActive);

                  return matchesSearch && matchesStatus;
                }).toList();

                if (hospitals.isEmpty) {
                  return const Center(
                    child: Text('No matching hospitals found.'),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: hospitals.length,
                  itemBuilder: (context, index) {
                    final hospital = hospitals[index];
                    return _buildHospitalCard(hospital);
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showHospitalDialog(),
        label: const Text('Register Hospital'),
        icon: const Icon(Icons.add),
        backgroundColor: Theme.of(context).primaryColor,
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            offset: const Offset(0, 2),
            blurRadius: 4,
          ),
        ],
      ),
      child: Column(
        children: [
          TextField(
            onChanged: (v) => setState(() => _searchQuery = v),
            decoration: InputDecoration(
              hintText: 'Search hospital name or city...',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: ['All', 'Active', 'Inactive'].map((filter) {
              final isSelected = _statusFilter == filter;
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: ChoiceChip(
                  label: Text(filter),
                  selected: isSelected,
                  onSelected: (val) {
                    if (val) setState(() => _statusFilter = filter);
                  },
                  selectedColor: Theme.of(
                    context,
                  ).primaryColor.withValues(alpha: 0.2),
                  labelStyle: TextStyle(
                    color: isSelected
                        ? Theme.of(context).primaryColor
                        : Colors.grey[700],
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  
  void _displayHospitalModal(HospitalModel hospital) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          hospital.name,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Hospital ID: ${hospital.id?.substring(0, 8)}...',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _statusBadge(hospital.isActive),
                ],
              ),
              const SizedBox(height: 32),
              _detailSection('Location Information', [
                _detailItem(
                  Icons.location_on_outlined,
                  'Address',
                  hospital.address,
                ),
                _detailItem(
                  Icons.map_outlined,
                  'City/Region',
                  '${hospital.city}, ${hospital.region}',
                ),
                _detailItem(
                  Icons.explore_outlined,
                  'Coordinates',
                  '${hospital.latitude}, ${hospital.longitude}',
                ),
              ]),
              const SizedBox(height: 24),
              _detailSection('Contact Details', [
                _detailItem(
                  Icons.phone_outlined,
                  'Phone',
                  hospital.contactNumber,
                ),
                _detailItem(Icons.email_outlined, 'Email', hospital.email),
              ]),
              const SizedBox(height: 24),
              _detailSection('Inventory Snapshot', [
                _detailItem(
                  Icons.bloodtype_outlined,
                  'Available Types',
                  hospital.availableBloodTypes.isEmpty
                      ? 'No stock information available'
                      : hospital.availableBloodTypes.join(', '),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHospitalCard(HospitalModel hospital) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(top: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: InkWell(
        onTap: () => _displayHospitalModal(hospital),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.local_hospital,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          hospital.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          hospital.city,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _statusBadge(hospital.isActive),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Divider(height: 1),
              ),
              Row(
                children: [
                  _infoItem(Icons.phone_outlined, hospital.contactNumber),
                  const Spacer(),
                  _inventorySnapshot(hospital.availableBloodTypes.length),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () => _showHospitalDialog(hospital: hospital),
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text('Edit'),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: () =>
                        _confirmDelete(hospital.id!, hospital.name),
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: const Text('Remove'),
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusBadge(bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isActive ? Colors.green[50] : Colors.red[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        isActive ? 'ACTIVE' : 'INACTIVE',
        style: TextStyle(
          color: isActive ? Colors.green[700] : Colors.red[700],
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _infoItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
      ],
    );
  }

  Widget _inventorySnapshot(int typesCount) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.bloodtype_outlined, size: 14, color: Colors.blue),
          const SizedBox(width: 4),
          Text(
            '$typesCount Types Available',
            style: const TextStyle(
              color: Colors.blue,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailSection(String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: TextStyle(
            color: Colors.grey[500],
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        ...items,
      ],
    );
  }

  Widget _detailItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.blue),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(color: Colors.grey[600], fontSize: 10),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  //Calls 'api.deleteHospital(id)'.
  void _confirmDelete(String id, String name) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Hospital'),
        content: Text('Are you sure you want to remove "$name"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final navigator = Navigator.of(context);
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              await _api.deleteHospital(id);
              if (mounted) {
                navigator.pop();
                scaffoldMessenger.showSnackBar(
                  SnackBar(content: Text('$name removed successfully')),
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showHospitalDialog({HospitalModel? hospital}) {
    final isEditing = hospital != null;
    final nameController = TextEditingController(text: hospital?.name);
    final emailController = TextEditingController(text: hospital?.email);
    String? selectedIsland = hospital?.islandGroup;
    String? selectedRegionName = hospital?.region;
    String? selectedCity = hospital?.city;
    String? selectedBarangay = hospital?.barangay;
    final addressController = TextEditingController(text: hospital?.address);
    final contactController = TextEditingController(
      text: hospital?.contactNumber,
    );
    final latController = TextEditingController(
      text: hospital?.latitude.toString() ?? '0.0',
    );
    final lonController = TextEditingController(
      text: hospital?.longitude.toString() ?? '0.0',
    );
    bool isGeocoding = false;
    bool isActive = hospital?.isActive ?? true;

    // Local lists for the dropdowns
    List<Map<String, dynamic>> regions = [];
    List<Map<String, dynamic>> cities = [];
    List<Map<String, dynamic>> barangays = [];
    bool isLoadingRegions = false;
    bool isLoadingCities = false;
    bool isLoadingBarangays = false;
    bool initialized = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          if (!initialized) {
            initialized = true;
            if (isEditing && selectedIsland != null) {
              Future.microtask(() async {
                setModalState(() {
                  isLoadingRegions = true;
                  isLoadingCities = true;
                });

                final fetchedRegions = await _locationSvc.getRegionsByIsland(
                  selectedIsland!,
                );
                final fetchedCities = await _locationSvc.getCitiesByIsland(
                  selectedIsland!,
                );

                setModalState(() {
                  regions = fetchedRegions;
                  cities = fetchedCities;
                  isLoadingRegions = false;
                  isLoadingCities = false;
                });

                if (selectedCity != null) {
                  final cityMatch = fetchedCities.firstWhere(
                    (c) => c['name'] == selectedCity,
                    orElse: () => {},
                  );
                  if (cityMatch.isNotEmpty) {
                    setModalState(() => isLoadingBarangays = true);
                    final fetchedBarangays = await _locationSvc.getBarangays(
                      cityMatch['code'],
                    );
                    setModalState(() {
                      barangays = fetchedBarangays;
                      isLoadingBarangays = false;
                    });
                  }
                }
              });
            }
          }

          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isEditing ? 'Edit Hospital' : 'Register New Hospital',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        CustomTextField(
                          label: 'Hospital Name',
                          controller: nameController,
                          validator: (v) => v == null || v.isEmpty
                              ? 'Name is required'
                              : null,
                        ),
                        CustomTextField(
                          label: 'Email',
                          controller: emailController,
                          keyboardType: TextInputType.emailAddress,
                          validator: (v) {
                            if (v == null || v.isEmpty) {
                              return 'Email is required';
                            }
                            if (!RegExp(
                              r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                            ).hasMatch(v)) {
                              return 'Enter a valid email';
                            }
                            return null;
                          },
                        ),

                        // ISLAND DROPDOWN: The starting point for location selection.
                        DropdownButtonFormField<String>(
                          initialValue: selectedIsland,
                          decoration: const InputDecoration(
                            labelText: 'Island Group',
                          ),
                          items: ['Luzon', 'Visayas', 'Mindanao']
                              .map(
                                (e) =>
                                    DropdownMenuItem(value: e, child: Text(e)),
                              )
                              .toList(),
                          onChanged: (v) async {
                            setModalState(() {
                              selectedIsland = v;
                              selectedRegionName = null;
                              selectedCity = null;
                              selectedBarangay = null;
                              regions = [];
                              cities = [];
                              barangays = [];
                              isLoadingRegions = true;
                            });
                            if (v != null) {
                              final fetchedRegions = await _locationSvc
                                  .getRegionsByIsland(v);
                              setModalState(() {
                                regions = fetchedRegions;
                                isLoadingRegions = false;
                              });
                            }
                          },
                          validator: (v) => v == null ? 'Required' : null,
                        ),
                        const SizedBox(height: 16),

                        if (selectedIsland != null)
                          Column(
                            children: [
                              if (isLoadingRegions)
                                const LinearProgressIndicator()
                              else
                                DropdownButtonFormField<String>(
                                  initialValue:
                                      regions.any(
                                        (r) => r['name'] == selectedRegionName,
                                      )
                                      ? regions.firstWhere(
                                          (r) =>
                                              r['name'] == selectedRegionName,
                                        )['code']
                                      : null,
                                  decoration: const InputDecoration(
                                    labelText: 'Region',
                                  ),
                                  items: regions
                                      .map<DropdownMenuItem<String>>(
                                        (e) => DropdownMenuItem<String>(
                                          value: e['code'],
                                          child: Text(e['name']),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (v) async {
                                    final regName = regions.firstWhere(
                                      (r) => r['code'] == v,
                                    )['name'];
                                    setModalState(() {
                                      selectedRegionName = regName;
                                      selectedCity = null;
                                      selectedBarangay = null;
                                      cities = [];
                                      barangays = [];
                                      isLoadingCities = true;
                                    });
                                    if (v != null) {
                                      final fetchedCities = await _locationSvc
                                          .getCitiesAndMunicipalities(v);
                                      setModalState(() {
                                        cities = fetchedCities;
                                        isLoadingCities = false;
                                      });
                                    }
                                  },
                                  validator: (v) =>
                                      v == null ? 'Required' : null,
                                ),
                              const SizedBox(height: 16),
                            ],
                          ),

                        if (cities.isNotEmpty || isLoadingCities)
                          Column(
                            children: [
                              if (isLoadingCities)
                                const LinearProgressIndicator()
                              else
                                DropdownButtonFormField<String>(
                                  initialValue:
                                      cities.any(
                                        (c) => c['name'] == selectedCity,
                                      )
                                      ? cities.firstWhere(
                                          (c) => c['name'] == selectedCity,
                                        )['code']
                                      : null,
                                  decoration: const InputDecoration(
                                    labelText: 'City',
                                  ),
                                  items: cities
                                      .map<DropdownMenuItem<String>>(
                                        (e) => DropdownMenuItem<String>(
                                          value: e['code'],
                                          child: Text(e['name']),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (v) async {
                                    final cityName = cities.firstWhere(
                                      (c) => c['code'] == v,
                                    )['name'];
                                    setModalState(() {
                                      selectedCity = cityName;
                                      selectedBarangay = null;
                                      barangays = [];
                                      isLoadingBarangays = true;
                                    });
                                    if (v != null) {
                                      final fetchedBarangays =
                                          await _locationSvc.getBarangays(v);
                                      setModalState(() {
                                        barangays = fetchedBarangays;
                                        isLoadingBarangays = false;
                                      });
                                    }
                                  },
                                  validator: (v) =>
                                      v == null ? 'Required' : null,
                                ),
                              const SizedBox(height: 16),
                            ],
                          ),

                        // BARANGAY DROPDOWN: The most granular selection.
                        if (barangays.isNotEmpty || isLoadingBarangays)
                          Column(
                            children: [
                              if (isLoadingBarangays)
                                const LinearProgressIndicator()
                              else
                                DropdownButtonFormField<String>(
                                  initialValue:
                                      barangays.any(
                                        (b) => b['name'] == selectedBarangay,
                                      )
                                      ? barangays.firstWhere(
                                          (b) => b['name'] == selectedBarangay,
                                        )['code']
                                      : null,
                                  decoration: const InputDecoration(
                                    labelText: 'Barangay',
                                  ),
                                  items: barangays
                                      .map<DropdownMenuItem<String>>(
                                        (e) => DropdownMenuItem<String>(
                                          value: e['code'],
                                          child: Text(e['name']),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (v) {
                                    final bName = barangays.firstWhere(
                                      (b) => b['code'] == v,
                                    )['name'];
                                    setModalState(
                                      () => selectedBarangay = bName,
                                    );
                                  },
                                  validator: (v) =>
                                      v == null ? 'Required' : null,
                                ),
                              const SizedBox(height: 16),
                            ],
                          ),

                        CustomTextField(
                          label: 'Street Address',
                          controller: addressController,
                          validator: (v) => v == null || v.isEmpty
                              ? 'Address is required'
                              : null,
                        ),
                        CustomTextField(
                          label: 'Contact Number',
                          controller: contactController,
                          keyboardType: TextInputType.phone,
                          validator: (v) {
                            if (v == null || v.isEmpty) {
                              return 'Contact is required';
                            }
                            if (v.length < 7) return 'Invalid contact number';
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // COORDINATES Manual entry or auto-fetched via the 'Search' button.
                        Row(
                          children: [
                            Expanded(
                              child: CustomTextField(
                                label: 'Latitude',
                                controller: latController,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                validator: (v) => v == null || v.isEmpty
                                    ? 'Required'
                                    : double.tryParse(v) == null
                                    ? 'Invalid'
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: CustomTextField(
                                label: 'Longitude',
                                controller: lonController,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                validator: (v) => v == null || v.isEmpty
                                    ? 'Required'
                                    : double.tryParse(v) == null
                                    ? 'Invalid'
                                    : null,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // GEOCREATION ACTIO
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: isGeocoding
                                ? null
                                : () async {
                                    if (selectedCity == null ||
                                        addressController.text.isEmpty) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Please enter address and city first',
                                          ),
                                          backgroundColor: Colors.orange,
                                        ),
                                      );
                                      return;
                                    }
                                    setModalState(() => isGeocoding = true);
                                    try {
                                      final query =
                                          '${addressController.text}, ${selectedBarangay ?? ""}, $selectedCity, Philippines';
                                      final locations = await _api
                                          .getCoordinatesFromAddress(query);
                                      if (locations != null) {
                                        latController.text = locations.latitude
                                            .toString();
                                        lonController.text = locations.longitude
                                            .toString();
                                        if (mounted) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Coordinates fetched successfully!',
                                              ),
                                              backgroundColor: Colors.green,
                                            ),
                                          );
                                        }
                                      }
                                    } finally {
                                      setModalState(() => isGeocoding = false);
                                    }
                                  },
                            icon: isGeocoding
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.location_searching),
                            label: Text(
                              isGeocoding
                                  ? 'Fetching...'
                                  : 'Fetch Coordinates from Address',
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        SwitchListTile(
                          title: const Text('Active Status'),
                          subtitle: Text(
                            isActive
                                ? 'Hospital is searchable'
                                : 'Hospital is hidden',
                          ),
                          value: isActive,
                          onChanged: (v) => setModalState(() => isActive = v),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (!_formKey.currentState!.validate()) return;
                        final updatedHospital = HospitalModel(
                          id: hospital?.id,
                          name: nameController.text,
                          email: emailController.text,
                          islandGroup: selectedIsland!,
                          region: selectedRegionName ?? 'Unknown',
                          city: selectedCity!,
                          barangay: selectedBarangay!,
                          address: addressController.text,
                          contactNumber: contactController.text,
                          latitude: double.tryParse(latController.text) ?? 0.0,
                          longitude: double.tryParse(lonController.text) ?? 0.0,
                          availableBloodTypes:
                              hospital?.availableBloodTypes ?? [],
                          isActive: isActive,
                          createdAt: hospital?.createdAt ?? DateTime.now(),
                        );
                        final navigator = Navigator.of(context);
                        final scaffoldMessenger = ScaffoldMessenger.of(context);
                        if (isEditing) {
                          await _api.updateHospital(
                            hospital.id!,
                            updatedHospital,
                          );
                        } else {
                          await _api.addHospital(updatedHospital);
                        }
                        if (mounted) {
                          navigator.pop();
                          scaffoldMessenger.showSnackBar(
                            SnackBar(
                              content: Text(
                                isEditing
                                    ? 'Hospital updated successfully'
                                    : 'Hospital registered successfully',
                              ),
                            ),
                          );
                        }
                      },
                      child: Text(isEditing ? 'Save Changes' : 'Register'),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
