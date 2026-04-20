library;

import 'package:flutter/material.dart';
import '../../../core/models/user_model.dart';
import '../../../core/models/hospital_model.dart';
import '../../../core/services/database_service.dart';
import '../../../core/services/api_service.dart';
import '../widgets/super_admin_drawer.dart';

class ManageUsersScreen extends StatefulWidget {
  const ManageUsersScreen({super.key});

  @override
  State<ManageUsersScreen> createState() => _ManageUsersScreenState();
}

class _ManageUsersScreenState extends State<ManageUsersScreen> {
  final DatabaseService _db = DatabaseService();
  final ApiService _api = ApiService();

  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Users')),
      drawer: const SuperAdminDrawer(),
      body: Column(
        children: [
          // GUI: Search Input.
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search by name or email...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) =>
                  setState(() => _searchQuery = value.toLowerCase()),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<UserModel>>(
              stream: _db.streamAllUsers(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No users found.'));
                }

                final users = snapshot.data!.where((u) {
                  final fullName = '${u.firstName} ${u.lastName}'.toLowerCase();
                  return fullName.contains(_searchQuery) ||
                      u.email.toLowerCase().contains(_searchQuery);
                }).toList();

                return ListView.builder(
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final user = users[index];
                    // Prevent Super Admins from editing each other here.
                    if (user.role == 'superadmin')
                      return const SizedBox.shrink();

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: user.isBanned
                            ? Colors.grey
                            : Theme.of(context).primaryColor,
                        child: const Icon(Icons.person, color: Colors.white),
                      ),
                      title: Text('${user.firstName} ${user.lastName}'),
                      subtitle: Text(user.email),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          //Opens the role assignment modal.
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () => _showEditRoleDialog(user),
                          ),
                          // Quick Ban Toggle via API.
                          Switch(
                            value: !user.isBanned,
                            activeThumbColor: Colors.green,
                            onChanged: (active) async {
                              await _api.toggleUserBan(user.uid, !active);
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    active ? 'User Unbanned' : 'User Banned',
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  ///r: 'DatabaseService.streamHospitals' for the dropdown list.
  void _showEditRoleDialog(UserModel user) {
    String selectedRole = user.role;
    String? selectedHospitalId = user.hospitalId;
    final hospitalsStream = _db.streamHospitals(allowAll: true);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          title: Text('Edit Role: ${user.firstName}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: selectedRole,
                decoration: const InputDecoration(labelText: 'User Role'),
                items: const [
                  DropdownMenuItem(value: 'user', child: Text('Standard User')),
                  DropdownMenuItem(
                    value: 'admin',
                    child: Text('Hospital Admin'),
                  ),
                ],
                onChanged: (v) {
                  if (v != null) {
                    setModalState(() {
                      selectedRole = v;
                      if (v != 'admin') selectedHospitalId = null;
                    });
                  }
                },
              ),
              // If the user is promoted to Admin, show the hospital picker.
              if (selectedRole == 'admin') ...[
                const SizedBox(height: 16),
                StreamBuilder<List<HospitalModel>>(
                  stream: hospitalsStream,
                  builder: (context, snapshot) {
                    if (!snapshot.hasData)
                      return const LinearProgressIndicator();
                    return DropdownButtonFormField<String>(
                      initialValue:
                          snapshot.data!.any((h) => h.id == selectedHospitalId)
                          ? selectedHospitalId
                          : null,
                      decoration: const InputDecoration(
                        labelText: 'Assign Hospital',
                      ),
                      items: snapshot.data!
                          .map(
                            (h) => DropdownMenuItem(
                              value: h.id,
                              child: Text(h.name),
                            ),
                          )
                          .toList(),
                      onChanged: (v) =>
                          setModalState(() => selectedHospitalId = v),
                    );
                  },
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                //
                await _api.updateUserRole(
                  user.uid,
                  selectedRole,
                  hospitalId: selectedHospitalId,
                );
                if (!mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('User updated!')));
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
