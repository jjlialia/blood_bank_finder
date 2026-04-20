library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/models/blood_request_model.dart';
import '../../../core/services/database_service.dart';
import '../../../core/services/api_service.dart';
import '../../../core/providers/auth_provider.dart';
import '../widgets/hospital_admin_drawer.dart';
import '../widgets/no_hospital_assigned.dart';

class BloodRequestsListScreen extends StatefulWidget {
  const BloodRequestsListScreen({super.key});

  @override
  State<BloodRequestsListScreen> createState() =>
      _BloodRequestsListScreenState();
}

class _BloodRequestsListScreenState extends State<BloodRequestsListScreen> {
  final DatabaseService _db = DatabaseService();
  final ApiService _api = ApiService();

  //Controls what requests are visible in the GUI.
  String _selectedFilter = 'All';
  final List<String> _filters = [
    'All',
    'Pending',
    'On Progress',
    'Completed',
    'Rejected',
  ];

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final hospitalId = auth.user?.hospitalId;

    return Scaffold(
      appBar: AppBar(title: const Text('Hospital Requests')),
      drawer: const HospitalAdminDrawer(),
      body: hospitalId == null || hospitalId.isEmpty
          ? const NoHospitalAssigned()
          : Column(
              children: [
                _buildFilterRow(),
                Expanded(
                  child: StreamBuilder<List<BloodRequestModel>>(
                    // STREAM
                    stream: _db.streamHospitalRequests(hospitalId),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return _buildErrorView(snapshot.error);
                      }
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      // Client-side filtering based on UI chips.
                      final allRequests = snapshot.data ?? [];
                      final filteredRequests = _selectedFilter == 'All'
                          ? allRequests
                          : allRequests
                                .where(
                                  (req) =>
                                      req.status.toLowerCase() ==
                                      _selectedFilter.toLowerCase(),
                                )
                                .toList();

                      if (filteredRequests.isEmpty) {
                        return Center(
                          child: Text(
                            'No ${_selectedFilter.toLowerCase()} requests.',
                          ),
                        );
                      }

                      return ListView.builder(
                        itemCount: filteredRequests.length,
                        itemBuilder: (context, index) {
                          final req = filteredRequests[index];

                          // Quick Swipe to Approve/Reject.
                          return Dismissible(
                            key: Key(req.id ?? index.toString()),
                            background: _swipeBg(
                              Colors.green,
                              Icons.check,
                              Alignment.centerLeft,
                            ),
                            secondaryBackground: _swipeBg(
                              Colors.red,
                              Icons.close,
                              Alignment.centerRight,
                            ),
                            confirmDismiss: (direction) async {
                              final newStatus =
                                  direction == DismissDirection.startToEnd
                                  ? 'completed'
                                  : 'rejected';
                              await _api.updateRequestStatus(
                                req.id!,
                                newStatus,
                                adminMessage: 'Status updated via swipe.',
                              );
                              return true;
                            },
                            child: Card(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              child: ListTile(
                                title: Text(
                                  '${req.userName} (${req.bloodType})',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Text(
                                  'Type: ${req.type} | Units: ${req.quantity}',
                                ),
                                trailing: Chip(
                                  label: Text(
                                    req.status.toUpperCase(),
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  backgroundColor: _getStatusColor(req.status),
                                ),
                                onTap: () =>
                                    _showDetailedRequestView(context, req),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildFilterRow() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: _filters.map((filter) {
          final isSelected = _selectedFilter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: FilterChip(
              label: Text(filter),
              selected: isSelected,
              onSelected: (selected) =>
                  setState(() => _selectedFilter = filter),
              selectedColor: Colors.red[50],
            ),
          );
        }).toList(),
      ),
    );
  }

  void _showDetailedRequestView(BuildContext context, BloodRequestModel req) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => Padding(
          padding: const EdgeInsets.all(24.0),
          child: ListView(
            controller: scrollController,
            children: [
              _detailRow(Icons.person, 'Patient Name', req.userName),
              _detailRow(
                Icons.bloodtype,
                'Blood Type',
                req.bloodType,
                color: Colors.red,
              ),
              _detailRow(Icons.category, 'Request Type', req.type),
              _detailRow(Icons.water_drop, 'Units Needed', '${req.quantity}'),
              _detailRow(Icons.phone, 'Contact Number', req.contactNumber),
              const Divider(height: 32),
              const Text(
                'Update Status & Notify User',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _buildUpdateStatusSection(context, req),
            ],
          ),
        ),
      ),
    );
  }

  //Status Update Section
  Widget _buildUpdateStatusSection(
    BuildContext context,
    BloodRequestModel req,
  ) {
    String selectedStatus = req.status;
    final messageController = TextEditingController();

    return StatefulBuilder(
      builder: (context, setModalState) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DropdownButtonFormField<String>(
            initialValue: selectedStatus,
            decoration: const InputDecoration(labelText: 'New Status'),
            items: ['pending', 'on progress', 'completed', 'rejected']
                .map(
                  (s) =>
                      DropdownMenuItem(value: s, child: Text(s.toUpperCase())),
                )
                .toList(),
            onChanged: (v) => setModalState(() => selectedStatus = v!),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: messageController,
            decoration: const InputDecoration(
              labelText: 'Message for patient (Optional)',
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () async {
              try {
                //Saves status and triggers alert to the user.
                await _api.updateRequestStatus(
                  req.id!,
                  selectedStatus,
                  adminMessage: messageController.text.isNotEmpty
                      ? messageController.text
                      : null,
                );
                if (context.mounted) Navigator.pop(context);
              } catch (e) {
                /* Error handeled by ApiService logic */
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirm Changes'),
          ),
        ],
      ),
    );
  }

  //ui helper
  Widget _swipeBg(Color color, IconData icon, Alignment align) {
    return Container(
      color: color,
      alignment: align,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Icon(icon, color: Colors.white),
    );
  }

  Widget _detailRow(IconData icon, String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color ?? Colors.grey[700]),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(value, style: const TextStyle(fontSize: 16)),
            ],
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green[100]!;
      case 'rejected':
        return Colors.red[100]!;
      case 'on progress':
        return Colors.blue[100]!;
      default:
        return Colors.orange[100]!;
    }
  }

  Widget _buildErrorView(Object? error) {
    return Center(
      child: Text('Error: $error', style: const TextStyle(color: Colors.red)),
    );
  }
}
