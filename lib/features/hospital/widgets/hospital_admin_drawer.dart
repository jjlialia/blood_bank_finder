import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:blood_bank_finder/core/providers/auth_provider.dart';
import 'package:blood_bank_finder/features/auth/screens/login_screen.dart';
import 'package:blood_bank_finder/features/hospital/screens/hospital_admin_dashboard.dart';
import 'package:blood_bank_finder/features/hospital/screens/inventory_management_screen.dart';
import 'package:blood_bank_finder/features/hospital/screens/blood_requests_list_screen.dart';
import 'package:blood_bank_finder/features/hospital/screens/hospital_profile_screen.dart';

class HospitalAdminDrawer extends StatelessWidget {
  const HospitalAdminDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            accountName: Text(
              '${user?.firstName ?? ''} ${user?.lastName ?? ''}',
            ),
            accountEmail: Text(user?.email ?? ''),
            currentAccountPicture: const CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.local_hospital, color: Colors.redAccent),
            ),
            decoration: const BoxDecoration(color: Colors.redAccent),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard),
            title: const Text('Dashboard'),
            onTap: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const HospitalAdminDashboard(),
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.inventory),
            title: const Text('Inventory'),
            onTap: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const InventoryManagementScreen(),
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.list_alt),
            title: const Text('Blood Requests'),
            onTap: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const BloodRequestsListScreen(),
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.local_hospital),
            title: const Text('Hospital Profile'),
            onTap: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const HospitalProfileScreen(),
              ),
            ),
          ),
          const Spacer(),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Logout', style: TextStyle(color: Colors.red)),
            onTap: () {
              context.read<AuthProvider>().logout();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                (route) => false,
              );
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
