import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/models/audit_log_model.dart';
import '../../../core/services/database_service.dart';
import '../widgets/super_admin_drawer.dart';

class AuditTrailScreen extends StatelessWidget {
  const AuditTrailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final DatabaseService db = DatabaseService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Security Audit Trail'),
        centerTitle: true,
      ),
      drawer: const SuperAdminDrawer(),
      body: StreamBuilder<List<AuditLogModel>>(
        stream: db.streamAuditLogs(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildEmptyState();
          }

          final logs = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: logs.length,
            itemBuilder: (context, index) {
              return _buildAuditItem(logs[index]);
            },
          );
        },
      ),
    );
  }

  Widget _buildAuditItem(AuditLogModel log) {
    IconData icon;
    Color color;

    switch (log.category.toLowerCase()) {
      case 'auth':
        icon = Icons.lock_outline;
        color = Colors.blue;
        break;
      case 'admin':
        icon = Icons.admin_panel_settings_outlined;
        color = Colors.purple;
        break;
      case 'inventory':
        icon = Icons.inventory_2_outlined;
        color = Colors.orange;
        break;
      default:
        icon = Icons.info_outline;
        color = Colors.grey;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.withValues(alpha: 0.1)),
      ),
      elevation: 0,
      borderOnForeground: true,
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.1),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(
          log.description,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        subtitle: Text(
          '${DateFormat('MMM d, h:mm a').format(log.timestamp)} • ${log.userName}',
          style: TextStyle(color: Colors.grey[600], fontSize: 12),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow('Action', log.action),
                _buildDetailRow('User Role', log.userRole),
                _buildDetailRow('User ID', log.userId),
                if (log.metadata != null) ...[
                  const Divider(),
                  const Text('Metadata:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  const SizedBox(height: 4),
                  ...log.metadata!.entries.map((e) => _buildDetailRow(e.key, e.value.toString())),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text('$label:', style: const TextStyle(color: Colors.grey, fontSize: 12)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shield_outlined, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'No security logs found.',
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
        ],
      ),
    );
  }
}
