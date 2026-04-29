import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../hospital/domain/entities/hospital.dart';
import '../presentation/providers/hospital_provider.dart';
import '../../../shared/widgets/custom_text_field.dart';
import '../../../core/services/location_service.dart';
import '../widgets/hospital_admin_drawer.dart';
import '../widgets/no_hospital_assigned.dart';

class HospitalProfileScreen extends StatefulWidget {
  const HospitalProfileScreen({super.key});

  @override
  State<HospitalProfileScreen> createState() => _HospitalProfileScreenState();
}

class _HospitalProfileScreenState extends State<HospitalProfileScreen> {
  final LocationService _locationSvc = LocationService();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = true;
  HospitalEntity? _hospital;

  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _addressController;
  late TextEditingController _contactController;
  late TextEditingController _latController;
  late TextEditingController _lonController;
  String? _selectedIsland;
  String? _selectedRegion;
  String? _selectedCity;
  String? _selectedBarangay;
  bool _isActive = true;

  List<Map<String, dynamic>> _regions = [];
  List<Map<String, dynamic>> _cities = [];
  List<Map<String, dynamic>> _barangays = [];
  bool _isLoadingRegions = false;
  bool _isLoadingCities = false;
  bool _isLoadingBarangays = false;

  @override
  void initState() {
    super.initState();
    _loadHospital();
  }

