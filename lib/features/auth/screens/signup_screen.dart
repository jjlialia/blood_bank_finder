library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/custom_text_field.dart';
import '../../../shared/widgets/location_picker.dart';
import 'landing_screen.dart';
import '../../user/screens/user_home_screen.dart';
import 'otp_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();

  //holder
  final Map<String, dynamic> _formData = {
    'gender': 'Male',
    'bloodGroup': 'A+',
    'islandGroup': null,
    'region': null,
    'city': null,
    'barangay': null,
  };

  /// validate, save, otp, navigate to otpscreen.
  void _signup() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      final auth = context.read<AuthProvider>();

      // 1. Send OTP first
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sending verification code...')),
      );

      final error = await auth.sendOtp(_formData['email']);

      if (!mounted) return;

      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error), backgroundColor: Colors.red),
        );
        return;
      }

      // 2. Navigate to OTP Screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => OtpScreen(
            email: _formData['email'],
            onVerified: _completeSignup,
          ),
        ),
      );
    }
  }

  void _completeSignup() async {
    final auth = context.read<AuthProvider>();
    final error = await auth.signup(_formData, _formData['password']);

    if (!mounted) return;

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.red),
      );
      return;
    }

    // Go to LandingScreen as requested ("after login/signout")
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LandingScreen()),
      (route) => false,
    );
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
              // input data
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
                'A+',
                'A-',
                'B+',
                'B-',
                'O+',
                'O-',
                'AB+',
                'AB-',
              ], 'bloodGroup'),

              const SizedBox(height: 16),
              // location
              Text(
                'Location Details',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              const SizedBox(height: 16),
              // mopili og location. island, region, city, barangay.
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
              // email og password
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
              // pagclick sa signup button mogamit sa _signup method.
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

  //reusable. gigamit nga dropdown sa gender og bloodgroup
  Widget _buildDropdown(String label, List<String> items, String key) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<String>(
        initialValue: _formData[key],
        decoration: InputDecoration(labelText: label),
        items: items
            .map((e) => DropdownMenuItem(value: e, child: Text(e)))
            .toList(),
        onChanged: (v) => setState(() => _formData[key] = v),
      ),
    );
  }
}









/// FILE: signup_screen.dart
///
/// DESCRIPTION:
/// This screen handles the comprehensive registration process for new users.
/// It collects personal identity, health information (blood group),
/// and detailed location data.
///
/// DATA FLOW OVERVIEW:
/// 1. RECEIVES DATA FROM:
///    - User Input: Multiple TextFields and Dropdowns.
///    - 'PhLocationPicker': A dedicated widget for Philippine address hierarchy.
/// 2. PROCESSING:
///    - Data Aggregation: Collects all inputs into a single '_formData' map.
///    - Validation: Ensures all required fields (identity, location, credentials) are filled.
/// 3. SENDS DATA TO:
///    - 'AuthProvider.signup': Sends the full profile map to the provider, which
///      calls the backend to create both the Auth account and Firestore doc.
/// 4. OUTPUTS/GUI:
///    - A long, scrollable form divided into 'Personal', 'Location', and 'Account' sections.
///    - Direct navigation to the 'UserHomeScreen' upon successful registration.

//onsaved: (v) => _formData['key'] = v,
//ang v kay ang value sa textfield.
//phlocationpicker: gikan sa location_picker.dart

//ang _formData kay ang data sa user og ang _formkey kay ang key sa form.
//ang _signup kay ang function sa pag-signup.
//ang _buildDropdown kay ang function sa pag-build ng dropdown.