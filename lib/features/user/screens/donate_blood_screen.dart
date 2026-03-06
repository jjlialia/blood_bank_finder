import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/blood_request_model.dart';
import '../../../models/hospital_model.dart';
import '../../../services/database_service.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../shared/widgets/custom_text_field.dart';

class DonateBloodScreen extends StatefulWidget {
  const DonateBloodScreen({super.key});

  @override
  State<DonateBloodScreen> createState() => _DonateBloodScreenState();
}

class _DonateBloodScreenState extends State<DonateBloodScreen> {
  final DatabaseService _db = DatabaseService();
  late Stream<List<HospitalModel>> _hospitalsStream;
  int _currentStep = 0;
  String? _selectedBloodType;
  HospitalModel? _selectedHospital;
  final _unitsController = TextEditingController(text: '1.0');
  final _contactController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
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
      appBar: AppBar(title: const Text('Donate Blood')),
      body: Stepper(
        type: StepperType.vertical,
        currentStep: _currentStep,
        onStepContinue: () {
          if (_currentStep == 2) {
            if (!_formKey.currentState!.validate()) return;
          }

          if (_currentStep < 3) {
            setState(() => _currentStep++);
          } else {
            _submitDonation(auth);
          }
        },
        onStepCancel: () {
          if (_currentStep > 0) setState(() => _currentStep--);
        },
        steps: [
          Step(
            title: const Text('Select Blood Type'),
            isActive: _currentStep >= 0,
            content: DropdownButtonFormField<String>(
              initialValue: _selectedBloodType,
              items: [
                'A+',
                'A-',
                'B+',
                'B-',
                'O+',
                'O-',
                'AB+',
                'AB-',
              ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (v) => setState(() => _selectedBloodType = v),
              decoration: const InputDecoration(labelText: 'Your Blood Type'),
            ),
          ),
          Step(
            title: const Text('Select Hospital'),
            isActive: _currentStep >= 1,
            content: StreamBuilder<List<HospitalModel>>(
              stream: _hospitalsStream,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Text(
                    'Error loading hospitals: ${snapshot.error}',
                    style: const TextStyle(color: Colors.red),
                  );
                }
                if (!snapshot.hasData) return const CircularProgressIndicator();
                final hospitals = snapshot.data!;
                return DropdownButtonFormField<HospitalModel>(
                  initialValue: _selectedHospital,
                  items: hospitals
                      .map(
                        (h) => DropdownMenuItem(value: h, child: Text(h.name)),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => _selectedHospital = v),
                  decoration: const InputDecoration(
                    labelText: 'Where to donate?',
                  ),
                );
              },
            ),
          ),
          Step(
            title: const Text('Details'),
            isActive: _currentStep >= 2,
            content: Form(
              key: _formKey,
              child: Column(
                children: [
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
                    label: 'Contact Number',
                    controller: _contactController,
                    prefixIcon: Icons.phone,
                    keyboardType: TextInputType.phone,
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Contact required' : null,
                  ),
                ],
              ),
            ),
          ),
          Step(
            title: const Text('Declaration'),
            isActive: _currentStep >= 3,
            content: CheckboxListTile(
              title: const Text(
                'I swear that the information provided is true.',
              ),
              value: _isSworn,
              onChanged: (v) => setState(() => _isSworn = v ?? false),
            ),
          ),
        ],
      ),
    );
  }

  void _submitDonation(AuthProvider auth) async {
    if (!_isSworn || _selectedHospital == null || _selectedBloodType == null) {
      return;
    }

    final request = BloodRequestModel(
      userId: auth.user!.uid,
      userName: '${auth.user!.firstName} ${auth.user!.lastName}',
      type: 'Donate',
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
      const SnackBar(content: Text('Donation request submitted!')),
    );
  }
}
