import 'package:flutter/material.dart';
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
    final hospitalId = auth.user?.hospitalId; // Changed from .uid
    final DatabaseService db = DatabaseService();

    return Scaffold(
      appBar: AppBar(title: const Text('Hospital Admin Dashboard')),
      drawer: const HospitalAdminDrawer(),
      body: hospitalId == null || hospitalId.isEmpty
          ? const NoHospitalAssigned()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hospital Overview',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _buildStatCard(
                        stream: db.streamHospitalRequests(hospitalId),
                        title: 'Pending Requests',
                        icon: Icons.emergency,
                        color: Colors.red,
                        getValue: (List<BloodRequestModel> data) => data
                            .where((r) => r.status == 'pending')
                            .length
                            .toString(),
                      ),
                      _buildStatCard(
                        stream: db.streamInventory(hospitalId),
                        title: 'Low Stock Alerts',
                        icon: Icons.warning,
                        color: Colors.orange,
                        getValue: (List<InventoryModel> data) =>
                            data.where((i) => i.units < 5).length.toString(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    'Quick Inventory',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  _buildInventorySummary(db, hospitalId),
                ],
              ),
            ),
    );
  }

  Widget _buildStatCard<T>({
    required Stream<T> stream,
    required String title,
    required IconData icon,
    required Color color,
    required String Function(T) getValue,
  }) {
    return StreamBuilder<T>(
      stream: stream,
      builder: (context, snapshot) {
        String count = '...';
        if (snapshot.hasData) {
          count = getValue(snapshot.data as T);
        }
        return Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 40, color: color),
                const SizedBox(height: 12),
                Text(
                  count,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInventorySummary(DatabaseService db, String hospitalId) {
    return StreamBuilder<List<InventoryModel>>(
      stream: db.streamInventory(hospitalId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const LinearProgressIndicator();

        final items = snapshot.data!;
        if (items.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: Text(
                'No inventory data. Add from Inventory screen.',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ),
          );
        }

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: items.take(6).map((i) {
                final double progress = (i.units / 20).clamp(0.0, 1.0);
                final Color color = i.units < 5 ? Colors.red : Colors.green;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Type ${i.bloodType}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            '${i.units} Units',
                            style: TextStyle(
                              color: color,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progress,
                          backgroundColor: Colors.grey[200],
                          valueColor: AlwaysStoppedAnimation<Color>(color),
                          minHeight: 8,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }
}
