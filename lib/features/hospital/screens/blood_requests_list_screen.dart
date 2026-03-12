import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/blood_request_model.dart';
import '../../../services/database_service.dart';
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
    final DatabaseService db = DatabaseService();

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
                    stream: db.streamHospitalRequests(hospitalId),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.error_outline,
                                  size: 48,
                                  color: Colors.red,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Error: ${snapshot.error}',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(color: Colors.red),
                                ),
                                if (snapshot.error.toString().contains('index'))
                                  const Padding(
                                    padding: EdgeInsets.only(top: 8.0),
                                    child: Text(
                                      'A Firestore index is likely missing. Check the debug console for a creation link.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      }
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

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
                            _selectedFilter == 'All'
                                ? 'No requests for this hospital.'
                                : 'No ${_selectedFilter.toLowerCase()} requests.',
                          ),
                        );
                      }

                      return ListView.builder(
                        itemCount: filteredRequests.length,
                        itemBuilder: (context, index) {
                          final req = filteredRequests[index];

                          return Dismissible(
                            key: Key(req.id ?? index.toString()),
                            background: Container(
                              color: Colors.green,
                              alignment: Alignment.centerLeft,
                              padding: const EdgeInsets.only(left: 20),
                              child: const Icon(
                                Icons.check,
                                color: Colors.white,
                              ),
                            ),
                            secondaryBackground: Container(
                              color: Colors.red,
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              child: const Icon(
                                Icons.close,
                                color: Colors.white,
                              ),
                            ),
                            confirmDismiss: (direction) async {
                              if (direction == DismissDirection.startToEnd) {
                                // Approve/Complete
                                await db.updateRequestStatusWithNotification(
                                  request: req,
                                  newStatus: 'completed',
                                  adminMessage: 'Approved via quick action.',
                                );
                                return true;
                              } else {
                                // Reject
                                await db.updateRequestStatusWithNotification(
                                  request: req,
                                  newStatus: 'rejected',
                                  adminMessage: 'Rejected via quick action.',
                                );
                                return true;
                              }
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
              onSelected: (selected) {
                setState(() {
                  _selectedFilter = filter;
                });
              },
              selectedColor: Colors.red[100],
              checkmarkColor: Colors.red,
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Request Details',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(),
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
              _detailRow(
                Icons.calendar_today,
                'Date Requested',
                '${req.createdAt.day}/${req.createdAt.month}/${req.createdAt.year} ${req.createdAt.hour}:${req.createdAt.minute.toString().padLeft(2, '0')}',
              ),
              const SizedBox(height: 16),
              if (req.adminMessage != null && req.adminMessage!.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blueGrey[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Previous Admin Note:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blueGrey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        req.adminMessage!,
                        style: const TextStyle(fontStyle: FontStyle.italic),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 24),
              const Text(
                'Update Status',
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

  Widget _buildUpdateStatusSection(
    BuildContext context,
    BloodRequestModel req,
  ) {
    String selectedStatus = req.status;
    final messageController = TextEditingController();
    final db = DatabaseService();

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
              labelText: 'Message for user (Optional)',
              hintText: 'e.g. Please proceed to the blood bank.',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () async {
              final navigator = Navigator.of(context);
              final scaffoldMessenger = ScaffoldMessenger.of(context);

              await db.updateRequestStatusWithNotification(
                request: req,
                newStatus: selectedStatus,
                adminMessage: messageController.text,
              );

              if (context.mounted) {
                navigator.pop();
                scaffoldMessenger.showSnackBar(
                  const SnackBar(content: Text('Request updated successfully')),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Save & Notify User'),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: color ?? Colors.grey[700]),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
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
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
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
}
