import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../widgets/super_admin_drawer.dart';
import '../../auth/domain/entities/user.dart';
import '../../hospital/domain/entities/hospital.dart';
import '../../blood_request/domain/entities/blood_request.dart';
import '../presentation/providers/super_admin_provider.dart';
import '../../hospital/presentation/providers/hospital_provider.dart';
import '../../blood_request/presentation/providers/blood_request_provider.dart';

class SuperAdminDashboard extends StatelessWidget {
  const SuperAdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final superAdminProvider = context.read<SuperAdminProvider>();
    final hospitalProvider = context.read<HospitalProvider>();
    final bloodRequestProvider = context.read<BloodRequestProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Super Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none),
            onPressed: () {},
          ),
        ],
      ),
      drawer: const SuperAdminDrawer(),
      body: StreamBuilder<List<BloodRequestEntity>>(
        stream: bloodRequestProvider.streamAllRequests(),
        builder: (context, requestSnapshot) {
          return StreamBuilder<List<UserEntity>>(
            stream: superAdminProvider.streamAllUsers(),
            builder: (context, userSnapshot) {
              return StreamBuilder<List<HospitalEntity>>(
                stream: hospitalProvider.streamHospitals(),
                builder: (context, hospitalSnapshot) {
                  final requests = requestSnapshot.data ?? [];
                  final users = userSnapshot.data ?? [];
                  final hospitals = hospitalSnapshot.data ?? [];

                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(),
                        const SizedBox(height: 24),

                        // --- Top Metrics Row ---
                        Row(
                          children: [
                            Expanded(
                              child: _buildMetricTile(
                                'Total Users',
                                users.length.toString(),
                                Icons.people,
                                Colors.blue,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildMetricTile(
                                'Active Hospitals',
                                hospitals.length.toString(),
                                Icons.local_hospital,
                                Colors.green,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildMetricTile(
                                'Pending Requests',
                                requests
                                    .where((r) =>
                                        r.status == 'pending' &&
                                        r.type == 'Request')
                                    .length
                                    .toString(),
                                Icons.emergency,
                                Colors.red,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildMetricTile(
                                'Total Donations',
                                requests
                                    .where((r) => r.type == 'Donate')
                                    .length
                                    .toString(),
                                Icons.volunteer_activism,
                                Colors.orange,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 32),
                        _buildSectionTitle('Global Supply vs. Demand'),
                        const SizedBox(height: 16),
                        _buildDemandSupplyChart(requests),

                        const SizedBox(height: 32),
                        _buildSectionTitle('Platform Health'),
                        const SizedBox(height: 16),
                        _buildGlobalInventorySection(hospitals),

                        const SizedBox(height: 32),
                        _buildSectionTitle('User Growth (Last 7 Days)'),
                        const SizedBox(height: 16),
                        _buildGrowthChart(users),
                        const SizedBox(height: 40),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Command Center',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
        ),
        Text(
          DateFormat('EEEE, MMMM d').format(DateTime.now()),
          style: TextStyle(color: Colors.grey[600], fontSize: 16),
        ),
      ],
    );
  }

  Widget _buildMetricTile(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          Text(
            title,
            style: TextStyle(color: Colors.grey[600], fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildDemandSupplyChart(List<BloodRequestEntity> requests) {
    final pendingRequests =
        requests.where((r) => r.status == 'pending' && r.type == 'Request').length;
    final completedDonations =
        requests.where((r) => r.status == 'completed' && r.type == 'Donate').length;

    return Container(
      height: 200,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: (pendingRequests > completedDonations ? pendingRequests : completedDonations) + 5.0,
          barTouchData: BarTouchData(enabled: false),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  switch (value.toInt()) {
                    case 0:
                      return const Text('Pending Req', style: TextStyle(fontSize: 10));
                    case 1:
                      return const Text('Served Don', style: TextStyle(fontSize: 10));
                    default:
                      return const Text('');
                  }
                },
              ),
            ),
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          barGroups: [
            BarChartGroupData(
              x: 0,
              barRods: [
                BarChartRodData(
                  toY: pendingRequests.toDouble(),
                  color: Colors.redAccent,
                  width: 30,
                  borderRadius: BorderRadius.circular(6),
                ),
              ],
            ),
            BarChartGroupData(
              x: 1,
              barRods: [
                BarChartRodData(
                  toY: completedDonations.toDouble(),
                  color: Colors.greenAccent,
                  width: 30,
                  borderRadius: BorderRadius.circular(6),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGrowthChart(List<UserEntity> users) {
    final now = DateTime.now();
    final spots = List.generate(7, (index) {
      final day = now.subtract(Duration(days: 6 - index));
      final count = users.where((u) => u.createdAt.isBefore(day)).length;
      return FlSpot(index.toDouble(), count.toDouble());
    });

    return Container(
      height: 200,
      padding: const EdgeInsets.only(right: 24, top: 24, bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: false),
          titlesData: const FlTitlesData(
            show: true,
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: Colors.blue,
              barWidth: 4,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: Colors.blue.withOpacity(0.1),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlobalInventorySection(List<HospitalEntity> hospitals) {
    int totalDiversity = 0;
    for (var h in hospitals) {
      totalDiversity += h.availableBloodTypes.length;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.red[700]!, Colors.red[400]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          const Icon(Icons.water_drop, color: Colors.white, size: 48),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Global Stock Diversity',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                Text(
                  '$totalDiversity Active Stocks',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  'Aggregated across all registered facilities',
                  style: TextStyle(color: Colors.white54, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
