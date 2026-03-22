library;

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
    // DATA SOURCE: Retrieving the linked hospital ID.
    final auth = context.read<AuthProvider>();
    final hospitalId = auth.user?.hospitalId;
    final DatabaseService db = DatabaseService();

    return Scaffold(
      appBar: AppBar(title: const Text('Hospital Admin Dashboard')),
      drawer: const HospitalAdminDrawer(),
      // SECURITY GATE: Redirect if the admin isn't assigned to a collection yet.
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
                  // --- SECTION: High-Level Stat Cards ---
                  GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      // DATA FLOW: Database -> Filter (Pending) -> Count.
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
                      // DATA FLOW: Database -> Filter (Units < 5) -> Count.
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
                    'Quick Inventory Status',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  // --- SECTION: Visual Inventory Bars ---
                  _buildInventorySummary(db, hospitalId),
                ],
              ),
            ),
    );
  }

  // --- UI HELPER: Reusable Stat Card with Stream Integration ---
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
        );
      },
    );
  }

  // --- UI COMPONENT: The Inventory Bar Chart ---
  Widget _buildInventorySummary(DatabaseService db, String hospitalId) {
    return StreamBuilder<List<InventoryModel>>(
      stream: db.streamInventory(hospitalId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const LinearProgressIndicator();

        final items = snapshot.data!;
        if (items.isEmpty) {
          return const Center(child: Text('Add data in Inventory section.'));
        }

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: items.take(6).map((i) {
                // DATA MAPPING: Converting unit count into a 0-1 progress value.
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
                            style: const TextStyle(fontWeight: FontWeight.bold),
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
                      // GUI: Visual representation of stock capacity.
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

/// FILE: hospital_admin_dashboard.dart
///
/// DESCRIPTION:
/// The landing page for Hospital Administrators. It provides a real-time
/// executive summary of their site's health, including critical alerts
/// for pending emergency requests and low blood inventory.
///
/// DATA FLOW OVERVIEW:
/// 1. RECEIVES DATA FROM:
///    - 'AuthProvider': Retrieves the 'hospitalId' for the logged-in admin.
///    - 'DatabaseService': Streams both 'blood_requests' and 'inventory'
///       data for a single hospital.
/// 2. PROCESSING:
///    - Aggregation: Calculates the count of 'pending' requests from the full list.
///    - Alert Logic: Identifies inventory items with less than 5 units remaining.
///    - Progress Calculation: Maps stock levels (0-20 units) to a visual % (0-1.0).
/// 3. SENDS DATA TO:
///    - Navigation: Links to 'InventoryManagementScreen' and 'BloodRequestsListScreen'.
/// 4. OUTPUTS/GUI:
///    - Stat Cards: Large indicators for urgent actions.
///    - Inventory Summary: Visual progress bars for quick stock inspection.
