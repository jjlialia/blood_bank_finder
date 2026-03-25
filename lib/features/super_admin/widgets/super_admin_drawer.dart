import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:blood_bank_finder/core/providers/auth_provider.dart';
import 'package:blood_bank_finder/features/auth/screens/login_screen.dart';
import 'package:blood_bank_finder/features/super_admin/screens/super_admin_dashboard.dart';
import 'package:blood_bank_finder/features/super_admin/screens/manage_hospitals_screen.dart';
import 'package:blood_bank_finder/features/super_admin/screens/manage_users_screen.dart';
import 'package:blood_bank_finder/features/super_admin/screens/global_log_screen.dart';
import 'package:blood_bank_finder/features/chat/screens/chat_list_screen.dart';

class SuperAdminDrawer extends StatelessWidget {
  const SuperAdminDrawer({super.key});

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
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(
                Icons.admin_panel_settings,
                color: Theme.of(context).primaryColor,
              ),
            ),
            decoration: BoxDecoration(color: Theme.of(context).primaryColor),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard),
            title: const Text('Dashboard'),
            onTap: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const SuperAdminDashboard(),
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.chat),
            title: const Text('Messages'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ChatListScreen(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.local_hospital),
            title: const Text('Manage Hospitals'),
            onTap: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const ManageHospitalsScreen(),
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.people),
            title: const Text('Manage Users'),
            onTap: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const ManageUsersScreen(),
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.history),
            title: const Text('Global Logs'),
            onTap: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const GlobalLogScreen()),
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
