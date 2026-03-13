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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Hospitals'),
        actions: [
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
      body: StreamBuilder<List<HospitalModel>>(
        stream: _db.streamHospitals(allowAll: true),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Error: ${snapshot.error}',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No hospitals registered.'));
          }

          final hospitals = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: hospitals.length,
            itemBuilder: (context, index) {
              final hospital = hospitals[index];
              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  title: Text(
                    hospital.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    '${hospital.city} | ${hospital.contactNumber}',
                  ),
                  onTap: () => _showHospitalDetails(hospital),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () =>
                            _showHospitalDialog(hospital: hospital),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () =>
                            _confirmDelete(hospital.id!, hospital.name),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showHospitalDialog(),
        label: const Text('Register Hospital'),
        icon: const Icon(Icons.add),
        backgroundColor: Theme.of(context).primaryColor,
      ),
    );
  }

  void _showHospitalDetails(HospitalModel hospital) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      hospital.name,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const Divider(height: 32),
              _detailRow(Icons.email, 'Email', hospital.email),
              _detailRow(
                Icons.location_on,
                'Location',
                '${hospital.barangay}, ${hospital.city}, ${hospital.islandGroup}',
              ),
              _detailRow(Icons.map, 'Address', hospital.address),
              _detailRow(Icons.phone, 'Contact', hospital.contactNumber),
              _detailRow(
                Icons.bloodtype,
                'Available Blood Types',
                hospital.availableBloodTypes.isEmpty
                    ? 'None'
                    : hospital.availableBloodTypes.join(', '),
              ),
              _detailRow(
                hospital.isActive ? Icons.check_circle : Icons.cancel,
                'Status',
                hospital.isActive ? 'Active' : 'Inactive',
                color: hospital.isActive ? Colors.green : Colors.red,
              ),
              _detailRow(
                Icons.calendar_today,
                'Registered On',
                hospital.createdAt.toString().split(' ')[0],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _showHospitalDialog(hospital: hospital);
                  },
                  icon: const Icon(Icons.edit),
                  label: const Text('Edit Hospital Info'),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 22, color: color ?? Theme.of(context).primaryColor),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(value, style: const TextStyle(fontSize: 16)),
              ],
            ),
          ),
        ],
      ),
    );
  }

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

    // Dynamic location state
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
                final fetchedRegions =
                    await _locationSvc.getRegionsByIsland(selectedIsland!);
                final fetchedCities =
                    await _locationSvc.getCitiesByIsland(selectedIsland!);

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
                    final fetchedBarangays =
                        await _locationSvc.getBarangays(cityMatch['code']);
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
                        DropdownButtonFormField<String>(
                          value: selectedIsland,
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
                              final fetchedRegions =
                                  await _locationSvc.getRegionsByIsland(v);
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
                                    value: regions.any((r) => r['code'] == regions.firstWhere((r) => r['name'] == selectedRegionName, orElse: () => {})['code'])
                                        ? regions.firstWhere((r) => r['name'] == selectedRegionName)['code']
                                        : null,
                                  decoration: const InputDecoration(
                                      labelText: 'Region'),
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
                                        (r) => r['code'] == v)['name'];
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
                                    value: cities.any((c) => c['code'] == cities.firstWhere((c) => c['name'] == selectedCity, orElse: () => {})['code'])
                                        ? cities.firstWhere((c) => c['name'] == selectedCity)['code']
                                        : null,
                                  decoration:
                                      const InputDecoration(labelText: 'City'),
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
                                        (c) => c['code'] == v)['name'];
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
                        if (barangays.isNotEmpty || isLoadingBarangays)
                          Column(
                            children: [
                              if (isLoadingBarangays)
                                const LinearProgressIndicator()
                              else
                                 DropdownButtonFormField<String>(
                                    value: barangays.any((b) => b['code'] == barangays.firstWhere((b) => b['name'] == selectedBarangay, orElse: () => {})['code'])
                                        ? barangays.firstWhere((b) => b['name'] == selectedBarangay)['code']
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
                                        (b) => b['code'] == v)['name'];
                                    setModalState(() {
                                      selectedBarangay = bName;
                                    });
                                  },
                                  validator: (v) =>
                                      v == null ? 'Required' : null,
                                ),
                              const SizedBox(height: 16),
                            ],
                          ),
                        const SizedBox(height: 16),
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
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: isGeocoding
                                ? null
                                : () async {
                                    if (selectedCity == null ||
                                        addressController.text.isEmpty) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
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
                                      print('Attempting to geocode: $query');
                                      final locations = await _api
                                          .getCoordinatesFromAddress(query);
                                      if (locations != null) {
                                        latController.text =
                                            locations.latitude.toString();
                                        lonController.text =
                                            locations.longitude.toString();
                                        if (mounted) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                              content: Text('Coordinates fetched successfully!'),
                                              backgroundColor: Colors.green,
                                            ),
                                          );
                                        }
                                      } else {
                                        if (mounted) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Could not find coordinates for this address. Try being more specific.',
                                              ),
                                              backgroundColor: Colors.red,
                                            ),
                                          );
                                        }
                                      }
                                    } catch (e) {
                                      print('Geocoding error detail: $e');
                                      if (mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content:
                                                Text('Geocoding Error: ${e.toString()}'),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
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
                              hospital.id!, updatedHospital);
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
