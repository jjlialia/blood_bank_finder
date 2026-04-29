import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../blood_request/domain/entities/blood_request.dart';
import '../../blood_request/presentation/providers/blood_request_provider.dart';
import '../../hospital/presentation/providers/hospital_provider.dart';
import '../../auth/domain/entities/user.dart';
import '../../super_admin/domain/entities/audit_log.dart';
import '../../super_admin/presentation/providers/super_admin_provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../chat/presentation/providers/chat_provider.dart';
import '../../chat/screens/chat_room_screen.dart';
import '../widgets/hospital_admin_drawer.dart';
import '../widgets/no_hospital_assigned.dart';
import '../../hospital/domain/entities/inventory.dart';

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
    final bloodRequestProvider = context.read<BloodRequestProvider>();

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
                  child: StreamBuilder<List<BloodRequestEntity>>(
                    stream: bloodRequestProvider.streamHospitalRequests(hospitalId),
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
              selectedColor: Colors.red.withOpacity(0.1),
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

  void _showDetailedRequestView(BuildContext context, BloodRequestEntity req) {
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
          final superAdminProvider = context.read<SuperAdminProvider>();
          final hospitalProvider = context.read<HospitalProvider>();

          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: FutureBuilder<UserEntity?>(
              future: superAdminProvider.getUser(req.userId),
              builder: (context, userSnapshot) {
                final userProfile = userSnapshot.data;

                return StreamBuilder<List<InventoryEntity>>(
                  stream: hospitalProvider.streamInventory(req.hospitalId),
                  builder: (context, invSnapshot) {
                    final inventory = invSnapshot.data ?? [];
                    final stockItem = inventory.firstWhere(
                      (i) => i.bloodType == req.bloodType,
                      orElse: () => InventoryEntity(
                        bloodType: req.bloodType,
                        units: 0,
                        status: 'Empty',
                        lastUpdated: DateTime.now(),
                      ),
                    );

                    return Column(
                      children: [
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
                              if (!isDonation) _buildInventoryInsight(req, stockItem),
                              const SizedBox(height: 24),
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
        color: color.withOpacity(0.1),
        shape: BoxShape.circle,
        border: Border.all(color: color.withOpacity(0.2), width: 1.5),
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

  Widget _buildRequestCard(BloodRequestEntity req, int index) {
    final isDonation = req.type == 'Donate';
    final accentColor = isDonation ? Colors.blue : Colors.red;

    return Dismissible(
      key: Key(req.id ?? index.toString()),
      background: _swipeBg(Colors.green, Icons.check, Alignment.centerLeft),
      confirmDismiss: (direction) async {
        final admin = context.read<AuthProvider>().user;
        final bloodRequestProvider = context.read<BloodRequestProvider>();
        final superAdminProvider = context.read<SuperAdminProvider>();
        final newStatus = direction == DismissDirection.startToEnd ? 'completed' : 'rejected';
        
        await bloodRequestProvider.updateRequestStatus(
          req.id!,
          newStatus,
          adminMessage: 'Status updated via swipe.',
        );

        if (admin != null) {
          await superAdminProvider.logAction(AuditLogEntity(
            id: '',
            action: 'REQUEST_STATUS_UPDATED',
            category: 'Admin',
            description: '${admin.firstName} ${newStatus == 'completed' ? 'approved/completed' : 'rejected'} ${req.userName}\'s ${req.type.toLowerCase()}.',
            userId: admin.uid,
            userName: '${admin.firstName} ${admin.lastName}',
            userRole: admin.role,
            timestamp: DateTime.now(),
            metadata: {
              'requestId': req.id,
              'newStatus': newStatus,
              'targetUser': req.userName,
              'method': 'swipe',
            },
          ));
        }
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
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: IntrinsicHeight(
            child: Row(
              children: [
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
                      colors: [accentColor, accentColor.withOpacity(0.5)],
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
                                 color: accentColor.withOpacity(0.08),
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

  Widget _buildInventoryInsight(BloodRequestEntity req, InventoryEntity stock) {
    final hasEnough = stock.units >= req.quantity;
    final statusColor = hasEnough ? Colors.green : Colors.orange;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withOpacity(0.2)),
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
                  style: TextStyle(color: statusColor.withOpacity(0.8), fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard(UserEntity? user, BloodRequestEntity req) {
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

  Widget _buildDetailsCard(BloodRequestEntity req, bool isDonation, Color color) {
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

  Widget _buildMedicalContextCard(BloodRequestEntity req) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.02),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          _detailRow(Icons.personal_video_outlined, 'Patient Name', req.patientName ?? 'N/A'),
          const Divider(height: 24),
          _detailRow(Icons.local_hospital_outlined, 'Admitted Hospital', req.patientHospital ?? 'Not specified'),
          const Divider(height: 24),
          _detailRow(Icons.emergency_outlined, 'Urgency Level', req.urgency ?? 'Regular'),
          const Divider(height: 24),
          _detailRow(Icons.meeting_room_outlined, 'Hospital Ward / Room', (req.hospitalWard == null || req.hospitalWard!.isEmpty) ? 'Not specified' : req.hospitalWard!),
          const Divider(height: 24),
          _detailRow(Icons.medical_services_outlined, 'Reason / Diagnosis', req.medicalReason ?? 'No reason provided'),
        ],
      ),
    );
  }

  Future<void> _openChat(BuildContext context, BloodRequestEntity req) async {
    final auth = context.read<AuthProvider>();
    final currentAdmin = auth.user;
    if (currentAdmin == null) return;

    final chatProvider = context.read<ChatProvider>();
    final participantId = currentAdmin.hospitalId ?? currentAdmin.uid;
    final chatId = await chatProvider.createOrGetChat(
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
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(large ? 12 : 8),
        border: Border.all(color: color.withOpacity(0.3)),
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

  Widget _buildUpdateStatusSection(
    BuildContext context,
    BloodRequestEntity req,
  ) {
    String selectedStatus = req.status;
    final messageController = TextEditingController();

    return StatefulBuilder(
      builder: (context, setModalState) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DropdownButtonFormField<String>(
            value: selectedStatus,
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
              final admin = context.read<AuthProvider>().user;
              final bloodRequestProvider = context.read<BloodRequestProvider>();
              final superAdminProvider = context.read<SuperAdminProvider>();

              try {
                await bloodRequestProvider.updateRequestStatus(
                  req.id!,
                  selectedStatus,
                  adminMessage: messageController.text.isNotEmpty
                      ? messageController.text
                      : null,
                );

                if (admin != null) {
                  await superAdminProvider.logAction(AuditLogEntity(
                    id: '',
                    action: 'REQUEST_STATUS_UPDATED',
                    category: 'Admin',
                    description: '${admin.firstName} updated ${req.userName}\'s ${req.type.toLowerCase()} status to $selectedStatus.',
                    userId: admin.uid,
                    userName: '${admin.firstName} ${admin.lastName}',
                    userRole: admin.role,
                    timestamp: DateTime.now(),
                    metadata: {
                      'requestId': req.id,
                      'newStatus': selectedStatus,
                      'targetUser': req.userName,
                      'adminMessage': messageController.text,
                    },
                  ));
                }

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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: color ?? Colors.blueGrey),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 11)),
                Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title.toUpperCase(),
      style: TextStyle(
        color: Colors.grey[600],
        fontSize: 11,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.5,
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'on progress':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date, {bool full = false}) {
    if (full) return DateFormat('MMMM d, yyyy • h:mm a').format(date);
    return DateFormat('MMM d, h:mm a').format(date);
  }

  Widget _buildErrorView(dynamic error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 16),
          Text('Something went wrong: $error'),
        ],
      ),
    );
  }
}
