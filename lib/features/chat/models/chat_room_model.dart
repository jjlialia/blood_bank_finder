import 'package:cloud_firestore/cloud_firestore.dart';

class ChatRoom {
  final String id;
  final List<String> participants;
  final String lastMessage;
  final DateTime lastUpdateTime;
  final Map<String, dynamic>?
  participantNames; //para name sa participant ang ipakita

  ChatRoom({
    required this.id,
    required this.participants,
    required this.lastMessage,
    required this.lastUpdateTime,
    this.participantNames,
  });

  factory ChatRoom.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return ChatRoom(
      id: doc.id,
      participants: List<String>.from(data['participants'] ?? []),
      lastMessage: data['lastMessage'] ?? '',
      lastUpdateTime:
          (data['lastUpdateTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      participantNames: data['participantNames'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'participants': participants,
      'lastMessage': lastMessage,
      'lastUpdateTime': FieldValue.serverTimestamp(),
      'participantNames': participantNames,
    };
  }
}
