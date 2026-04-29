import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../auth/domain/entities/user.dart';
import '../../super_admin/presentation/providers/super_admin_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();

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
    final user = context.read<AuthProvider>().userEntity;
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

  Future<void> _saveProfile(UserEntity currentUser) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final updatedUser = UserEntity(
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

      // Using SuperAdminProvider to update user profile as it already has access to ISuperAdminRepository
      // which can handle user updates (we might need to add an update method there).
      // Or we can add it to AuthProvider.
      // For now, let's assume we want a clean DDD way.
      // I'll add 'updateUser' to SuperAdminProvider and use it here.
      
      final superAdminProvider = context.read<SuperAdminProvider>();
      await superAdminProvider.updateUser(updatedUser);

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
    final user = auth.userEntity;

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
                    //If cancelling, i put the original data back in the controllers.
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
                    Stack(
                      alignment: Alignment.bottomCenter,
                      clipBehavior: Clip.none,
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
                        // Blood-type badge pinned at the bottom of the avatar
                        if (user.bloodGroup.isNotEmpty)
                          Positioned(
                            bottom: -14,
                            child: _BloodTypeBadge(bloodType: user.bloodGroup),
                          ),
                      ],
                    ),
                    const SizedBox(height: 28),

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
                      // Blood group shown as a card banner instead of a plain row
                      _buildBloodGroupCard(user.bloodGroup),
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

  /// Full-width banner that makes the blood group unmissable on the profile.
  Widget _buildBloodGroupCard(String bloodType) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFCC0000), Color(0xFFFF4444)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.35),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.bloodtype, color: Colors.white, size: 28),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Blood Type',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                  letterSpacing: 1.2,
                ),
              ),
              Text(
                bloodType.isEmpty ? 'Not Set' : bloodType,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'Registered',
              style: TextStyle(color: Colors.white, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }
}

/// Reusable pill badge — shown on the avatar in the Profile screen
/// and in the UserDrawer header.
class _BloodTypeBadge extends StatelessWidget {
  final String bloodType;
  const _BloodTypeBadge({required this.bloodType});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFCC0000), Color(0xFFFF4444)],
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.5),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        bloodType,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
      ),
    );
  }
}
