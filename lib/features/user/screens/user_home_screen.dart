library;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/models/blood_request_model.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/services/database_service.dart';
import '../widgets/user_drawer.dart';
import 'find_blood_bank_screen.dart';
import 'donate_blood_screen.dart';
import 'my_requests_screen.dart';
import 'request_blood_screen.dart';
import 'notifications_screen.dart';
import '../../chat/screens/chat_list_screen.dart';

class UserHomeScreen extends StatelessWidget {
  const UserHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // live. sa authprovider
    final auth = context.watch<AuthProvider>();
    final theme = Theme.of(context);
    final user = auth.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          //message shortcut
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ChatListScreen()),
            ),
          ),
          // notification shortcut
          IconButton(
            icon: const Icon(Icons.notifications_none),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const NotificationsScreen(),
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      drawer: const UserDrawer(),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner and Greeting
            Stack(
              children: [
                Image.asset(
                  'assets/images/home_banner.jpg',
                  width: double.infinity,
                  height: 220,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: double.infinity,
                      height: 220,
                      color: theme.primaryColor.withValues(alpha: 0.1),
                      child: Center(
                        child: Icon(
                          Icons.volunteer_activism,
                          size: 64,
                          color: theme.primaryColor.withValues(alpha: 0.5),
                        ),
                      ),
                    );
                  },
                ),
                //Dark gradient, white text
                Container(
                  width: double.infinity,
                  height: 220,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.4),
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.4),
                      ],
                    ),
                  ),
                ),
                // Showing the users name from the AuthProvider.
                Positioned(
                  top: 40,
                  left: 24,
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: Colors.white.withValues(alpha: 0.2),
                        child: const Icon(
                          Icons.person,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hello,',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                          ),
                          Text(
                            '${user?.firstName ?? "Donor"}!',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Call-to-Action (Donation)
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [theme.primaryColor, const Color(0xFFB22222)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: theme.primaryColor.withValues(alpha: 0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Ready to give?',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Donate Blood',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const DonateBloodScreen(),
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: theme.primaryColor,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 10,
                                  ),
                                  minimumSize: Size.zero,
                                ),
                                child: const Text('Schedule Now'),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.volunteer_activism,
                          color: Colors.white24,
                          size: 80,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Quick Actions Selection
                  Text(
                    'Quick Actions',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _buildQuickAction(
                        context,
                        'Find Banks',
                        Icons.search,
                        theme.primaryColor.withValues(alpha: 0.08),
                        const FindBloodBankScreen(),
                      ),
                      const SizedBox(width: 16),
                      _buildQuickAction(
                        context,
                        'Request',
                        Icons.emergency_outlined,
                        const Color(0xFFFFF8E1),
                        const RequestBloodScreen(),
                      ),
                      const SizedBox(width: 16),
                      _buildQuickAction(
                        context,
                        'My History',
                        Icons.history_outlined,
                        const Color(0xFFE8F5E9),
                        const MyRequestsScreen(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  // Recent Activity Preview (live)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Recent Activity',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const MyRequestsScreen(),
                          ),
                        ),
                        child: Text(
                          'See All',
                          style: TextStyle(color: theme.primaryColor),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Live StreamBuilder: shows the 2 most recent requests/donations
                  if (user != null)
                    StreamBuilder<List<BloodRequestModel>>(
                      stream: DatabaseService().streamUserRequests(user!.uid),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                        final items = (snapshot.data ?? []).take(2).toList();
                        if (items.isEmpty) {
                          return Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(16),
                              border:
                                  Border.all(color: Colors.grey.shade200),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.history_toggle_off_outlined,
                                  color: theme.primaryColor
                                      .withValues(alpha: 0.4),
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  'No activity yet. Make a request or donate!',
                                  style: TextStyle(
                                      color: Colors.black45, fontSize: 13),
                                ),
                              ],
                            ),
                          );
                        }
                        return Column(
                          children: items
                              .map((r) => _buildRequestPreview(context, r))
                              .toList(),
                        );
                      },
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  //UI HELPER: interactive card
  Widget _buildQuickAction(
    BuildContext context,
    String label,
    IconData icon,
    Color color,
    Widget screen,
  ) {
    return Expanded(
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => screen),
        ),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Icon(icon, size: 32, color: Theme.of(context).primaryColor),
              const SizedBox(height: 12),
              Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // UI HELPER: compact card for a real blood request / donation
  Widget _buildRequestPreview(BuildContext context, BloodRequestModel r) {
    final theme = Theme.of(context);
    final isRequest = r.type.toLowerCase() == 'request';

    Color statusColor;
    Color statusBg;
    IconData statusIcon;
    switch (r.status.toLowerCase()) {
      case 'approved':
      case 'completed':
        statusColor = const Color(0xFF2E7D32);
        statusBg = const Color(0xFFE8F5E9);
        statusIcon = Icons.check_circle_outline;
        break;
      case 'rejected':
        statusColor = const Color(0xFFC62828);
        statusBg = const Color(0xFFFFEBEE);
        statusIcon = Icons.cancel_outlined;
        break;
      default:
        statusColor = const Color(0xFFF57F17);
        statusBg = const Color(0xFFFFF8E1);
        statusIcon = Icons.hourglass_top_outlined;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 1.5,
      shadowColor: Colors.black12,
      child: ListTile(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const MyRequestsScreen()),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: theme.primaryColor.withValues(alpha: 0.08),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              r.bloodType,
              style: TextStyle(
                color: theme.primaryColor,
                fontWeight: FontWeight.w900,
                fontSize: 13,
              ),
            ),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                isRequest ? 'Blood Request' : 'Donation',
                style: const TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 14),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: statusBg,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(statusIcon, size: 12, color: statusColor),
                  const SizedBox(width: 3),
                  Text(
                    r.status[0].toUpperCase() + r.status.substring(1),
                    style: TextStyle(
                        color: statusColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ],
        ),
        subtitle: Text(
          '${r.hospitalName} · ${DateFormat('MMM d, y').format(r.createdAt)}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 12, color: Colors.black54),
        ),
        trailing: const Icon(Icons.chevron_right, size: 20),
      ),
    );
  }
}