  Future<void> _loadHospital() async {
    final auth = context.read<AuthProvider>();
    final hospitalProvider = context.read<HospitalProvider>();
    final hospitalId = auth.user?.hospitalId;

    if (hospitalId != null && hospitalId.isNotEmpty) {
      final h = await hospitalProvider.getHospital(hospitalId);
      if (h != null) {
        final regions = await _locationSvc.getRegionsByIsland(h.islandGroup);
        final currentRegion = regions.firstWhere(
          (r) => r['name'] == h.region,
          orElse: () => {},
        );

        List<Map<String, dynamic>> cities = [];
        if (currentRegion.isNotEmpty) {
          cities = await _locationSvc.getCitiesAndMunicipalities(
            currentRegion['code'],
          );
        }

        final cityMatch = cities.firstWhere(
          (c) => c['name'] == h.city,
          orElse: () => {},
        );

        List<Map<String, dynamic>> barangays = [];
        if (cityMatch.isNotEmpty) {
          barangays = await _locationSvc.getBarangays(cityMatch['code']);
        }

        setState(() {
          _hospital = h;
          _nameController = TextEditingController(text: h.name);
          _emailController = TextEditingController(text: h.email);
          _addressController = TextEditingController(text: h.address);
          _contactController = TextEditingController(text: h.contactNumber);
          _latController = TextEditingController(text: h.latitude.toString());
          _lonController = TextEditingController(text: h.longitude.toString());
          _selectedIsland = h.islandGroup;
          _selectedRegion = currentRegion['code'];
          _selectedCity = cityMatch['code'];
          _selectedBarangay = barangays.firstWhere(
            (b) => b['name'] == h.barangay,
            orElse: () => {},
          )['code'];
          _regions = regions;
          _cities = cities;
          _barangays = barangays;
          _isActive = h.isActive;
          _isLoading = false;
        });
        return;
      }
    }
    setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _contactController.dispose();
    _latController.dispose();
    _lonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_hospital == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Hospital Profile')),
        drawer: const HospitalAdminDrawer(),
        body: const NoHospitalAssigned(),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Manage Hospital Profile')),
      drawer: const HospitalAdminDrawer(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Edit Hospital Information',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              CustomTextField(
                label: 'Hospital Name',
                controller: _nameController,
                validator: (v) =>
                    v == null || v.isEmpty ? 'Name is required' : null,
              ),
              CustomTextField(
                label: 'Email',
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Email is required';
                  if (!RegExp(
                    r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                  ).hasMatch(v)) {
                    return 'Enter a valid email';
                  }
                  return null;
                },
              ),
              DropdownButtonFormField<String>(
                value: _selectedIsland,
                decoration: const InputDecoration(labelText: 'Island Group'),
                items: ['Luzon', 'Visayas', 'Mindanao']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) async {
                  setState(() {
                    _selectedIsland = v;
                    _selectedRegion = null;
                    _selectedCity = null;
                    _selectedBarangay = null;
                    _regions = [];
                    _cities = [];
                    _barangays = [];
                    _isLoadingRegions = true;
                  });

                  if (v != null) {
                    final fetched = await _locationSvc.getRegionsByIsland(v);
                    setState(() {
                      _regions = fetched;
                      _isLoadingRegions = false;
                    });
                  }
                },
                validator: (v) => v == null ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              if (_isLoadingRegions)
                const LinearProgressIndicator()
              else if (_selectedIsland != null)
                DropdownButtonFormField<String>(
                  value: _selectedRegion,
                  decoration: const InputDecoration(labelText: 'Region'),
                  items: _regions
                      .map(
                        (e) => DropdownMenuItem<String>(
                          value: e['code'],
                          child: Text(e['name']),
                        ),
                      )
                      .toList(),
                  onChanged: (v) async {
                    setState(() {
                      _selectedRegion = v;
                      _selectedCity = null;
                      _selectedBarangay = null;
                      _cities = [];
                      _barangays = [];
                      _isLoadingCities = true;
                    });

                    if (v != null) {
                      final fetched = await _locationSvc
                          .getCitiesAndMunicipalities(v);
                      setState(() {
                        _cities = fetched;
                        _isLoadingCities = false;
                      });
                    }
                  },
                  validator: (v) => v == null ? 'Required' : null,
                ),
              const SizedBox(height: 16),
              if (_isLoadingCities)
                const LinearProgressIndicator()
              else if (_selectedRegion != null)
                DropdownButtonFormField<String>(
                  value: _selectedCity,
                  decoration: const InputDecoration(labelText: 'City'),
                  items: _cities
                      .map(
                        (e) => DropdownMenuItem<String>(
                          value: e['code'],
                          child: Text(e['name']),
                        ),
                      )
                      .toList(),
                  onChanged: (v) async {
                    setState(() {
                      _selectedCity = v;
                      _selectedBarangay = null;
                      _barangays = [];
                      _isLoadingBarangays = true;
                    });

                    if (v != null) {
                      final fetched = await _locationSvc.getBarangays(v);
                      setState(() {
                        _barangays = fetched;
                        _isLoadingBarangays = false;
                      });
                    }
                  },
                  validator: (v) => v == null ? 'Required' : null,
                ),
              const SizedBox(height: 16),
              if (_isLoadingBarangays)
                const LinearProgressIndicator()
              else if (_selectedCity != null)
                DropdownButtonFormField<String>(
                  value: _selectedBarangay,
                  decoration: const InputDecoration(labelText: 'Barangay'),
                  items: _barangays
                      .map(
                        (e) => DropdownMenuItem<String>(
                          value: e['code'],
                          child: Text(e['name']),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => _selectedBarangay = v),
                  validator: (v) => v == null ? 'Required' : null,
                ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'Street Address',
                controller: _addressController,
                validator: (v) =>
                    v == null || v.isEmpty ? 'Address is required' : null,
              ),
              CustomTextField(
                label: 'Contact Number',
                controller: _contactController,
                keyboardType: TextInputType.phone,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Contact is required';
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
                      controller: _latController,
                      keyboardType: const TextInputType.numberWithOptions(
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
                      controller: _lonController,
                      keyboardType: const TextInputType.numberWithOptions(
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
              SwitchListTile(
                title: const Text('Active Status'),
                subtitle: Text(
                  _isActive
                      ? 'Your hospital is searchable by users'
                      : 'Your hospital is currently hidden from search',
                ),
                value: _isActive,
                onChanged: (v) => setState(() => _isActive = v),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                  ),
                  child: const Text(
                    'Update Hospital Profile',
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    final hospitalProvider = context.read<HospitalProvider>();

    final updated = HospitalEntity(
      id: _hospital!.id,
      name: _nameController.text,
      email: _emailController.text,
      islandGroup: _selectedIsland!,
      region: _regions.firstWhere((r) => r['code'] == _selectedRegion)['name'],
      city: _cities.firstWhere((c) => c['code'] == _selectedCity)['name'],
      barangay: _barangays.firstWhere(
        (b) => b['code'] == _selectedBarangay,
      )['name'],
      address: _addressController.text,
      contactNumber: _contactController.text,
      latitude: double.tryParse(_latController.text) ?? 0.0,
      longitude: double.tryParse(_lonController.text) ?? 0.0,
      availableBloodTypes: _hospital!.availableBloodTypes,
      isActive: _isActive,
      createdAt: _hospital!.createdAt,
    );

    await hospitalProvider.updateHospital(updated);
    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Hospital profile updated!')));
  }
}
