/// FILE: donate_blood_screen.dart
///
/// DESCRIPTION:
/// This screen provides a guided, multi-step process (Stepper) for users who
/// wish to donate blood. It includes an eligibility quiz, location selection,
/// and final data submission.
///
/// DATA FLOW OVERVIEW:
/// 1. RECEIVES DATA FROM:
///    - 'AuthProvider': To get the currently logged-in user's UID and profile info.
///    - 'HospitalPickerSheet': A custom widget that lets the user select a
///      target hospital from a list fetched from Firestore.
/// 2. PROCESSING:
///    - Validation: Checks if the user meets all 5 health criteria in Step 1.
///    - Model Construction: Combines user input (blood type, quantity, contact)
///      with fixed data (Status = 'pending', Type = 'Donate') into a 'BloodRequestModel'.
/// 3. SENDS DATA TO:
///    - 'ApiService.createBloodRequest': Sends the final JSON object to the
///      FastAPI backend, which then writes it to Firestore.
/// 4. OUTPUTS/GUI:
///    - A vertical Stepper UI that validates each step before allowing progression.
///    - Visual feedback (SnackBars) for success or failure of the submission.
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
  // STATE MANAGEMENT: Tracking the user's progress through the form.
  int _currentStep = 0;
  String? _selectedBloodType;
  HospitalModel? _selectedHospital;
  final _unitsController = TextEditingController(text: '1.0');
  final _contactController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  // ELIGIBILITY STATE: These must all be TRUE to proceed.
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
          // STEP: Validation Gate for the Eligibility Quiz.
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
          // STEP: Validation Gate for the Details Form.
          if (_currentStep == 3) {
            if (!_formKey.currentState!.validate()) return;
          }

          if (_currentStep < 4) {
            setState(() => _currentStep++);
          } else {
            // FINAL STEP: Submit the gathered data to the server.
            _submitDonation(auth);
          }
        },
        onStepCancel: () {
          if (_currentStep > 0) setState(() => _currentStep--);
        },
        steps: [
          // GUI: Step 1 - Health Screening.
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
          // GUI: Step 2 - Blood Group.
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
          // GUI: Step 3 - Hospital Selection.
          Step(
            title: const Text('Select Hospital'),
            isActive: _currentStep >= 2,
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InkWell(
                  onTap: () {
                    // STEP: Opens a sub-sheet that fetches hospital data from Firestore.
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
          // GUI: Step 4 - Contact and Quantity.
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
          // GUI: Step 5 - Legal Declaration.
          Step(
            title: const Text('Declaration'),
            isActive: _currentStep >= 4,
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

  /// CORE LOGIC: Final Data Flow Submission.
  /// 1. Consolidates all state variables into a 'BloodRequestModel'.
  /// 2. Calls the 'api.createBloodRequest' method.
  /// 3. DATA DESTINATION: FastAPI backend -> Firestore 'blood_requests' collection.
  /// 4. If successful, closes the screen and shows a green success banner.
  void _submitDonation(AuthProvider auth) async {
    if (!_isSworn || _selectedHospital == null || _selectedBloodType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please complete all steps and sign the declaration'),
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
