/// FILE: request_blood_screen.dart
///
/// DESCRIPTION:
/// This screen allows users to post an emergency request for blood.
/// It collects technical details (blood type, quantity) and integrates
/// a hospital directory for site selection.
///
/// DATA FLOW OVERVIEW:
/// 1. RECEIVES DATA FROM:
///    - 'AuthProvider': For the requester's ID and Name.
///    - 'HospitalPickerSheet': For selecting the destination facility.
///    - User Input: Blood type dropdown and unit quantity.
/// 2. PROCESSING:
///    - Request Assembly: Creates a 'BloodRequestModel' object with 'status: pending'.
///    - Validation: Ensures a hospital is selected and quantity is a valid number.
/// 3. SENDS DATA TO:
///    - 'ApiService.createBloodRequest': Transmits the request data to the
///      FastAPI backend, which persists it in Firestore.
/// 4. OUTPUTS/GUI:
///    - Multi-input form with a 'Sworn Statement' checkbox for medical urgency.
///    - Success/Error snackbars based on the API response.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/models/blood_request_model.dart';
import '../../../core/models/hospital_model.dart';
import '../../../core/services/api_service.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../shared/widgets/custom_text_field.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/hospital_picker_sheet.dart';

class RequestBloodScreen extends StatefulWidget {
  const RequestBloodScreen({super.key});

  @override
  State<RequestBloodScreen> createState() => _RequestBloodScreenState();
}

class _RequestBloodScreenState extends State<RequestBloodScreen> {
  final _formKey = GlobalKey<FormState>();

  // STATE: Holding the user's selections.
  String? _selectedBloodType;
  HospitalModel? _selectedHospital;
  final _unitsController = TextEditingController(text: '1.0');
  final _contactController = TextEditingController();
  bool _isSworn = false;

  @override
  void initState() {
    super.initState();
  }

  /// CORE LOGIC: The Emergency Request Data Flow.
  /// 1. PRE-CHECK: Ensures a Hospital and Blood Type are selected.
  /// 2. ASSEMBLY: Gathers Data from: Auth (User) + GUI (Inputs) + Picker (Hospital).
  /// 3. DATA JOURNEY: App -> ApiService -> FastAPI Backend -> Firestore.
  /// 4. UI UPDATE: Closes the screen and shows a green success snackbar.
  void _submitRequest(AuthProvider auth) async {
    // STEP: Validate that the picker was used.
    if (_selectedHospital == null || _selectedBloodType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select hospital and blood type')),
      );
      return;
    }

    try {
      final api = ApiService();

      // STEP: Create the data structure for the backend.
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

      // STEP: Send the package over the network.
      await api.createBloodRequest(request);

      if (!mounted) return;

      // STEP: GUI cleanup and feedback.
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Blood request posted successfully!'),
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

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Request Blood')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // INPUT: Blood selection dropdown.
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
              // INPUT: Interactive Hospital selection sheet.
              InkWell(
                onTap: () {
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
                      Icon(Icons.local_hospital, color: theme.primaryColor),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _selectedHospital?.name ?? 'Select Hospital',
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
              // GUI: Displaying location preview once a hospital is picked.
              if (_selectedHospital != null) ...[
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Text(
                    'Location: ${_selectedHospital!.barangay}, ${_selectedHospital!.city}',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              // INPUT: Units required.
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
              // INPUT: Legal verification checkbox.
              CheckboxListTile(
                title: const Text(
                  'I solemnly swear this request is for a medical need.',
                  style: TextStyle(fontSize: 13),
                ),
                value: _isSworn,
                activeColor: Theme.of(context).primaryColor,
                onChanged: (v) => setState(() => _isSworn = v ?? false),
              ),
              const SizedBox(height: 32),
              // ACTION: Triggers the data submission.
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
}
