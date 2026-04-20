library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/services/api_service.dart';
import '../../../core/models/user_model.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _api = ApiService();

  // Controls if nag viewing or editing.
  bool _isEditing = false;
  bool _isLoading = false;

  late TextEditingController _firstNameCtrl;
  late TextEditingController _lastNameCtrl;
  late TextEditingController _mobileCtrl;
  late TextEditingController _cityCtrl;
  late TextEditingController _addressCtrl;

  @override
  void initState() {
    super.initState();
    // Load from the AuthProvider into the GUI controllers.
    final user = context.read<AuthProvider>().user;
    _firstNameCtrl = TextEditingController(text: user?.firstName ?? '');
    _lastNameCtrl = TextEditingController(text: user?.lastName ?? '');
    _mobileCtrl = TextEditingController(text: user?.mobile ?? '');
    _cityCtrl = TextEditingController(text: user?.city ?? '');
    _addressCtrl = TextEditingController(text: user?.address ?? '');
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _mobileCtrl.dispose();
    _cityCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveProfile(UserModel currentUser) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final updatedUser = UserModel(
        uid: currentUser.uid,
        email: currentUser.email,
        role: currentUser.role,
        firstName: _firstNameCtrl.text.trim(),
        lastName: _lastNameCtrl.text.trim(),
        fatherName: currentUser.fatherName,
        mobile: _mobileCtrl.text.trim(),
        gender: currentUser.gender,
        bloodGroup: currentUser.bloodGroup,
        islandGroup: currentUser.islandGroup,
        region: currentUser.region,
        city: _cityCtrl.text.trim(),
        barangay: currentUser.barangay,
        address: _addressCtrl.text.trim(),
        hospitalId: currentUser.hospitalId,
        isBanned: currentUser.isBanned,
        createdAt: currentUser.createdAt,
      );

      await _api.saveUser(updatedUser);

      if (mounted) {
        setState(() => _isEditing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to update profile: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen to the 'AuthProvider' for the real-time user object.
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        backgroundColor: Theme.of(context).primaryColor,
        actions: [
          if (user != null)
            IconButton(
              icon: Icon(_isEditing ? Icons.close : Icons.edit),
              onPressed: () {
                setState(() {
                  _isEditing = !_isEditing;
                  if (!_isEditing) {
                    //If cancelling,i put the original data back in the controllers.
                    _firstNameCtrl.text = user.firstName;
                    _lastNameCtrl.text = user.lastName;
                    _mobileCtrl.text = user.mobile;
                    _cityCtrl.text = user.city;
                    _addressCtrl.text = user.address;
                  }
                });
              },
            ),
        ],
      ),
      body: user == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Theme.of(context).primaryColor,
                      child: const Icon(
                        Icons.person,
                        size: 60,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // READ MODE
                    if (!_isEditing) ...[
                      Text(
                        '${user.firstName} ${user.lastName}',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        user.email,
                        style: const TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 30),
                      _buildProfileItem(
                        Icons.bloodtype,
                        'Blood Group',
                        user.bloodGroup,
                      ),
                      _buildProfileItem(Icons.phone, 'Contact', user.mobile),
                      _buildProfileItem(Icons.location_city, 'City', user.city),
                      _buildProfileItem(Icons.home, 'Address', user.address),
                      _buildProfileItem(
                        Icons.admin_panel_settings,
                        'Role',
                        user.role.toUpperCase(),
                      ),
                    ]
                    // EDIT MODE:
                    else ...[
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _firstNameCtrl,
                        decoration: const InputDecoration(
                          labelText: 'First Name',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person),
                        ),
                        validator: (v) => v!.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _lastNameCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Last Name',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        validator: (v) => v!.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _mobileCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Contact Number',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.phone),
                        ),
                        keyboardType: TextInputType.phone,
                        validator: (v) => v!.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _cityCtrl,
                        decoration: const InputDecoration(
                          labelText: 'City',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.location_city),
                        ),
                        validator: (v) => v!.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _addressCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Detailed Address',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.home),
                        ),
                        maxLines: 2,
                        validator: (v) => v!.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 24),
                      // SAVE BUTTON
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: _isLoading
                              ? null
                              : () => _saveProfile(user),
                          icon: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.save),
                          label: Text(
                            _isLoading ? 'Saving...' : 'Save Changes',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).primaryColor,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 40),
                    // LOGOUT
                    if (!_isEditing)
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            auth.logout();
                            Navigator.of(context).pushNamedAndRemoveUntil(
                              '/login',
                              (route) => false,
                            );
                          },
                          icon: const Icon(Icons.logout, color: Colors.red),
                          label: const Text(
                            'Logout',
                            style: TextStyle(color: Colors.red),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.red),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
    );
  }

  // Displays a single row of user information ---
  Widget _buildProfileItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).primaryColor),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                Text(
                  value.isEmpty ? 'Not Provided' : value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
