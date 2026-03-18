/**
 * FILE: super_admin_dashboard.dart
 * 
 * DESCRIPTION:
 * The primary system command center. It provides the Super Admin with a 
 * macro-level view of the entire platform's health, aggregating data 
 * across all users and all hospital facilities.
 * 
 * DATA FLOW OVERVIEW:
 * 1. RECEIVES DATA FROM: 
 *    - 'DatabaseService.streamAllUsers': For total population count.
 *    - 'DatabaseService.streamHospitals': For facility infrastructure count.
 *    - 'DatabaseService.streamAllBloodRequests': For system-wide request and 
 *       donation metrics.
 * 2. PROCESSING:
 *    - Data Aggregation: Counts objects in the streamed lists.
 *    - Specific Filtering: Separates 'Requests' from 'Donations' using 
 *      the 'type' field in the shared request stream.
 * 3. SENDS DATA TO:
 *    - GUI: Updates the four primary stat cards in real-time as the 
 *      database changes.
 * 4. OUTPUTS/GUI:
 *    - A high-contrast grid of "Executive Stat Cards" (Users, Hospitals, 
 *      Pending Requests, Total Donations).
 */

import 'package:flutter/material.dart';
import '../widgets/super_admin_drawer.dart';
import '../../../core/services/database_service.dart';
import '../../../core/models/user_model.dart';
import '../../../core/models/hospital_model.dart';
import '../../../core/models/blood_request_model.dart';

class SuperAdminDashboard extends StatelessWidget {
  const SuperAdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    // DATA SOURCE: Global data streams for the entire platform.
    final DatabaseService db = DatabaseService();

    return Scaffold(
      appBar: AppBar(title: const Text('Super Admin Dashboard')),
      drawer: const SuperAdminDrawer(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'System Overview',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            // --- SECTION: Executive Metric Cards ---
            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                // DATA FLOW: Firestore (all users) -> UI.
                _buildStatCard(
                  stream: db.streamAllUsers(),
                  title: 'Total Users',
                  icon: Icons.people,
                  color: Colors.blue,
                  getValue: (List<UserModel> data) => data.length.toString(),
                ),
                // DATA FLOW: Firestore (all hospitals) -> UI.
                _buildStatCard(
                  stream: db.streamHospitals(),
                  title: 'Hospitals',
                  icon: Icons.local_hospital,
                  color: Colors.green,
                  getValue: (List<HospitalModel> data) => data.length.toString(),
                ),
                // DATA FLOW: Firestore (requests) -> Client Filter (Status=Pending && Type=Request) -> UI.
                _buildStatCard(
                  stream: db.streamAllBloodRequests(),
                  title: 'Pending Requests',
                  icon: Icons.emergency,
                  color: Colors.red,
                  getValue: (List<BloodRequestModel> data) => data
                      .where((r) => r.status == 'pending' && r.type == 'Request').length.toString(),
                ),
                // DATA FLOW: Firestore (requests) -> Client Filter (Type=Donate) -> UI.
                _buildStatCard(
                  stream: db.streamAllBloodRequests(),
                  title: 'Total Donations',
                  icon: Icons.volunteer_activism,
                  color: Colors.orange,
                  getValue: (List<BloodRequestModel> data) =>
                      data.where((r) => r.type == 'Donate').length.toString(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --- UI COMPONENT: Reusable Metric Card with Live Animation ---
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: color),
              const SizedBox(height: 12),
              Text(count, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, color: Colors.grey)),
            ],
          ),
        );
      },
    );
  }
}
