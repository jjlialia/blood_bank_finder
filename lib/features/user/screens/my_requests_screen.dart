library;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/models/blood_request_model.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/services/database_service.dart';

class MyRequestsScreen extends StatelessWidget {
  const MyRequestsScreen({super.key});

  // ── Colour helpers ──────────────────────────────────────────────────────────

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
      case 'completed':
        return const Color(0xFF2E7D32); // green
      case 'rejected':
        return const Color(0xFFC62828); // red
      default:
        return const Color(0xFFF57F17); // amber – pending
    }
  }

  Color _statusBg(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
      case 'completed':
        return const Color(0xFFE8F5E9);
      case 'rejected':
        return const Color(0xFFFFEBEE);
      default:
        return const Color(0xFFFFF8E1);
    }
  }

  IconData _statusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Icons.check_circle_outline;
      case 'completed':
        return Icons.task_alt;
      case 'rejected':
        return Icons.cancel_outlined;
      default:
        return Icons.hourglass_top_outlined;
    }
  }

  // ── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final uid = auth.user?.uid;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Requests & Donations'),
        centerTitle: false,
      ),
      body: uid == null
          ? const Center(child: Text('Not logged in.'))
          : StreamBuilder<List<BloodRequestModel>>(
              stream: DatabaseService().streamUserRequests(uid),
              builder: (context, snapshot) {
                // Loading
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                // Error
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.error_outline,
                            size: 48,
                            color: theme.colorScheme.error),
                        const SizedBox(height: 8),
                        Text(
                          'Failed to load history.\n${snapshot.error}',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: theme.colorScheme.error),
                        ),
                      ],
                    ),
                  );
                }

                final items = snapshot.data ?? [];

                // Empty state
                if (items.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.history_toggle_off_outlined,
                          size: 72,
                          color: theme.primaryColor.withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No requests yet',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Your blood requests and donations\nwill appear here.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.black38, fontSize: 13),
                        ),
                      ],
                    ),
                  );
                }

                // List
                return ListView.separated(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 20),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) =>
                      _RequestCard(item: items[index]),
                );
              },
            ),
    );
  }
}

// ── Single card ──────────────────────────────────────────────────────────────

class _RequestCard extends StatelessWidget {
  const _RequestCard({required this.item});

  final BloodRequestModel item;

  Color _statusColor(String s) {
    switch (s.toLowerCase()) {
      case 'approved':
      case 'completed':
        return const Color(0xFF2E7D32);
      case 'rejected':
        return const Color(0xFFC62828);
      default:
        return const Color(0xFFF57F17);
    }
  }

  Color _statusBg(String s) {
    switch (s.toLowerCase()) {
      case 'approved':
      case 'completed':
        return const Color(0xFFE8F5E9);
      case 'rejected':
        return const Color(0xFFFFEBEE);
      default:
        return const Color(0xFFFFF8E1);
    }
  }

  IconData _statusIcon(String s) {
    switch (s.toLowerCase()) {
      case 'approved':
        return Icons.check_circle_outline;
      case 'completed':
        return Icons.task_alt;
      case 'rejected':
        return Icons.cancel_outlined;
      default:
        return Icons.hourglass_top_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isRequest = item.type.toLowerCase() == 'request';
    final typeColor =
        isRequest ? const Color(0xFFB71C1C) : const Color(0xFF1565C0);
    final typeBg =
        isRequest ? const Color(0xFFFFEBEE) : const Color(0xFFE3F2FD);
    final statusColor = _statusColor(item.status);
    final statusBg = _statusBg(item.status);
    final statusIcon = _statusIcon(item.status);

    return Card(
      elevation: 2,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Top row: type badge + status chip + date ──────────────────
            Row(
              children: [
                // Type badge
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: typeBg,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isRequest
                            ? Icons.emergency_outlined
                            : Icons.volunteer_activism_outlined,
                        size: 14,
                        color: typeColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isRequest ? 'Request' : 'Donation',
                        style: TextStyle(
                          color: typeColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                // Status chip
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 14, color: statusColor),
                      const SizedBox(width: 4),
                      Text(
                        _capitalize(item.status),
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // ── Blood type + quantity ─────────────────────────────────────
            Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: theme.primaryColor.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      item.bloodType,
                      style: TextStyle(
                        color: theme.primaryColor,
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.hospitalName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${item.quantity.toStringAsFixed(item.quantity == item.quantity.truncate() ? 0 : 1)} unit(s) · '
                        '${DateFormat('MMM d, yyyy').format(item.createdAt)}',
                        style: const TextStyle(
                            fontSize: 12, color: Colors.black54),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // ── Admin message (optional) ──────────────────────────────────
            if (item.adminMessage != null &&
                item.adminMessage!.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.admin_panel_settings_outlined,
                        size: 14, color: Colors.black45),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        item.adminMessage!,
                        style: const TextStyle(
                            fontSize: 12, color: Colors.black54),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}
