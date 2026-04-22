library;

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/models/blood_request_model.dart';
import '../../../core/services/database_service.dart';
import '../../../core/providers/auth_provider.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final userId = auth.user?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        centerTitle: true,
        elevation: 0,
      ),
      body: userId == null
          ? const Center(child: Text('Unauthorized'))
          : StreamBuilder<QuerySnapshot>(
              // Creating a live to the database.
              // Give only notifications where userId matches mine.
              stream: FirebaseFirestore.instance
                  .collection('notifications')
                  .where('userId', isEqualTo: userId)
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
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

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

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

                //Rendering the list of alerts from the streamed data.
                return ListView.builder(
                  itemCount: snapshot.data!.docs.length,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  itemBuilder: (context, index) {
                    final doc = snapshot.data!.docs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final bool isRead = data['isRead'] ?? false;
                    final String type = data['type'] ?? 'default';
                    final String body = data['body'] ?? '';
                    final accentColor = _getColorForType(type);

                    return GestureDetector(
                      onTap: () {
                        FirebaseFirestore.instance
                            .collection('notifications')
                            .doc(doc.id)
                            .update({'isRead': true});
                        _showNotificationDetails(context, data);
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: isRead ? Colors.black.withValues(alpha: 0.02) : accentColor.withValues(alpha: 0.08),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                          border: isRead ? Border.all(color: Colors.grey[100]!) : Border.all(color: accentColor.withValues(alpha: 0.1)),
                        ),
                        child: IntrinsicHeight(
                          child: Row(
                            children: [
                              Container(
                                width: 5,
                                decoration: BoxDecoration(
                                  color: isRead ? Colors.grey[300] : accentColor,
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(20),
                                    bottomLeft: Radius.circular(20),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: accentColor.withValues(alpha: 0.1),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          _getIconForType(type),
                                          color: accentColor,
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Text(
                                                  _formatRelativeTime(data['createdAt']),
                                                  style: TextStyle(
                                                    color: Colors.grey[400],
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w900,
                                                    letterSpacing: 0.5,
                                                  ),
                                                ),
                                                if (!isRead)
                                                  Container(
                                                    width: 8,
                                                    height: 8,
                                                    decoration: BoxDecoration(
                                                      color: accentColor,
                                                      shape: BoxShape.circle,
                                                    ),
                                                  ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              data['title'] ?? 'Notification',
                                              style: TextStyle(
                                                fontSize: 15,
                                                fontWeight: isRead ? FontWeight.w600 : FontWeight.w800,
                                                color: isRead ? Colors.black87 : Colors.black,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              body.contains('Schedule:') ? body.replaceAll('\n\n', '\n') : body,
                                              maxLines: 3,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: Colors.grey[600],
                                                height: 1.3,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }

  /// Details Popup.
  ///Receives map of notification data and renders a clean bottom sheet.
  void _showNotificationDetails(
    BuildContext context,
    Map<String, dynamic> data,
  ) {
    final accentColor = _getColorForType(data['type']);
    final String body = data['body'] ?? 'No additional details provided.';

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
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _getIconForType(data['type']),
                      color: accentColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data['title'] ?? 'Notification Details',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                        ),
                        Text(
                          'Received: ${_formatDate(data['createdAt'])}',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              //The core message from the Admin/System.
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: Border.all(color: Colors.grey[100]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 4,
                          height: 12,
                          decoration: BoxDecoration(
                            color: accentColor,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'OFFICIAL UPDATE',
                          style: TextStyle(
                            color: accentColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      body,
                      style: const TextStyle(
                        fontSize: 15,
                        height: 1.6,
                        color: Colors.black87,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // --- CASE SUMMARY CARD (Hospital Style) ---
              if (data['requestId'] != null)
                FutureBuilder<BloodRequestModel?>(
                  future: DatabaseService().getRequest(data['requestId']),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: LinearProgressIndicator());
                    }
                    final req = snapshot.data;
                    if (req == null) return const SizedBox.shrink();

                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.assignment_outlined, size: 16, color: Colors.blueGrey[700]),
                              const SizedBox(width: 8),
                              Text(
                                'CASE SUMMARY',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.blueGrey[700],
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 24),
                          _detailRow(Icons.person_outline, 'Patient', req.patientName ?? 'N/A'),
                          _detailRow(Icons.water_drop_outlined, 'Blood Type', req.bloodType),
                          _detailRow(Icons.layers_outlined, 'Quantity', '${req.quantity.toInt()} Units'),
                          _detailRow(
                            Icons.emergency_outlined,
                            'Urgency',
                            req.urgency ?? 'Regular',
                            valueColor: req.urgency == 'Emergency' ? Colors.red[700] : null,
                          ),
                          if (req.hospitalWard != null)
                            _detailRow(Icons.meeting_room_outlined, 'Location', req.hospitalWard!),
                        ],
                      ),
                    );
                  },
                ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Text(
            '$label:',
            style: TextStyle(color: Colors.grey[500], fontSize: 13, fontWeight: FontWeight.w500),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: valueColor ?? Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getColorForType(String? type) {
    switch (type) {
      case 'request_approved':
        return Colors.green;
      case 'request_rejected':
        return Colors.red;
      case 'request_on_progress':
        return Colors.blue;
      case 'new_donation':
        return Colors.purple;
      default:
        return Colors.blueGrey;
    }
  }

  String _formatRelativeTime(dynamic timestamp) {
    if (timestamp == null) return '';
    final DateTime date = (timestamp as Timestamp).toDate();
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) return 'JUST NOW';
    if (diff.inMinutes < 60) return '${diff.inMinutes}M AGO';
    if (diff.inHours < 24) return '${diff.inHours}H AGO';
    return DateFormat('MMM d').format(date).toUpperCase();
  }

  // ui helper for type
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

  // Converts Firestore Timestamp into a readable String ---
  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return '';
    final DateTime date = (timestamp as Timestamp).toDate();
    return '${date.day}/${date.month} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
