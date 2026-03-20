/// FILE: user_home_screen.dart
///
/// DESCRIPTION:
/// The primary dashboard for regular users. It serves as a central hub
/// for the app's main functionalities, providing high-level summaries
/// and quick access to critical features like donating or requesting blood.
///
/// DATA FLOW OVERVIEW:
/// 1. RECEIVES DATA FROM:
///    - 'AuthProvider': Fetches the current user's name for the personalized greeting.
///    - 'Notifications': (Future proofing) Previews the latest alerts.
/// 2. PROCESSING:
///    - UI State Management: Uses 'context.watch<AuthProvider>()' to rebuild
///      instantly if user details change.
///    - Layout Construction: Combines a promotional banner, a donation CTA card,
///      and a grid of quick actions.
/// 3. SENDS DATA TO:
///    - Navigation: Sub-screens like 'FindBloodBankScreen', 'DonateBloodScreen',
///      and 'RequestBloodScreen'.
/// 4. OUTPUTS/GUI:
///    - A rich, scrollable dashboard with visual status indicators.
///    - Handlers for deep-linking into specific app features.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../widgets/user_drawer.dart';
import 'find_blood_bank_screen.dart';
import 'donate_blood_screen.dart';
import 'request_blood_screen.dart';
import 'notifications_screen.dart';

class UserHomeScreen extends StatelessWidget {
  const UserHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // DATA SOURCE: Listening to the AuthProvider for real-time user info.
    final auth = context.watch<AuthProvider>();
    final theme = Theme.of(context);
    final user = auth.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          // GUI: Quick access to the notifications history.
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
            // --- SECTION: Branded Banner & Greeting ---
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
                // GUI: Dark gradient to make white text readable over the image.
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
                // DATA DISPLAY: Showing the user's name from the AuthProvider.
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
                  // --- SECTION: Call-to-Action (Donation) ---
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
                  // --- SECTION: Quick Actions Selection ---
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
                    ],
                  ),
                  const SizedBox(height: 32),
                  // --- SECTION: Recent Activity Preview ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Latest Notifications',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const NotificationsScreen(),
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
                  // MOCK GUI: Displaying static examples of recent alerts.
                  _buildNotificationPreview(
                    context,
                    'Blood Request Approved',
                    'Your request for O+ at City Hospital has been approved.',
                    Icons.check_circle_outline,
                  ),
                  _buildNotificationPreview(
                    context,
                    'New Donation Drive',
                    'A new donation drive is happening this weekend!',
                    Icons.notifications_active_outlined,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- UI HELPER: Builds a interactive card for a main feature ---
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

  // --- UI HELPER: Builds a condensed preview row for a notification ---
  Widget _buildNotificationPreview(
    BuildContext context,
    String title,
    String body,
    IconData icon,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Theme.of(context).primaryColor),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        subtitle: Text(
          body,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 12),
        ),
        trailing: const Icon(Icons.chevron_right, size: 20),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const NotificationsScreen()),
        ),
      ),
    );
  }
}
