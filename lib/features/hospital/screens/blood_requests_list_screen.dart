library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/models/blood_request_model.dart';
import '../../../core/services/database_service.dart';
import '../../../core/services/api_service.dart';
import '../../../core/providers/auth_provider.dart';
import '../../chat/services/chat_service.dart';
import '../../chat/screens/chat_room_screen.dart';
import '../widgets/hospital_admin_drawer.dart';
import '../widgets/no_hospital_assigned.dart';
import '../../../core/models/user_model.dart';
import '../../../core/models/inventory_model.dart';

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
      appBar: AppBar(
        title: const Text('Hospital Requests'),
        elevation: 0,
        centerTitle: true,
      ),
      drawer: const HospitalAdminDrawer(),
      body: hospitalId == null || hospitalId.isEmpty
          ? const NoHospitalAssigned()
          : Column(
              children: [
                _buildFilterRow(),
                Expanded(
                  child: StreamBuilder<List<BloodRequestModel>>(
                    stream: _db.streamHospitalRequests(hospitalId),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) return _buildErrorView(snapshot.error);
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final allRequests = snapshot.data ?? [];
                      final filteredRequests = _selectedFilter == 'All'
                          ? allRequests
                          : allRequests.where((req) => req.status.toLowerCase() == _selectedFilter.toLowerCase()).toList();

                      if (filteredRequests.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey[300]),
                              const SizedBox(height: 16),
                              Text('No ${_selectedFilter.toLowerCase()} requests.', style: TextStyle(color: Colors.grey[500])),
                            ],
                          ),
                        );
                      }

                      return ListView.builder(
                        itemCount: filteredRequests.length,
                        padding: const EdgeInsets.only(bottom: 24),
                        itemBuilder: (context, index) {
                          final req = filteredRequests[index];
                          return _buildRequestCard(req, index);
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
            child: ChoiceChip(
              label: Text(filter),
              selected: isSelected,
              onSelected: (selected) => setState(() => _selectedFilter = filter),
              selectedColor: Colors.red.withValues(alpha: 0.1),
              backgroundColor: Colors.white,
              labelStyle: TextStyle(
                color: isSelected ? Colors.red : Colors.grey[600],
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              padding: const EdgeInsets.symmetric(horizontal: 12),
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
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) {
          final isDonation = req.type == 'Donate';
          final accentColor = isDonation ? Colors.blue : Colors.red;

          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: FutureBuilder<UserModel?>(
              future: _db.getUser(req.userId),
              builder: (context, userSnapshot) {
                final userProfile = userSnapshot.data;

                return StreamBuilder<List<InventoryModel>>(
                  stream: _db.streamInventory(req.hospitalId),
                  builder: (context, invSnapshot) {
                    final inventory = invSnapshot.data ?? [];
                    final stockItem = inventory.firstWhere(
                      (i) => i.bloodType == req.bloodType,
                      orElse: () => InventoryModel(
                        bloodType: req.bloodType,
                        units: 0,
                        lastUpdated: DateTime.now(),
                      ),
                    );

                    return Column(
                      children: [
                        // Handle
                        Container(
                          margin: const EdgeInsets.symmetric(vertical: 12),
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        Expanded(
                          child: ListView(
                            controller: scrollController,
                            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                            children: [
                              // --- HEADER SECTION ---
                              Row(
                                children: [
                                  _buildTypeIndicator(req.bloodType, accentColor),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          req.userName,
                                          style: const TextStyle(
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: -0.5,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Icon(
                                              isDonation ? Icons.favorite_border : Icons.emergency_outlined,
                                              size: 14,
                                              color: accentColor,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              isDonation ? 'BLOOD DONATION' : (req.urgency?.toUpperCase() ?? 'REQUEST'),
                                              style: TextStyle(
                                                color: req.urgency == 'Emergency' ? Colors.red : accentColor,
                                                fontSize: 11,
                                                fontWeight: FontWeight.w900,
                                                letterSpacing: 1.0,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  _statusChip(req.status, large: true),
                                ],
                              ),
                              const SizedBox(height: 24),

                              // --- INVENTORY INSIGHT ---
                              if (!isDonation) _buildInventoryInsight(req, stockItem),
                              const SizedBox(height: 24),

                              // --- QUICK ACTIONS ---
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: () => _openChat(context, req),
                                      icon: const Icon(Icons.forum_outlined),
                                      label: const Text('Direct Chat'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.blue[700],
                                        foregroundColor: Colors.white,
                                        elevation: 0,
                                        padding: const EdgeInsets.symmetric(vertical: 16),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 32),

                              // --- REQUESTER PROFILE ---
                              _sectionTitle('Requester Profile'),
                              const SizedBox(height: 12),
                              _buildProfileCard(userProfile, req),
                              const SizedBox(height: 24),

                              _sectionTitle('Transaction Details'),
                              const SizedBox(height: 12),
                              _buildDetailsCard(req, isDonation, accentColor),
                              const SizedBox(height: 24),

                              if (!isDonation) ...[
                                _sectionTitle('Medical Context'),
                                const SizedBox(height: 12),
                                _buildMedicalContextCard(req),
                                const SizedBox(height: 32),
                              ],

                              // --- MANAGEMENT HUD ---
                              _sectionTitle('Process Case'),
                              const SizedBox(height: 12),
                              _buildUpdateStatusSection(context, req),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildTypeIndicator(String type, Color color) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        shape: BoxShape.circle,
        border: Border.all(color: color.withValues(alpha: 0.2), width: 1.5),
      ),
      child: Center(
        child: Text(
          type,
          style: TextStyle(
            color: color,
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }

  Widget _buildRequestCard(BloodRequestModel req, int index) {
    final isDonation = req.type == 'Donate';
    final accentColor = isDonation ? Colors.blue : Colors.red;

    return Dismissible(
      key: Key(req.id ?? index.toString()),
      background: _swipeBg(Colors.green, Icons.check, Alignment.centerLeft),
      secondaryBackground: _swipeBg(Colors.red, Icons.close, Alignment.centerRight),
      confirmDismiss: (direction) async {
        final newStatus = direction == DismissDirection.startToEnd ? 'completed' : 'rejected';
        await _api.updateRequestStatus(
          req.id!,
          newStatus,
          adminMessage: 'Status updated via swipe.',
        );
        return true;
      },
      child: GestureDetector(
        onTap: () => _showDetailedRequestView(context, req),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: IntrinsicHeight(
            child: Row(
              children: [
                // Activity gradient strip
                Container(
                  width: 6,
                  decoration: BoxDecoration(
                    color: accentColor,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      bottomLeft: Radius.circular(20),
                    ),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [accentColor, accentColor.withValues(alpha: 0.5)],
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _formatDate(req.createdAt).toUpperCase(),
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.2,
                              ),
                            ),
                            _statusChip(req.status),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                             Expanded(
                               child: Column(
                                 crossAxisAlignment: CrossAxisAlignment.start,
                                 children: [
                                   Text(
                                     !isDonation && req.patientName != null && req.patientName!.isNotEmpty
                                         ? 'PATIENT: ${req.patientName}'
                                         : req.userName,
                                     style: const TextStyle(
                                       fontSize: 18,
                                       fontWeight: FontWeight.bold,
                                       letterSpacing: -0.5,
                                     ),
                                   ),
                                   if (!isDonation)
                                     Text(
                                       'Requested by ${req.userName}',
                                       style: TextStyle(color: Colors.grey[500], fontSize: 11),
                                     ),
                                 ],
                               ),
                             ),
                             Container(
                               padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                               decoration: BoxDecoration(
                                 color: accentColor.withValues(alpha: 0.08),
                                 borderRadius: BorderRadius.circular(8),
                               ),
                               child: Text(
                                 req.bloodType,
                                 style: TextStyle(
                                   color: accentColor,
                                   fontWeight: FontWeight.w900,
                                   fontSize: 14,
                                 ),
                               ),
                             ),
                           ],
                         ),
                         if (!isDonation && req.urgency == 'Emergency') ...[
                           const SizedBox(height: 8),
                           Container(
                             padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                             decoration: BoxDecoration(
                               color: Colors.red[700],
                               borderRadius: BorderRadius.circular(8),
                             ),
                             child: const Row(
                               mainAxisSize: MainAxisSize.min,
                               children: [
                                 Icon(Icons.flash_on, color: Colors.white, size: 12),
                                 SizedBox(width: 4),
                                 Text(
                                   'EMERGENCY PRIORITY',
                                   style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900),
                                 ),
                               ],
                             ),
                           ),
                         ],
                         const SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(Icons.water_drop_outlined, size: 14, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Text(
                              '${req.quantity} Units needed',
                              style: TextStyle(color: Colors.grey[700], fontSize: 13, fontWeight: FontWeight.w500),
                            ),
                            const Spacer(),
                            if (req.preferredDate != null)
                              Row(
                                children: [
                                  const Icon(Icons.event_available, size: 14, color: Colors.green),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${req.preferredDate} @ ${req.preferredTime}',
                                    style: TextStyle(color: Colors.green[700], fontSize: 11, fontWeight: FontWeight.w900),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInventoryInsight(BloodRequestModel req, InventoryModel stock) {
    final hasEnough = stock.units >= req.quantity;
    final statusColor = hasEnough ? Colors.green : Colors.orange;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(
            hasEnough ? Icons.check_circle_outline : Icons.warning_amber_rounded,
            color: statusColor,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Inventory Insight',
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                Text(
                  hasEnough
                      ? 'You have enough stock fulfill this request (${stock.units} Units available).'
                      : 'Stock is low. Only ${stock.units} Units of ${req.bloodType} available.',
                  style: TextStyle(color: statusColor.withValues(alpha: 0.8), fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard(UserModel? user, BloodRequestModel req) {
    if (user == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(child: Text('Loading verified profile details...')),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          _profileRow(Icons.person_outline, 'Full Name', '${user.firstName} ${user.lastName}'),
          const Divider(height: 24),
          _profileRow(Icons.family_restroom_outlined, 'Father\'s Name', user.fatherName),
          const Divider(height: 24),
          _profileRow(
            user.gender.toLowerCase() == 'male' ? Icons.male : Icons.female,
            'Gender',
            user.gender,
          ),
          const Divider(height: 24),
          _profileRow(Icons.location_on_outlined, 'Verified Address', user.address),
          const Divider(height: 24),
          _profileRow(Icons.map_outlined, 'Region', '${user.city}, ${user.region}'),
        ],
      ),
    );
  }

  Widget _profileRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.blueGrey),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 11, fontWeight: FontWeight.bold)),
            Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
          ],
        ),
      ],
    );
  }

  Widget _buildDetailsCard(BloodRequestModel req, bool isDonation, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          _detailRow(Icons.water_drop, 'Case Quantity', '${req.quantity} Units', color: color),
          const Divider(height: 24),
          _detailRow(Icons.phone, 'Direct Contact', req.contactNumber),
          if (req.preferredDate != null) ...[
            const Divider(height: 24),
            _detailRow(Icons.event, 'Requested Appointment', req.preferredDate!),
            const Divider(height: 24),
            _detailRow(Icons.schedule, 'Preferred Window', req.preferredTime ?? 'Any Time'),
          ],
          const Divider(height: 24),
          _detailRow(Icons.calendar_today, 'Original Submission', _formatDate(req.createdAt, full: true)),
        ],
      ),
    );
  }

  Widget _buildMedicalContextCard(BloodRequestModel req) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          _detailRow(Icons.personal_video_outlined, 'Patient Name', req.patientName ?? 'N/A'),
          const Divider(height: 24),
          _detailRow(Icons.emergency_outlined, 'Urgency Level', req.urgency ?? 'Regular'),
          const Divider(height: 24),
          _detailRow(Icons.meeting_room_outlined, 'Hospital Ward / Room', req.hospitalWard ?? 'Not specified'),
          const Divider(height: 24),
          _detailRow(Icons.medical_services_outlined, 'Reason / Diagnosis', req.medicalReason ?? 'No reason provided'),
        ],
      ),
    );
  }

  Future<void> _openChat(BuildContext context, BloodRequestModel req) async {
    final auth = context.read<AuthProvider>();
    final currentAdmin = auth.user;
    if (currentAdmin == null) return;

    final chatService = ChatService();
    final participantId = currentAdmin.hospitalId ?? currentAdmin.uid;
    final chatId = await chatService.createOrGetChat(
      participantId,
      req.userId,
      {
        participantId: currentAdmin.hospitalId != null ? 'Hospital Admin' : 'Admin',
        req.userId: req.userName,
      },
    );

    if (!context.mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatRoomScreen(
          chatRoomId: chatId,
          otherParticipantName: req.userName,
        ),
      ),
    );
  }

  Widget _statusChip(String status, {bool large = false}) {
    final color = _getStatusColor(status);
    final isPending = status.toLowerCase() == 'pending';

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: large ? 16 : 8,
        vertical: large ? 8 : 4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(large ? 12 : 8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          fontSize: large ? 12 : 10,
          fontWeight: FontWeight.bold,
          color: isPending ? Colors.orange[900] : color,
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
                debugPrint('Error updating request status: $e');
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

  // UI Helpers
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

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.5,
      ),
    );
  }

  String _formatDate(DateTime date, {bool full = false}) {
    if (full) {
      return DateFormat('MMM d, yyyy · h:mm a').format(date);
    }
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else {
      return DateFormat('MMM d').format(date);
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green[700]!;
      case 'rejected':
        return Colors.red[700]!;
      case 'on progress':
        return Colors.blue[700]!;
      default:
        return Colors.orange[700]!;
    }
  }

  Widget _buildErrorView(Object? error) {
    return Center(
      child: Text('Error: $error', style: const TextStyle(color: Colors.red)),
    );
  }
}
