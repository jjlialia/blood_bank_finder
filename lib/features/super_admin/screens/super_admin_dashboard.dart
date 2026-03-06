import 'package:flutter/material.dart';
import '../widgets/super_admin_drawer.dart';
import '../../../services/database_service.dart';
import '../../../models/user_model.dart';
import '../../../models/hospital_model.dart';
import '../../../models/blood_request_model.dart';

class SuperAdminDashboard extends StatelessWidget {
  const SuperAdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
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
            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildStatCard(
                  stream: db.streamAllUsers(),
                  title: 'Total Users',
                  icon: Icons.people,
                  color: Colors.blue,
                  getValue: (List<UserModel> data) => data.length.toString(),
                ),
                _buildStatCard(
                  stream: db.streamHospitals(),
                  title: 'Hospitals',
                  icon: Icons.local_hospital,
                  color: Colors.green,
                  getValue: (List<HospitalModel> data) =>
                      data.length.toString(),
                ),
                _buildStatCard(
                  stream: db.streamAllBloodRequests(),
                  title: 'Pending Requests',
                  icon: Icons.emergency,
                  color: Colors.red,
                  getValue: (List<BloodRequestModel> data) => data
                      .where(
                        (r) => r.status == 'pending' && r.type == 'Request',
                      )
                      .length
                      .toString(),
                ),
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
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
