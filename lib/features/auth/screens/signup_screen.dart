/**
 * FILE: signup_screen.dart
 * 
 * DESCRIPTION:
 * This screen handles the comprehensive registration process for new users.
 * It collects personal identity, health information (blood group), 
 * and detailed location data.
 * 
 * DATA FLOW OVERVIEW:
 * 1. RECEIVES DATA FROM: 
 *    - User Input: Multiple TextFields and Dropdowns.
 *    - 'PhLocationPicker': A dedicated widget for Philippine address hierarchy.
 * 2. PROCESSING:
 *    - Data Aggregation: Collects all inputs into a single '_formData' map.
 *    - Validation: Ensures all required fields (identity, location, credentials) are filled.
 * 3. SENDS DATA TO:
 *    - 'AuthProvider.signup': Sends the full profile map to the provider, which 
 *      calls the FastAPI backend to create both the Auth account and Firestore doc.
 * 4. OUTPUTS/GUI:
 *    - A long, scrollable form divided into 'Personal', 'Location', and 'Account' sections.
 *    - Direct navigation to the 'UserHomeScreen' upon successful registration.
 */

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/custom_text_field.dart';
import '../../../shared/widgets/location_picker.dart';
import '../../user/screens/user_home_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // DATA STORAGE: Temporary map to hold all user inputs before submission.
  final Map<String, dynamic> _formData = {
    'gender': 'Male',
    'bloodGroup': 'A+',
    'islandGroup': null,
    'region': null,
    'city': null,
    'barangay': null,
  };

  /**
   * CORE LOGIC: Signup Data Flow.
   * 1. Triggers form 'save()' to populate the '_formData' map.
   * 2. Calls the 'auth.signup' method.
   * 3. DATA JOURNEY: App -> AuthProvider -> FastAPI -> Firebase Auth & Firestore.
   * 4. On SUCCESS: Clears login history and enters the Home Screen.
   */
  void _signup() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      final auth = context.read<AuthProvider>();
      
      // STEP: Submit the gathered data.
      final error = await auth.signup(_formData, _formData['password']);

      if (!mounted) return;

      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error), backgroundColor: Colors.red),
        );
        return;
      }

      // STEP: Success. Redirect to the main app area.
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const UserHomeScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Account')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- SECTION 1: Personal Data ---
              Text(
                'Personal Information',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'First Name',
                prefixIcon: Icons.person_outline,
                onSaved: (v) => _formData['firstName'] = v,
              ),
              CustomTextField(
                label: 'Last Name',
                prefixIcon: Icons.person_outline,
                onSaved: (v) => _formData['lastName'] = v,
              ),
              CustomTextField(
                label: 'Mobile',
                prefixIcon: Icons.phone_android,
                keyboardType: TextInputType.phone,
                onSaved: (v) => _formData['mobile'] = v,
              ),
              _buildDropdown('Gender', ['Male', 'Female', 'Other'], 'gender'),
              _buildDropdown('Blood Group', [
                'A+', 'A-', 'B+', 'B-', 'O+', 'O-', 'AB+', 'AB-',
              ], 'bloodGroup'),

              const SizedBox(height: 16),
              // --- SECTION 2: Location Data ---
              Text(
                'Location Details',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              const SizedBox(height: 16),
              // STEP: This widget provides cascading selection for PH addresses.
              PhLocationPicker(
                onLocationChanged: (island, region, city, barangay) {
                  _formData['islandGroup'] = island;
                  _formData['region'] = region;
                  _formData['city'] = city;
                  _formData['barangay'] = barangay;
                },
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'Street Address / House No.',
                prefixIcon: Icons.home_outlined,
                onSaved: (v) => _formData['address'] = v,
              ),

              const SizedBox(height: 16),
              // --- SECTION 3: Account Data ---
              Text(
                'Account Credentials',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'Email',
                prefixIcon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                onSaved: (v) => _formData['email'] = v,
              ),
              CustomTextField(
                label: 'Password',
                prefixIcon: Icons.lock_outline,
                obscureText: true,
                onSaved: (v) => _formData['password'] = v,
              ),
              const SizedBox(height: 32),
              // ACTION: Triggers the _signup flow.
              Consumer<AuthProvider>(
                builder: (context, auth, _) => CustomButton(
                  label: 'Sign Up',
                  isLoading: auth.isLoading,
                  onPressed: _signup,
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // --- UI HELPER: Reusable dropdown for gender and blood group ---
  Widget _buildDropdown(String label, List<String> items, String key) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<String>(
        value: _formData[key],
        decoration: InputDecoration(labelText: label),
        items: items
            .map((e) => DropdownMenuItem(value: e, child: Text(e)))
            .toList(),
        onChanged: (v) => setState(() => _formData[key] = v),
      ),
    );
  }
}
