import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationEntity {
  final String? id;
  final String userId;
  final String message;
  final bool isRead;
  final DateTime createdAt;
  final String? type;
  final String? title;
  final String? body;
  final String? requestId;

  NotificationEntity({
    this.id,
    required this.userId,
    required this.message,
    required this.isRead,
    required this.createdAt,
    this.type,
    this.title,
    this.body,
    this.requestId,
  });

  factory NotificationEntity.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return NotificationEntity(
      id: doc.id,
      userId: data['userId'] ?? '',
      message: data['message'] ?? '',
      isRead: data['isRead'] ?? false,
      createdAt: data['createdAt'] is Timestamp 
          ? (data['createdAt'] as Timestamp).toDate() 
          : (data['createdAt'] as DateTime? ?? DateTime.now()),
      type: data['type'],
      title: data['title'],
      body: data['body'],
      requestId: data['requestId'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'message': message,
      'isRead': isRead,
      'createdAt': Timestamp.fromDate(createdAt),
      'type': type,
      'title': title,
      'body': body,
      'requestId': requestId,
    };
  }
}
