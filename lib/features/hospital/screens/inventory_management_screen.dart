import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../services/database_service.dart';
import '../../../models/inventory_model.dart';
import '../widgets/hospital_admin_drawer.dart';
import '../widgets/no_hospital_assigned.dart';

class InventoryManagementScreen extends StatelessWidget {
  const InventoryManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final hospitalId = auth.user?.hospitalId; // Use hospitalId instead of uid
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
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.remove_circle,
                                color: Colors.red,
                              ),
                              onPressed: () => db.updateInventory(
                                hospitalId,
                                type,
                                units > 0 ? units - 1 : 0,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.add_circle,
                                color: Colors.green,
                              ),
                              onPressed: () => db.updateInventory(
                                hospitalId,
                                type,
                                units + 1,
                              ),
                            ),
                          ],
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
