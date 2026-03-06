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
  final Map<String, dynamic> _formData = {
    'gender': 'Male',
    'bloodGroup': 'A+',
    'islandGroup': null,
    'city': null,
    'barangay': null,
  };

  void _signup() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      final auth = context.read<AuthProvider>();
      final error = await auth.signup(_formData, _formData['password']);

      if (!mounted) return;

      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error), backgroundColor: Colors.red),
        );
        return;
      }

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
              const Text(
                'Personal Information',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.redAccent,
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
              const Text(
                'Location Details',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.redAccent,
                ),
              ),
              const SizedBox(height: 16),
              PhLocationPicker(
                onLocationChanged: (island, city, barangay) {
                  _formData['islandGroup'] = island;
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
              const Text(
                'Account Credentials',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.redAccent,
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
