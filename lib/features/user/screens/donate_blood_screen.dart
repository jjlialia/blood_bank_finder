library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/models/blood_request_model.dart';
import '../../../core/models/hospital_model.dart';
import '../../../core/services/api_service.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../shared/widgets/custom_text_field.dart';
import '../../../shared/widgets/hospital_picker_sheet.dart';

class DonateBloodScreen extends StatefulWidget {
  const DonateBloodScreen({super.key});

  @override
  State<DonateBloodScreen> createState() => _DonateBloodScreenState();
}

class _DonateBloodScreenState extends State<DonateBloodScreen> {
  //
  int _currentStep = 0;
  String? _selectedBloodType;
  HospitalModel? _selectedHospital;
  final _unitsController = TextEditingController(text: '1.0');
  final _contactController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  // must be all TRUE to proceed.
  bool _isSworn = false;
  bool _ageOk = false;
  bool _weightOk = false;
  bool _travelOk = false;
  bool _medsOk = false;
  bool _wellOk = false;

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Donate Blood')),
      body: Stepper(
        type: StepperType.vertical,
        currentStep: _currentStep,
        onStepContinue: () {
          //  Validation for Eligibility Quiz.
          if (_currentStep == 0) {
            if (!(_ageOk && _weightOk && _travelOk && _medsOk && _wellOk)) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('You must meet all eligibility criteria.'),
                  backgroundColor: Colors.red,
                ),
              );
              return;
            }
          }
          // Validation Gate for Details Form.
          if (_currentStep == 3) {
            if (!_formKey.currentState!.validate()) return;
          }

          if (_currentStep < 5) {
            setState(() => _currentStep++);
          } else {
            // Submit the gathered data to the server.
            _submitDonation(auth);
          }
        },
        onStepCancel: () {
          if (_currentStep > 0) setState(() => _currentStep--);
        },
        steps: [
          // Health Screening.
          Step(
            title: const Text('Eligibility Quiz'),
            isActive: _currentStep >= 0,
            content: Column(
              children: [
                CheckboxListTile(
                  title: const Text('Are you between 18-65 years old?'),
                  value: _ageOk,
                  onChanged: (v) => setState(() => _ageOk = v ?? false),
                ),
                CheckboxListTile(
                  title: const Text('Do you weigh at least 50kg?'),
                  value: _weightOk,
                  onChanged: (v) => setState(() => _weightOk = v ?? false),
                ),
                CheckboxListTile(
                  title: const Text(
                    'No recent international travel (6 months)?',
                  ),
                  value: _travelOk,
                  onChanged: (v) => setState(() => _travelOk = v ?? false),
                ),
                CheckboxListTile(
                  title: const Text('No recent medications (7 days)?'),
                  value: _medsOk,
                  onChanged: (v) => setState(() => _medsOk = v ?? false),
                ),
                CheckboxListTile(
                  title: const Text('Are you feeling well today?'),
                  value: _wellOk,
                  onChanged: (v) => setState(() => _wellOk = v ?? false),
                ),
              ],
            ),
          ),
          //  Blood Group.
          Step(
            title: const Text('Select Blood Type'),
            isActive: _currentStep >= 1,
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
          //  Hospital Selection.
          Step(
            title: const Text('Select Hospital'),
            isActive: _currentStep >= 2,
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InkWell(
                  onTap: () {
                    // Opens sub-sheet nga gakuha hospital data sa Firestore.
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) => HospitalPickerSheet(
                        onHospitalSelected: (h) {
                          setState(() => _selectedHospital = h);
                        },
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 20,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.local_hospital,
                          color: Theme.of(context).primaryColor,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _selectedHospital?.name ?? 'Where to donate?',
                            style: TextStyle(
                              color: _selectedHospital == null
                                  ? Colors.grey.shade600
                                  : Colors.black,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        const Icon(Icons.arrow_drop_down, color: Colors.grey),
                      ],
                    ),
                  ),
                ),
                if (_selectedHospital != null) ...[
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Text(
                      'Location: ${_selectedHospital!.barangay}, ${_selectedHospital!.city}',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Contact and Quantity.
          Step(
            title: const Text('Details'),
            isActive: _currentStep >= 3,
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
          // Appointment Scheduling.
          Step(
            title: const Text('Schedule Appointment'),
            isActive: _currentStep >= 4,
            content: Column(
              children: [
                ListTile(
                  title: const Text('Preferred Date'),
                  subtitle: Text(
                    _selectedDate == null
                        ? 'Not selected'
                        : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                  ),
                  leading: const Icon(Icons.calendar_today),
                  trailing: ElevatedButton(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now().add(const Duration(days: 1)),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 30)),
                      );
                      if (picked != null) setState(() => _selectedDate = picked);
                    },
                    child: const Text('Pick Date'),
                  ),
                ),
                ListTile(
                  title: const Text('Preferred Time'),
                  subtitle: Text(
                    _selectedTime == null
                        ? 'Not selected'
                        : _selectedTime!.format(context),
                  ),
                  leading: const Icon(Icons.access_time),
                  trailing: ElevatedButton(
                    onPressed: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: const TimeOfDay(hour: 9, minute: 0),
                      );
                      if (picked != null) setState(() => _selectedTime = picked);
                    },
                    child: const Text('Pick Time'),
                  ),
                ),
              ],
            ),
          ),
          // Legal Declaration.
          Step(
            title: const Text('Declaration'),
            isActive: _currentStep >= 5,
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
    if (!_isSworn ||
        _selectedHospital == null ||
        _selectedBloodType == null ||
        _selectedDate == null ||
        _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please complete all steps including appointment'),
        ),
      );
      return;
    }

    try {
      final api = ApiService();
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
        preferredDate:
            '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
        preferredTime: _selectedTime!.format(context),
      );

      await api.createBloodRequest(request);
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Donation request submitted!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
