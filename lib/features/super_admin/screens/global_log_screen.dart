import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../blood_request/domain/entities/blood_request.dart';
import '../../blood_request/presentation/providers/blood_request_provider.dart';
import '../widgets/super_admin_drawer.dart';
import 'package:intl/intl.dart';

class GlobalLogScreen extends StatelessWidget {
  const GlobalLogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bloodRequestProvider = context.read<BloodRequestProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('System Audit Trail')),
      drawer: const SuperAdminDrawer(),
      body: StreamBuilder<List<BloodRequestEntity>>(
        stream: bloodRequestProvider.streamAllRequests(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildEmptyState();
          }

          final logs = snapshot.data!;
          // Sort by date descending
          logs.sort((a, b) => b.createdAt.compareTo(a.createdAt));

          return Column(
            children: [
              _buildAuditHeader(logs.length),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: logs.length,
                  itemBuilder: (context, index) {
                    final log = logs[index];
                    return _buildTimelineItem(
                      log,
                      isFirst: index == 0,
                      isLast: index == logs.length - 1,
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAuditHeader(int total) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      color: Colors.grey[50],
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.history, color: Colors.blue, size: 20),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Recent Activity',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                '$total events tracked platform-wide',
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(BloodRequestEntity log,
      {required bool isFirst, required bool isLast}) {
    final isRequest = log.type == 'Request';
    final accentColor = isRequest ? Colors.red : Colors.green;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 40,
            child: Column(
              children: [
                Container(
                  width: 2,
                  height: 20,
                  color: isFirst ? Colors.transparent : Colors.grey[300],
                ),
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: accentColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: accentColor.withOpacity(0.2),
                        spreadRadius: 2,
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Container(
                    width: 2,
                    color: isLast ? Colors.transparent : Colors.grey[300],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey[200]!),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      offset: const Offset(0, 2),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatRelativeTime(log.createdAt),
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        _statusTag(log.status),
                      ],
                    ),
                    const SizedBox(height: 8),
                    RichText(
                      text: TextSpan(
                        style: const TextStyle(color: Colors.black87, fontSize: 14),
                        children: [
                          TextSpan(
                            text: log.userName,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          TextSpan(
                            text: isRequest
                                ? ' requested blood '
                                : ' volunteered to donate ',
                          ),
                          TextSpan(
                            text: '(${log.bloodType}) ',
                            style: TextStyle(
                              color: accentColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const TextSpan(text: 'at '),
                          TextSpan(
                            text: log.hospitalName,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(Icons.water_drop_outlined,
                            size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          '${log.quantity} unit(s)',
                          style: TextStyle(color: Colors.grey[600], fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusTag(String status) {
    Color color;
    switch (status.toLowerCase()) {
      case 'completed':
        color = Colors.green;
        break;
      case 'rejected':
        color = Colors.red;
        break;
      case 'on progress':
        color = Colors.blue;
        break;
      default:
        color = Colors.orange;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  String _formatRelativeTime(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) return 'JUST NOW';
    if (diff.inMinutes < 60) return '${diff.inMinutes}M AGO';
    if (diff.inHours < 24) return '${diff.inHours}H AGO';
    return DateFormat('MMM d').format(date).toUpperCase();
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_toggle_off, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'No system activity recorded yet.',
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
        ],
      ),
    );
  }
}
