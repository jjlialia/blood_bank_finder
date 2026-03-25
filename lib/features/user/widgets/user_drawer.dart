import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:blood_bank_finder/core/providers/auth_provider.dart';
import 'package:blood_bank_finder/features/auth/screens/login_screen.dart';
import 'package:blood_bank_finder/features/user/screens/user_home_screen.dart';
import 'package:blood_bank_finder/features/user/screens/profile_screen.dart';
import 'package:blood_bank_finder/features/user/screens/notifications_screen.dart';
import 'package:blood_bank_finder/features/chat/screens/chat_room_screen.dart';
import 'package:blood_bank_finder/features/chat/services/chat_service.dart';

class UserDrawer extends StatelessWidget {
  const UserDrawer({super.key});

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
              child: Icon(Icons.person, color: Theme.of(context).primaryColor),
            ),
            decoration: BoxDecoration(color: Theme.of(context).primaryColor),
          ),
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('Home'),
            onTap: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const UserHomeScreen()),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('My Profile'),
            onTap: () {
              Navigator.pop(context); // Close drawer
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.notifications),
            title: const Text('Notifications'),
            onTap: () {
              Navigator.pop(context); // Close drawer
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NotificationsScreen(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('About Us'),
            onTap: () {
              // Show about dialog or navigate
              showAboutDialog(
                context: context,
                applicationName: 'Blood Bank Finder',
                applicationVersion: '1.0.0',
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.support_agent),
            title: const Text('Contact Support'),
            onTap: () async {
              final auth = context.read<AuthProvider>();
              final currentUser = auth.user;
              if (currentUser == null) return;
              
              final chatService = ChatService();
              final chatId = await chatService.createOrGetChat(
                currentUser.uid,
                'superadmin',
                {
                  currentUser.uid: '${currentUser.firstName} ${currentUser.lastName}',
                  'superadmin': 'System Admin',
                }
              );
              if (!context.mounted) return;
              Navigator.pop(context); // Close drawer
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatRoomScreen(
                    chatRoomId: chatId,
                    otherParticipantName: 'System Admin',
                  ),
                ),
              );
            },
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
