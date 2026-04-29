import 'package:cloud_firestore/cloud_firestore.dart';

class AuditLogEntity {
  final String id;
  final String action;
  final String category;
  final String description;
  final String userId;
  final String userName;
  final String userRole;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;

  AuditLogEntity({
    required this.id,
    required this.action,
    required this.category,
    required this.description,
    required this.userId,
    required this.userName,
    required this.userRole,
    required this.timestamp,
    this.metadata,
  });

  factory AuditLogEntity.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AuditLogEntity(
      id: doc.id,
      action: data['action'] ?? '',
      category: data['category'] ?? '',
      description: data['description'] ?? '',
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      userRole: data['userRole'] ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      metadata: data['metadata'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'action': action,
      'category': category,
      'description': description,
      'userId': userId,
      'userName': userName,
      'userRole': userRole,
      'timestamp': Timestamp.fromDate(timestamp),
      'metadata': metadata,
    };
  }
}
