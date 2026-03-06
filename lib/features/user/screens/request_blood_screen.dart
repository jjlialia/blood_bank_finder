import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/blood_request_model.dart';
import '../../../models/hospital_model.dart';
import '../../../services/database_service.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../shared/widgets/custom_text_field.dart';
import '../../../shared/widgets/custom_button.dart';

class RequestBloodScreen extends StatefulWidget {
  const RequestBloodScreen({super.key});

  @override
  State<RequestBloodScreen> createState() => _RequestBloodScreenState();
}

class _RequestBloodScreenState extends State<RequestBloodScreen> {
  final DatabaseService _db = DatabaseService();
  late Stream<List<HospitalModel>> _hospitalsStream;
  final _formKey = GlobalKey<FormState>();

  String? _selectedBloodType;
  HospitalModel? _selectedHospital;
  final _unitsController = TextEditingController(text: '1.0');
  final _contactController = TextEditingController();
  bool _isSworn = false;

  @override
  void initState() {
    super.initState();
    _hospitalsStream = _db.streamHospitals();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Request Blood')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              DropdownButtonFormField<String>(
                initialValue: _selectedBloodType,
                items: ['A+', 'A-', 'B+', 'B-', 'O+', 'O-', 'AB+', 'AB-']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) => setState(() => _selectedBloodType = v),
                decoration: const InputDecoration(
                  labelText: 'Blood Type Needed',
                ),
              ),
              const SizedBox(height: 16),
              StreamBuilder<List<HospitalModel>>(
                stream: _hospitalsStream,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Text(
                      'Error loading hospitals: ${snapshot.error}',
                      style: const TextStyle(color: Colors.red),
                    );
                  }
                  if (!snapshot.hasData) {
                    return const CircularProgressIndicator();
                  }
                  return DropdownButtonFormField<HospitalModel>(
                    initialValue: _selectedHospital,
                    items: snapshot.data!
                        .map(
                          (h) =>
                              DropdownMenuItem(value: h, child: Text(h.name)),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => _selectedHospital = v),
                    decoration: const InputDecoration(
                      labelText: 'Request From Hospital',
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'Quantity (Units)',
                controller: _unitsController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Required';
                  final n = double.tryParse(v);
                  if (n == null || n <= 0) return 'Must be > 0';
                  return null;
                },
              ),
              CustomTextField(
                label: 'Contact Details',
                controller: _contactController,
                prefixIcon: Icons.phone,
                keyboardType: TextInputType.phone,
                validator: (v) =>
                    v == null || v.isEmpty ? 'Contact required' : null,
              ),
              const SizedBox(height: 16),
              CheckboxListTile(
                title: const Text(
                  'I solemnly swear this request is for a medical need.',
                  style: TextStyle(fontSize: 13),
                ),
                value: _isSworn,
                activeColor: Colors.redAccent,
                onChanged: (v) => setState(() => _isSworn = v ?? false),
              ),
              const SizedBox(height: 32),
              CustomButton(
                label: 'Post Emergency Request',
                onPressed: _isSworn ? () => _submitRequest(auth) : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _submitRequest(AuthProvider auth) async {
    if (_selectedHospital == null || _selectedBloodType == null) return;

    final request = BloodRequestModel(
      userId: auth.user!.uid,
      userName: '${auth.user!.firstName} ${auth.user!.lastName}',
      type: 'Request',
      bloodType: _selectedBloodType!,
      status: 'pending',
      hospitalId: _selectedHospital!.id!,
      hospitalName: _selectedHospital!.name,
      contactNumber: _contactController.text,
      quantity: double.tryParse(_unitsController.text) ?? 1.0,
      createdAt: DateTime.now(),
    );

    await _db.createBloodRequest(request);
    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Blood request posted successfully!')),
    );
  }
}
