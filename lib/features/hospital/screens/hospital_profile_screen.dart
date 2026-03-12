import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../models/hospital_model.dart';
import '../../../services/database_service.dart';
import '../../../shared/widgets/custom_text_field.dart';
import '../../../core/utils/ph_locations.dart';
import '../widgets/hospital_admin_drawer.dart';
import '../widgets/no_hospital_assigned.dart';

class HospitalProfileScreen extends StatefulWidget {
  const HospitalProfileScreen({super.key});

  @override
  State<HospitalProfileScreen> createState() => _HospitalProfileScreenState();
}

class _HospitalProfileScreenState extends State<HospitalProfileScreen> {
  final DatabaseService _db = DatabaseService();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = true;
  HospitalModel? _hospital;

  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _addressController;
  late TextEditingController _contactController;
  String? _selectedIsland;
  String? _selectedCity;
  String? _selectedBarangay;
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    _loadHospital();
  }

  Future<void> _loadHospital() async {
    final auth = context.read<AuthProvider>();
    final hospitalId = auth.user?.hospitalId;

    if (hospitalId != null && hospitalId.isNotEmpty) {
      final h = await _db.getHospital(hospitalId);
      if (h != null) {
        setState(() {
          _hospital = h;
          _nameController = TextEditingController(text: h.name);
          _emailController = TextEditingController(text: h.email);
          _addressController = TextEditingController(text: h.address);
          _contactController = TextEditingController(text: h.contactNumber);
          _selectedIsland = h.islandGroup;
          _selectedCity = h.city;
          _selectedBarangay = h.barangay;
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
                initialValue: _selectedIsland,
                decoration: const InputDecoration(labelText: 'Island Group'),
                items: PhLocationData.islandGroups
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) {
                  setState(() {
                    _selectedIsland = v;
                    _selectedCity = null;
                    _selectedBarangay = null;
                  });
                },
                validator: (v) => v == null ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              if (_selectedIsland != null)
                DropdownButtonFormField<String>(
                  initialValue: _selectedCity,
                  decoration: const InputDecoration(labelText: 'City'),
                  items: PhLocationData.getCitiesForIsland(_selectedIsland!)
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (v) {
                    setState(() {
                      _selectedCity = v;
                      _selectedBarangay = null;
                    });
                  },
                  validator: (v) => v == null ? 'Required' : null,
                ),
              const SizedBox(height: 16),
              if (_selectedCity != null)
                DropdownButtonFormField<String>(
                  initialValue: _selectedBarangay,
                  decoration: const InputDecoration(labelText: 'Barangay'),
                  items: PhLocationData.getBarangaysForCity(_selectedCity!)
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
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

    final updated = HospitalModel(
      id: _hospital!.id,
      name: _nameController.text,
      email: _emailController.text,
      islandGroup: _selectedIsland!,
      city: _selectedCity!,
      barangay: _selectedBarangay!,
      address: _addressController.text,
      contactNumber: _contactController.text,
      latitude: _hospital!.latitude,
      longitude: _hospital!.longitude,
      availableBloodTypes: _hospital!.availableBloodTypes,
      isActive: _isActive,
      createdAt: _hospital!.createdAt,
    );

    await _db.updateHospital(_hospital!.id!, updated);
    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Hospital profile updated!')));
  }
}
