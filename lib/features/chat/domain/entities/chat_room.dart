import 'package:cloud_firestore/cloud_firestore.dart';

class ChatRoomEntity {
  final String id;
  final List<String> participants;
  final String lastMessage;
  final DateTime lastUpdateTime;
  final Map<String, dynamic>? participantNames;

  ChatRoomEntity({
    required this.id,
    required this.participants,
    required this.lastMessage,
    required this.lastUpdateTime,
    this.participantNames,
  });

  factory ChatRoomEntity.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChatRoomEntity(
      id: doc.id,
      participants: List<String>.from(data['participants'] ?? []),
      lastMessage: data['lastMessage'] ?? '',
      lastUpdateTime: (data['lastUpdateTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      participantNames: data['participantNames'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'participants': participants,
      'lastMessage': lastMessage,
      'lastUpdateTime': Timestamp.fromDate(lastUpdateTime),
      'participantNames': participantNames,
    };
  }
}
