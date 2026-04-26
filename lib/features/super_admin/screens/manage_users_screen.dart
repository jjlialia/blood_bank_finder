library;

import 'package:flutter/material.dart';
import '../../../core/models/user_model.dart';
import '../../../core/models/hospital_model.dart';
import '../../../core/services/database_service.dart';
import '../../../core/services/api_service.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/models/audit_log_model.dart';
import '../widgets/super_admin_drawer.dart';

class ManageUsersScreen extends StatefulWidget {
  const ManageUsersScreen({super.key});

  @override
  State<ManageUsersScreen> createState() => _ManageUsersScreenState();
}

class _ManageUsersScreenState extends State<ManageUsersScreen> {
  String _searchQuery = '';
  String _roleFilter = 'All'; // All, Admin, User, Banned

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('User Management')),
      drawer: const SuperAdminDrawer(),
      body: Column(
        children: [
          _buildSearchAndFilter(),
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

                final filteredUsers = snapshot.data!.where((u) {
                  // Hide superadmins from general management
                  if (u.role == 'superadmin') return false;

                  final fullName = '${u.firstName} ${u.lastName}'.toLowerCase();
                  final matchesSearch = fullName.contains(_searchQuery) ||
                      u.email.toLowerCase().contains(_searchQuery);

                  final matchesRole = _roleFilter == 'All' ||
                      (_roleFilter == 'Admin' && u.role == 'admin') ||
                      (_roleFilter == 'User' && u.role == 'user') ||
                      (_roleFilter == 'Banned' && u.isBanned);

                  return matchesSearch && matchesRole;
                }).toList();

                if (filteredUsers.isEmpty) {
                  return const Center(child: Text('No matching users found.'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filteredUsers.length,
                  itemBuilder: (context, index) {
                    final user = filteredUsers[index];
                    return _buildUserCard(user);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  final DatabaseService _db = DatabaseService();
  final ApiService _api = ApiService();

  Widget _buildSearchAndFilter() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, 2),
            blurRadius: 4,
          ),
        ],
      ),
      child: Column(
        children: [
          TextField(
            onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
            decoration: InputDecoration(
              hintText: 'Search by name or email...',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ['All', 'Admin', 'User', 'Banned'].map((filter) {
                final isSelected = _roleFilter == filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ChoiceChip(
                    label: Text(filter),
                    selected: isSelected,
                    onSelected: (val) {
                      if (val) setState(() => _roleFilter = filter);
                    },
                    selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
                    labelStyle: TextStyle(
                      color: isSelected
                          ? Theme.of(context).primaryColor
                          : Colors.grey[700],
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 12,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserCard(UserModel user) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(top: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: user.isBanned
                      ? Colors.grey[200]
                      : Theme.of(context).primaryColor.withOpacity(0.1),
                  child: Icon(
                    Icons.person,
                    color: user.isBanned
                        ? Colors.grey[400]
                        : Theme.of(context).primaryColor,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${user.firstName} ${user.lastName}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        user.email,
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                    ],
                  ),
                ),
                _roleBadge(user.role, user.isBanned),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(height: 1),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      'Access:',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      user.isBanned ? 'Restricted' : 'Full Access',
                      style: TextStyle(
                        color: user.isBanned ? Colors.red : Colors.green,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 20),
                      onPressed: () => _showEditRoleDialog(user),
                      tooltip: 'Change Role',
                    ),
                    const SizedBox(width: 8),
                    _banToggle(user),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _roleBadge(String role, bool isBanned) {
    if (isBanned) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Text(
          'BANNED',
          style: TextStyle(
            color: Colors.white,
            fontSize: 9,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    final isAdmin = role == 'admin';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isAdmin ? Colors.blue[50] : Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        role.toUpperCase(),
        style: TextStyle(
          color: isAdmin ? Colors.blue[700] : Colors.grey[700],
          fontSize: 9,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _banToggle(UserModel user) {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: user.isBanned ? Colors.red[50] : Colors.green[50],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Transform.scale(
            scale: 0.7,
            child: Switch(
              value: !user.isBanned,
              activeColor: Colors.green,
              activeTrackColor: Colors.green.withOpacity(0.2),
              inactiveThumbColor: Colors.red,
              inactiveTrackColor: Colors.red.withOpacity(0.2),
              onChanged: (active) async {
                final admin = context.read<AuthProvider>().user;
                await _api.toggleUserBan(user.uid, !active);
                
                // Audit Log
                if (admin != null) {
                  await _db.logAction(AuditLogModel(
                    id: '',
                    action: active ? 'USER_UNBANNED' : 'USER_BANNED',
                    category: 'Admin',
                    description: '${admin.firstName} ${active ? 'unbanned' : 'banned'} ${user.firstName} ${user.lastName}.',
                    userId: admin.uid,
                    userName: '${admin.firstName} ${admin.lastName}',
                    userRole: admin.role,
                    timestamp: DateTime.now(),
                    metadata: {'targetUserId': user.uid, 'targetEmail': user.email},
                  ));
                }

                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      active ? 'User Unbanned' : 'User Banned',
                    ),
                    backgroundColor: active ? Colors.green : Colors.red,
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Icon(
              user.isBanned ? Icons.block : Icons.check_circle,
              size: 14,
              color: user.isBanned ? Colors.red : Colors.green,
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
                final admin = context.read<AuthProvider>().user;
                await _api.updateUserRole(
                  user.uid,
                  selectedRole,
                  hospitalId: selectedHospitalId,
                );

                // Audit Log
                if (admin != null) {
                  await _db.logAction(AuditLogModel(
                    id: '',
                    action: 'USER_ROLE_UPDATED',
                    category: 'Admin',
                    description: '${admin.firstName} changed ${user.firstName}\'s role to $selectedRole.',
                    userId: admin.uid,
                    userName: '${admin.firstName} ${admin.lastName}',
                    userRole: admin.role,
                    timestamp: DateTime.now(),
                    metadata: {
                      'targetUserId': user.uid,
                      'newRole': selectedRole,
                      'hospitalId': selectedHospitalId,
                    },
                  ));
                }

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
