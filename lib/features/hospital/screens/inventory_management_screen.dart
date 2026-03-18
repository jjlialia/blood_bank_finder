/**
 * FILE: inventory_management_screen.dart
 * 
 * DESCRIPTION:
 * This screen provides Hospital Admins with direct control over their 
 * site's blood stock levels. It lists all standard blood groups and 
 * allows for precise unit updates.
 * 
 * DATA FLOW OVERVIEW:
 * 1. RECEIVES DATA FROM: 
 *    - 'AuthProvider': Retrieves the 'hospitalId' to identify which site's 
 *      inventory to manage.
 *    - 'DatabaseService': Streams the current units for each blood type 
 *      in real-time from Firestore.
 * 2. PROCESSING:
 *    - Input Mapping: Matches the streamed inventory data to a static 
 *      list of standard blood types (A+, O-, etc.).
 *    - Validation: Ensures new unit counts are valid numbers (>= 0).
 * 3. SENDS DATA TO:
 *    - 'ApiService.updateInventory': Transmits the new stock level to the 
 *      FastAPI backend, which performs a safe transactional update.
 * 4. OUTPUTS/GUI:
 *    - A list of cards, each containing an editable 'Qty' text field.
 *    - Immediate feedback snackbars upon successful database updates.
 */

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/services/database_service.dart';
import '../../../core/services/api_service.dart';
import '../../../core/models/inventory_model.dart';
import '../widgets/hospital_admin_drawer.dart';
import '../widgets/no_hospital_assigned.dart';

class InventoryManagementScreen extends StatelessWidget {
  const InventoryManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // DATA SOURCE: Getting the Hospital ID from the Auth state.
    final auth = context.read<AuthProvider>();
    final hospitalId = auth.user?.hospitalId; 
    final DatabaseService db = DatabaseService();

    // GUI: The standard list of blood groups to manage.
    final List<String> bloodTypes = [
      'A+', 'A-', 'B+', 'B-', 'O+', 'O-', 'AB+', 'AB-',
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Inventory Control')),
      drawer: const HospitalAdminDrawer(),
      // SECURITY CHECK: Ensure the admin is actually linked to a hospital.
      body: hospitalId == null || hospitalId.isEmpty
          ? const NoHospitalAssigned()
          : StreamBuilder<List<InventoryModel>>(
              // STEP: Creating a live pipe to the hospital's inventory collection.
              stream: db.streamInventory(hospitalId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                // DATA TRANSFORMATION: Converting the list from Firestore into a 
                // searchable Map for the UI.
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
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        title: Text(
                          type,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                        subtitle: Text('Inventory: $units Units'),
                        trailing: SizedBox(
                          width: 100,
                          child: TextField(
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            textAlign: TextAlign.center,
                            decoration: const InputDecoration(
                              hintText: 'Qty',
                              isDense: true,
                              border: OutlineInputBorder(),
                            ),
                            /**
                             * CORE LOGIC: Inventory Update Flow.
                             * 1. RECEIVES: User types a number and presses 'Enter'.
                             * 2. PROCESSING: Validates the number format.
                             * 3. DATA JOURNEY: App -> ApiService -> FastAPI Backend -> Firestore Transaction.
                             * 4. FEEDBACK: Shows a success banner if the write is confirmed.
                             */
                            onSubmitted: (value) async {
                              final newUnits = double.tryParse(value);
                              if (newUnits != null && newUnits >= 0) {
                                final api = ApiService();
                                try {
                                  // STEP: Trigger the backend update.
                                  await api.updateInventory(hospitalId, type, newUnits);
                                  
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Updated $type to $newUnits via FastAPI'),
                                        duration: const Duration(seconds: 1),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Failed: ${e.toString()}'),
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
