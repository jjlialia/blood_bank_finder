/// FILE: notifications_screen.dart
///
/// DESCRIPTION:
/// This screen displays the user's Inbox for all system alerts.
/// It primarily notifies users when their blood requests or donations
/// are approved, rejected, or updated by hospital admins.
///
/// DATA FLOW OVERVIEW:
/// 1. RECEIVES DATA FROM:
///    - 'FirebaseFirestore': Streams data in real-time from the 'notifications' collection.
///    - 'AuthProvider': Provides the 'userId' used to filter the stream.
/// 2. PROCESSING:
///    - Real-time Streaming: Uses 'StreamBuilder' to update the UI the second a
///      backend admin approves a request.
///    - Mark-as-Read Logic: Updates the Firestore document field 'isRead' to true
///      when the user taps an item.
/// 3. SENDS DATA TO:
///    - 'FirebaseFirestore': To update the 'isRead' status.
/// 4. OUTPUTS/GUI:
///    - A vertical list of alert cards with status-specific icons.
///    - A bottom sheet 'Details' view for long messages or admin instructions.
library;

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/auth_provider.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // DATA SOURCE: Retrieving current user ID from state.
    final auth = context.read<AuthProvider>();
    final userId = auth.user?.uid;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: userId == null
          ? const Center(child: Text('Unauthorized'))
          : StreamBuilder<QuerySnapshot>(
              // STEP: Creating a live pipe to the database.
              // Logic: Give me only notifications where userId matches mine.
              stream: FirebaseFirestore.instance
                  .collection('notifications')
                  .where('userId', isEqualTo: userId)
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                // UI: Handling error states (e.g., connection lost).
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            size: 48,
                            color: Colors.red,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Error: ${snapshot.error}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                // UI: Loading state.
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                // UI: Empty state.
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.notifications_off_outlined,
                          size: 64,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No notifications yet',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                // STEP: Rendering the list of alerts from the streamed data.
                return ListView.builder(
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final data =
                        snapshot.data!.docs[index].data()
                            as Map<String, dynamic>;
                    final bool isRead = data['isRead'] ?? false;

                    return Card(
                      // GUI: Visual cue for unread vs read notifications.
                      color: isRead ? Colors.white : Colors.red[50],
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: ListTile(
                        leading: Icon(
                          _getIconForType(data['type']),
                          color: theme.primaryColor,
                        ),
                        title: Text(
                          data['title'] ?? 'Notification',
                          style: TextStyle(
                            fontWeight: isRead
                                ? FontWeight.normal
                                : FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(data['body'] ?? ''),
                        trailing: Text(
                          _formatDate(data['createdAt']),
                          style: const TextStyle(fontSize: 12),
                        ),
                        onTap: () {
                          // ACTION: Write data back to Firestore to update status.
                          FirebaseFirestore.instance
                              .collection('notifications')
                              .doc(snapshot.data!.docs[index].id)
                              .update({'isRead': true});

                          // GUI: Show the detailed popup.
                          _showNotificationDetails(context, data);
                        },
                      ),
                    );
                  },
                );
              },
            ),
    );
  }

  /// UI COMPONENT: Details Popup.
  /// Logic: Receives the map of notification data and renders it in a clean bottom sheet.
  void _showNotificationDetails(
    BuildContext context,
    Map<String, dynamic> data,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    _getIconForType(data['type']),
                    color: Theme.of(context).primaryColor,
                    size: 32,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      data['title'] ?? 'Notification Details',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(height: 32),
              Text(
                'Date Received: ${_formatDate(data['createdAt'])}',
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              // DATA DISPLAY: The core message from the Admin/System.
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Text(
                  data['body'] ?? 'No additional details provided.',
                  style: const TextStyle(fontSize: 16, height: 1.5),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Close'),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  // --- UI HELPER: Maps backend 'type' strings to GUI icons ---
  IconData _getIconForType(String? type) {
    switch (type) {
      case 'request_approved':
        return Icons.check_circle_outline;
      case 'request_rejected':
        return Icons.highlight_off;
      case 'request_on_progress':
        return Icons.loop;
      case 'new_donation':
        return Icons.volunteer_activism;
      default:
        return Icons.notifications;
    }
  }

  // --- UI HELPER: Converts Firestore Timestamp into a readable String ---
  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return '';
    final DateTime date = (timestamp as Timestamp).toDate();
    return '${date.day}/${date.month} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
