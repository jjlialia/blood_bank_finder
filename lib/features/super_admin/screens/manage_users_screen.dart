import 'package:flutter/material.dart';
import '../../../models/user_model.dart';
import '../../../models/hospital_model.dart';
import '../../../services/database_service.dart';
import '../widgets/super_admin_drawer.dart';

class ManageUsersScreen extends StatefulWidget {
  const ManageUsersScreen({super.key});

  @override
  State<ManageUsersScreen> createState() => _ManageUsersScreenState();
}

class _ManageUsersScreenState extends State<ManageUsersScreen> {
  final DatabaseService _db = DatabaseService();
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Users')),
      drawer: const SuperAdminDrawer(),
      body: Column(
        children: [
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
                    if (user.role == 'superadmin') {
                      return const SizedBox.shrink(); // Hide other superadmins
                    }

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: user.isBanned
                            ? Colors.grey
                            : Colors.redAccent,
                        child: const Icon(Icons.person, color: Colors.white),
                      ),
                      title: Text('${user.firstName} ${user.lastName}'),
                      subtitle: Text(user.email),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () => _showEditRoleDialog(user),
                            tooltip: 'Edit Role/Hospital',
                          ),
                          Switch(
                            value: !user.isBanned,
                            activeThumbColor: Colors.green,
                            onChanged: (active) async {
                              await _db.toggleUserBan(user.uid, !active);
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      active ? 'User Unbanned' : 'User Banned',
                                    ),
                                    backgroundColor: active
                                        ? Colors.green
                                        : Colors.red,
                                  ),
                                );
                              }
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

  void _showEditRoleDialog(UserModel user) {
    String selectedRole = user.role;
    String? selectedHospitalId = user.hospitalId;
    // Create the stream ONCE before the dialog opens to avoid restarts
    final hospitalsStream = _db.streamHospitals(allowAll: true);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          title: Text('Edit ${user.firstName} ${user.lastName}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: selectedRole,
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
              if (selectedRole == 'admin') ...[
                const SizedBox(height: 16),
                StreamBuilder<List<HospitalModel>>(
                  stream: hospitalsStream, // Use the pre-created stream
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Text(
                        'Error: ${snapshot.error}',
                        style: const TextStyle(color: Colors.red, fontSize: 12),
                      );
                    }
                    if (!snapshot.hasData) {
                      return const LinearProgressIndicator();
                    }
                    final hospitals = snapshot.data!;
                    // Safety check: ensure selectedHospitalId exists in the current hospital list
                    final isValidValue = hospitals.any(
                      (h) => h.id == selectedHospitalId,
                    );

                    return DropdownButtonFormField<String>(
                      value: isValidValue ? selectedHospitalId : null,
                      decoration: const InputDecoration(
                        labelText: 'Assign Hospital',
                      ),
                      items: hospitals.map((h) {
                        return DropdownMenuItem(
                          value: h.id,
                          child: Text(h.name),
                        );
                      }).toList(),
                      onChanged: (v) {
                        setModalState(() => selectedHospitalId = v);
                      },
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
                final navigator = Navigator.of(context);
                final scaffoldMessenger = ScaffoldMessenger.of(context);

                if (selectedRole == 'admin' && selectedHospitalId == null) {
                  scaffoldMessenger.showSnackBar(
                    const SnackBar(
                      content: Text('Please select a hospital for Admin'),
                    ),
                  );
                  return;
                }

                await _db.updateUserRoleAndHospital(
                  uid: user.uid,
                  role: selectedRole,
                  hospitalId: selectedHospitalId,
                );

                navigator.pop();
                scaffoldMessenger.showSnackBar(
                  const SnackBar(content: Text('User updated successfully')),
                );
              },
              child: const Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }
}
