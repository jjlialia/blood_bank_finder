library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/services/database_service.dart';
import '../../../core/services/api_service.dart';
import '../../../core/models/inventory_model.dart';
import '../../../core/models/audit_log_model.dart';
import '../widgets/hospital_admin_drawer.dart';
import '../widgets/no_hospital_assigned.dart';

class InventoryManagementScreen extends StatelessWidget {
  const InventoryManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final hospitalId = auth.user?.hospitalId;
    final DatabaseService db = DatabaseService();

    final List<String> bloodTypes = [
      'A+',
      'A-',
      'B+',
      'B-',
      'O+',
      'O-',
      'AB+',
      'AB-',
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Inventory Control')),
      drawer: const HospitalAdminDrawer(),
      // security check
      body: hospitalId == null || hospitalId.isEmpty
          ? const NoHospitalAssigned()
          : StreamBuilder<List<InventoryModel>>(
              stream: db.streamInventory(hospitalId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final inventoryMap = {
                  for (var item in (snapshot.data ?? []))
                    item.bloodType: item.units,
                };

                return ListView.builder(
                  itemCount: bloodTypes.length,
                  itemBuilder: (context, index) {
                    final type = bloodTypes[index];
                    final units = inventoryMap[type] ?? 0.0;

                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: ListTile(
                        title: Text(
                          type,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        subtitle: Text('Inventory: $units Units'),
                        trailing: SizedBox(
                          width: 100,
                          child: TextField(
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            textAlign: TextAlign.center,
                            decoration: const InputDecoration(
                              hintText: 'Qty',
                              isDense: true,
                              border: OutlineInputBorder(),
                            ),

                            onSubmitted: (value) async {
                              final newUnits = double.tryParse(value);
                              if (newUnits != null && newUnits >= 0) {
                                final api = ApiService();
                                try {
                                  // STEP: Trigger the backend update.
                                  await api.updateInventory(
                                    hospitalId,
                                    type,
                                    newUnits,
                                  );

                                  // Audit Log
                                  final user = auth.user;
                                  if (user != null) {
                                    await db.logAction(AuditLogModel(
                                      id: '',
                                      action: 'INVENTORY_UPDATED',
                                      category: 'Inventory',
                                      description: '${user.firstName} updated $type stock to $newUnits units.',
                                      userId: user.uid,
                                      userName: '${user.firstName} ${user.lastName}',
                                      userRole: user.role,
                                      timestamp: DateTime.now(),
                                      metadata: {
                                        'hospitalId': hospitalId,
                                        'bloodType': type,
                                        'newUnits': newUnits,
                                        'oldUnits': units,
                                      },
                                    ));
                                  }

                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Updated $type to $newUnits via FastAPI',
                                        ),
                                        duration: const Duration(seconds: 1),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Failed: ${e.toString()}',
                                        ),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                }
                              }
                            },
                          ),
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
