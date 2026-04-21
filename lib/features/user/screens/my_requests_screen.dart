library;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/models/blood_request_model.dart';
import '../../../core/models/hospital_model.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/services/database_service.dart';

class MyRequestsScreen extends StatelessWidget {
  const MyRequestsScreen({super.key});


  // ── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final uid = auth.user?.uid;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My History'),
        centerTitle: true,
        elevation: 0,
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
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
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

  @override
  Widget build(BuildContext context) {
    final isRequest = item.type.toLowerCase() == 'request';
    final accentColor = isRequest ? Colors.red[800]! : Colors.blue[800]!;
    final statusColor = _statusColor(item.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            // Status/Type accent strip
            Container(
              width: 8,
              decoration: BoxDecoration(
                color: statusColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  bottomLeft: Radius.circular(24),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header: Date & Status
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          DateFormat('MMM d, yyyy').format(item.createdAt).toUpperCase(),
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                          ),
                        ),
                        _statusChip(item.status),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Core Info: Blood Type & Hospital
                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: accentColor.withValues(alpha: 0.08),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              item.bloodType,
                              style: TextStyle(
                                color: accentColor,
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.hospitalName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                  letterSpacing: -0.2,
                                ),
                              ),
                              FutureBuilder<HospitalModel?>(
                                future: DatabaseService().getHospital(item.hospitalId),
                                builder: (context, snapshot) {
                                  if (snapshot.hasData && snapshot.data != null) {
                                    return Text(
                                      snapshot.data!.address,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                    );
                                  }
                                  return const SizedBox(height: 14);
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Details: Quantity & Appointment
                    Row(
                      children: [
                        Icon(Icons.water_drop_outlined, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          '${item.quantity.toInt()} Unit(s)',
                          style: TextStyle(color: Colors.grey[700], fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                        const Spacer(),
                        if (item.preferredDate != null)
                          Row(
                            children: [
                              Icon(Icons.calendar_month_outlined, size: 14, color: Colors.grey[600]),
                              const SizedBox(width: 4),
                              Text(
                                '${item.preferredDate} @ ${item.preferredTime}',
                                style: TextStyle(color: Colors.grey[700], fontSize: 11, fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                      ],
                    ),
                    
                    // Admin Message or Instructions
                    if (item.adminMessage != null && item.adminMessage!.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.info_outline, size: 14, color: Colors.blueGrey),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                item.adminMessage!,
                                style: TextStyle(color: Colors.blueGrey[700], fontSize: 12, height: 1.4),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else if (item.status.toLowerCase() == 'approved') ...[
                      const SizedBox(height: 20),
                      _buildInstructionSection(accentColor),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusChip(String status) {
    final color = _statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildInstructionSection(Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Icon(Icons.directions_bus_outlined, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Please visit the hospital at your scheduled time.',
              style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
