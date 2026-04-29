import 'package:cloud_firestore/cloud_firestore.dart';

class MessageEntity {
  final String id;
  final String senderId;
  final String text;
  final DateTime timestamp;
  final bool isRead;

  MessageEntity({
    required this.id,
    required this.senderId,
    required this.text,
    required this.timestamp,
    required this.isRead,
  });

  factory MessageEntity.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MessageEntity(
      id: doc.id,
      senderId: data['senderId'] ?? '',
      text: data['text'] ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isRead: data['isRead'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'senderId': senderId,
      'text': text,
      'timestamp': Timestamp.fromDate(timestamp),
      'isRead': isRead,
    };
  }
}
