import 'package:cloud_firestore/cloud_firestore.dart';

class AuditLogModel {
  final String id;
  final String action;
  final String category;
  final String description;
  final String userId;
  final String userName;
  final String userRole;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;

  AuditLogModel({
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

  factory AuditLogModel.fromMap(Map<String, dynamic> map, String documentId) {
    return AuditLogModel(
      id: documentId,
      action: map['action'] ?? '',
      category: map['category'] ?? '',
      description: map['description'] ?? '',
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      userRole: map['userRole'] ?? '',
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      metadata: map['metadata'] != null ? Map<String, dynamic>.from(map['metadata']) : null,
    );
  }

  Map<String, dynamic> toMap() {
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
