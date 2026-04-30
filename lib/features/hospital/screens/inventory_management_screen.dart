import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../domain/entities/inventory.dart';
import '../presentation/providers/hospital_provider.dart';
import '../widgets/hospital_admin_drawer.dart';
import '../widgets/no_hospital_assigned.dart';
import '../../super_admin/domain/entities/audit_log.dart';
import '../../super_admin/presentation/providers/super_admin_provider.dart';

class InventoryManagementScreen extends StatefulWidget {
  const InventoryManagementScreen({super.key});

  @override
  State<InventoryManagementScreen> createState() => _InventoryManagementScreenState();
}

class _InventoryManagementScreenState extends State<InventoryManagementScreen> {
  final Map<String, TextEditingController> _controllers = {};

  final List<String> bloodTypes = [
    'A+', 'A-', 'B+', 'B-', 'O+', 'O-', 'AB+', 'AB-',
  ];

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  TextEditingController _getController(String type, double initialValue) {
    if (!_controllers.containsKey(type)) {
      _controllers[type] = TextEditingController(text: initialValue.toInt().toString());
    }
    return _controllers[type]!;
  }

  Future<void> _updateStock(
    BuildContext context, 
    String hospitalId, 
    String type, 
    double currentUnits
  ) async {
    final controller = _controllers[type];
    if (controller == null) return;

    final newUnits = double.tryParse(controller.text);
    if (newUnits == null || newUnits < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid quantity'), backgroundColor: Colors.orange),
      );
      return;
    }

    if (newUnits == currentUnits) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No changes made')),
      );
      return;
    }

    final hospitalProvider = context.read<HospitalProvider>();
    final authProvider = context.read<AuthProvider>();
    final superAdminProvider = context.read<SuperAdminProvider>();

    try {
      final newInventory = InventoryEntity(
        bloodType: type,
        units: newUnits,
        status: newUnits < 5 ? 'Low Stock' : 'Available',
        lastUpdated: DateTime.now(),
      );

      final error = await hospitalProvider.updateInventory(hospitalId, newInventory);
      if (error != null) throw error;

      // Log the action
      final user = authProvider.userEntity;
      if (user != null) {
        final auditLog = AuditLogEntity(
          id: '',
          action: 'Update Inventory',
          category: 'inventory',
          description: 'Updated $type stock from ${currentUnits.toInt()} to ${newUnits.toInt()} units',
          userId: user.uid,
          userName: '${user.firstName} ${user.lastName}',
          userRole: user.role,
          timestamp: DateTime.now(),
          metadata: {
            'hospitalId': hospitalId,
            'bloodType': type,
            'oldUnits': currentUnits,
            'newUnits': newUnits,
          },
        );
        await superAdminProvider.logAction(auditLog);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Inventory updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final hospitalId = auth.user?.hospitalId;
    final hospitalProvider = context.read<HospitalProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory Control'),
        elevation: 0,
      ),
      drawer: const HospitalAdminDrawer(),
      body: hospitalId == null || hospitalId.isEmpty
          ? const NoHospitalAssigned()
          : StreamBuilder<List<InventoryEntity>>(
              stream: hospitalProvider.streamInventory(hospitalId),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline, color: Colors.red, size: 48),
                          const SizedBox(height: 16),
                          Text(
                            'Error loading inventory: ${snapshot.error}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.red),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () => setState(() {}),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final inventoryMap = {
                  for (var item in (snapshot.data ?? []))
                    item.bloodType: item.units,
                };

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  itemCount: bloodTypes.length,
                  itemBuilder: (context, index) {
                    final type = bloodTypes[index];
                    final units = inventoryMap[type] ?? 0.0;
                    final controller = _getController(type, units);

                    // If the controller value is different from the remote value 
                    // AND the user isn't currently interacting with this specific field, update it.
                    // (Simple check: if the field is not focused)
                    // Note: We use a FocusNode for better precision if needed, but for now this is okay.
                    if (double.tryParse(controller.text) != units) {
                       // Only update if the user is not actively typing (this is tricky with just one focus scope)
                       // For now, let's just ensure that if the remote data arrives, it can populate the fields.
                       if (controller.text.isEmpty || (snapshot.connectionState == ConnectionState.active && units > 0 && controller.text == "0")) {
                         controller.text = units.toInt().toString();
                       }
                    }

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                              child: Text(
                                type,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).primaryColor,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Available Units',
                                    style: TextStyle(fontSize: 12, color: Colors.grey),
                                  ),
                                  Text(
                                    '${units.toInt()} Units',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(
                              width: 80,
                              child: TextField(
                                controller: controller,
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                                decoration: InputDecoration(
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            IconButton(
                              onPressed: () => _updateStock(context, hospitalId, type, units),
                              icon: const Icon(Icons.save),
                              color: Theme.of(context).primaryColor,
                              tooltip: 'Update',
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
