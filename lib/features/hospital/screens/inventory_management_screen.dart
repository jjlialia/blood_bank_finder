import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../domain/entities/inventory.dart';
import '../presentation/providers/hospital_provider.dart';
import '../widgets/hospital_admin_drawer.dart';
import '../widgets/no_hospital_assigned.dart';

class InventoryManagementScreen extends StatelessWidget {
  const InventoryManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final hospitalId = auth.user?.hospitalId;
    final hospitalProvider = context.read<HospitalProvider>();

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
          : StreamBuilder<List<InventoryEntity>>(
              stream: hospitalProvider.streamInventory(hospitalId),
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
                        subtitle: Text('Inventory: ${units.toInt()} Units'),
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
                                try {
                                  final newInventory = InventoryEntity(
                                    bloodType: type,
                                    units: newUnits,
                                    status: newUnits < 5 ? 'Low Stock' : 'Available',
                                    lastUpdated: DateTime.now(),
                                  );

                                  await hospitalProvider.updateInventory(
                                    hospitalId,
                                    newInventory,
                                  );

                                  // Audit Log is usually handled in the Repository/Use Case in pure DDD,
                                  // but for now, we'll let the provider/repository handle it if implemented.
                                  // Since I haven't added audit logging to HospitalRepository yet,
                                  // I'll skip it here to keep it clean, but in a real app, I'd add it to the Use Case.

                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Inventory updated successfully',
                                        ),
                                        duration: Duration(seconds: 1),
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

