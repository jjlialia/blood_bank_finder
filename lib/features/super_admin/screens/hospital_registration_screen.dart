import 'package:flutter/material.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/custom_text_field.dart';
import '../../../shared/widgets/location_picker.dart';

class HospitalRegistrationScreen extends StatefulWidget {
  const HospitalRegistrationScreen({super.key});

  @override
  State<HospitalRegistrationScreen> createState() =>
      _HospitalRegistrationScreenState();
}

class _HospitalRegistrationScreenState
    extends State<HospitalRegistrationScreen> {
  bool _isActive = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register Hospital')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const CustomTextField(
              label: 'Hospital Name',
              prefixIcon: Icons.local_hospital,
            ),
            const SizedBox(height: 8),
            PhLocationPicker(
              onLocationChanged: (island, region, city, barangay) {
                // Handle location data
              },
            ),
            const SizedBox(height: 16),
            const CustomTextField(
              label: 'Street Address',
              prefixIcon: Icons.home,
            ),
            const CustomTextField(
              label: 'Email',
              prefixIcon: Icons.email,
              keyboardType: TextInputType.emailAddress,
            ),
            const CustomTextField(
              label: 'Contact Number',
              prefixIcon: Icons.phone,
              keyboardType: TextInputType.phone,
            ),
            const CustomTextField(
              label: 'Initial Password',
              prefixIcon: Icons.lock,
              obscureText: true,
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              title: const Text('Is Active / Open'),
              subtitle: const Text(
                'Hospital will be visible in search results',
              ),
              activeThumbColor: Colors.redAccent,
              value: _isActive,
              onChanged: (v) => setState(() => _isActive = v),
            ),
            const SizedBox(height: 24),
            CustomButton(
              label: 'Register Hospital',
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}
