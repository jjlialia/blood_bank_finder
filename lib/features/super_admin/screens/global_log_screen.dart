import 'package:flutter/material.dart';
import '../../../core/models/blood_request_model.dart';
import '../../../core/services/database_service.dart';
import '../widgets/super_admin_drawer.dart';
import 'package:intl/intl.dart';

class GlobalLogScreen extends StatelessWidget {
  const GlobalLogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final DatabaseService db = DatabaseService();

    return Scaffold(
      appBar: AppBar(title: const Text('Global Requests Log')),
      drawer: const SuperAdminDrawer(),
      body: StreamBuilder<List<BloodRequestModel>>(
        stream: db.streamAllBloodRequests(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text('No blood requests in the system.'),
            );
          }

          final logs = snapshot.data!;
          return ListView.builder(
            itemCount: logs.length,
            itemBuilder: (context, index) {
              final log = logs[index];
              final date = DateFormat(
                'MMM dd, yyyy HH:mm',
              ).format(log.createdAt);

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  isThreeLine: true,
                  leading: CircleAvatar(
                    backgroundColor: log.type == 'Request'
                        ? Colors.red[100]
                        : Colors.green[100],
                    child: Icon(
                      log.type == 'Request'
                          ? Icons.emergency
                          : Icons.volunteer_activism,
                      color: log.type == 'Request' ? Colors.red : Colors.green,
                    ),
                  ),
                  title: Text('${log.userName} (${log.bloodType})'),
                  subtitle: Text(
                    'To: ${log.hospitalName}\nStatus: ${log.status.toUpperCase()}\nDate: $date',
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
