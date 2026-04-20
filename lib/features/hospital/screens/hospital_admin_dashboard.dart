library;

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../widgets/hospital_admin_drawer.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/services/database_service.dart';
import '../../../core/models/blood_request_model.dart';
import '../../../core/models/inventory_model.dart';
import '../widgets/no_hospital_assigned.dart';

class HospitalAdminDashboard extends StatelessWidget {
  const HospitalAdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final hospitalId = auth.user?.hospitalId;
    final DatabaseService db = DatabaseService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hospital Admin Dashboard'),
        elevation: 0,
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      drawer: const HospitalAdminDrawer(),
      body: hospitalId == null || hospitalId.isEmpty
          ? const NoHospitalAssigned()
          : StreamBuilder<List<BloodRequestModel>>(
              stream: db.streamHospitalRequests(hospitalId),
              builder: (context, requestSnap) {
                return StreamBuilder<List<InventoryModel>>(
                  stream: db.streamInventory(hospitalId),
                  builder: (context, inventorySnap) {
                    if (requestSnap.connectionState == ConnectionState.waiting ||
                        inventorySnap.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final requests = requestSnap.data ?? [];
                    final inventory = inventorySnap.data ?? [];

                    // Calculate Stats ---
                    final pendingCount =
                        requests.where((r) => r.status == 'pending').length;
                    
                    final now = DateTime.now();
                    final donationsThisMonth = requests.where((r) => 
                      r.type == 'Donate' && 
                      r.status == 'completed' &&
                      r.createdAt.month == now.month &&
                      r.createdAt.year == now.year
                    ).length;

                    final lowStockTypes =
                        inventory.where((i) => i.units < 5).toList();

                    return SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeader('Hospital Overview'),
                          const SizedBox(height: 16),
                          
                          // Stat row 1
                          Row(
                            children: [
                              Expanded(
                                child: _buildStatCardPlain(
                                  title: 'Pending Requests',
                                  value: pendingCount.toString(),
                                  icon: Icons.emergency_share,
                                  color: Colors.redAccent,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildStatCardPlain(
                                  title: 'Donations (Month)',
                                  value: donationsThisMonth.toString(),
                                  icon: Icons.volunteer_activism,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Activity Chart ---
                          _buildHeader('Weekly Activity (Last 7 Days)'),
                          const SizedBox(height: 12),
                          _buildActivityChart(requests),
                          const SizedBox(height: 24),

                          // Critical Alerts ---
                          if (lowStockTypes.isNotEmpty) ...[
                            _buildHeader('Critical Stock Alerts'),
                            const SizedBox(height: 8),
                            _buildAlertsList(lowStockTypes),
                            const SizedBox(height: 24),
                          ],

                          _buildHeader('Inventory Status'),
                          const SizedBox(height: 12),
                          _buildInventorySummaryPlain(inventory),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
    );
  }

  Widget _buildHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildStatCardPlain({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          Text(
            title,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityChart(List<BloodRequestModel> requests) {
    final now = DateTime.now();
    final last7Days = List.generate(7, (i) {
      final date = now.subtract(Duration(days: 6 - i));
      return DateTime(date.year, date.month, date.day);
    });

    final Map<DateTime, int> requestCounts = {};
    final Map<DateTime, int> donationCounts = {};

    for (var date in last7Days) {
      requestCounts[date] = requests.where((r) => 
        r.type == 'Request' && 
        r.createdAt.year == date.year && 
        r.createdAt.month == date.month && 
        r.createdAt.day == date.day
      ).length;
      
      donationCounts[date] = requests.where((r) => 
        r.type == 'Donate' && 
        r.createdAt.year == date.year && 
        r.createdAt.month == date.month && 
        r.createdAt.day == date.day
      ).length;
    }

    return Container(
      height: 220,
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: 10, // Adjust based on data if needed
          barTouchData: BarTouchData(enabled: true),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= 7) return const Text('');
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      DateFormat('E').format(last7Days[index]),
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                  );
                },
              ),
            ),
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          barGroups: List.generate(7, (i) {
            return BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: requestCounts[last7Days[i]]!.toDouble(),
                  color: Colors.redAccent,
                  width: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
                BarChartRodData(
                  toY: donationCounts[last7Days[i]]!.toDouble(),
                  color: Colors.green,
                  width: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget _buildAlertsList(List<InventoryModel> alerts) {
    return Column(
      children: alerts.map((a) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orange.shade200),
        ),
        child: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.orange),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '${a.bloodType} is critically low: ${a.units} units',
                style: TextStyle(
                  color: Colors.orange.shade900,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      )).toList(),
    );
  }

  Widget _buildInventorySummaryPlain(List<InventoryModel> items) {
    if (items.isEmpty) {
      return const Center(child: Text('No inventory data.'));
    }
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: items.map((i) {
            final double progress = (i.units / 20).clamp(0.0, 1.0);
            final Color color = i.units < 5 ? Colors.red : Colors.green;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Type ${i.bloodType}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text('${i.units} Units', style: TextStyle(color: color, fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.grey[100],
                      color: color,
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
