import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/chat_room.dart';
import '../../domain/entities/message.dart';
import '../../domain/repositories/chat_repository.dart';

class FirestoreChatRepository implements IChatRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Stream<List<ChatRoomEntity>> getChatRoomsStream(String userId) {
    return _firestore
        .collection('chats')
        .where('participants', arrayContains: userId)
        .snapshots()
        .map((snapshot) {
      final rooms = snapshot.docs
          .map((doc) => ChatRoomEntity.fromFirestore(doc))
          .toList();
      rooms.sort((a, b) => b.lastUpdateTime.compareTo(a.lastUpdateTime));
      return rooms;
    });
  }

  @override
  Stream<List<MessageEntity>> getMessagesStream(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => MessageEntity.fromFirestore(doc)).toList());
  }

  @override
  Future<void> sendMessage(String chatId, String senderId, String text) async {
    final messageData = {
      'senderId': senderId,
      'text': text,
      'timestamp': FieldValue.serverTimestamp(),
      'isRead': false,
    };

    await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .add(messageData);

    await _firestore.collection('chats').doc(chatId).update({
      'lastMessage': text,
      'lastUpdateTime': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<String> createOrGetChat(
    String currentUserId,
    String otherUserId,
    Map<String, dynamic>? names,
  ) async {
    final ids = [currentUserId, otherUserId];
    ids.sort();
    final chatId = ids.join('_');

    final docRef = _firestore.collection('chats').doc(chatId);
    final docSnapshot = await docRef.get();

    if (!docSnapshot.exists) {
      final newChat = ChatRoomEntity(
        id: chatId,
        participants: [currentUserId, otherUserId],
        lastMessage: '',
        lastUpdateTime: DateTime.now(),
        participantNames: names,
      );
      await docRef.set(newChat.toFirestore());
    }

    return chatId;
  }
  @override
  Future<void> markMessagesAsRead(String chatId, String userId) async {
    final messages = await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .where('isRead', isEqualTo: false)
        .get();

    final batch = _firestore.batch();
    bool hasUpdates = false;
    for (var doc in messages.docs) {
      if (doc.data()['senderId'] != userId) {
        batch.update(doc.reference, {'isRead': true});
        hasUpdates = true;
      }
    }
    if (hasUpdates) {
      await batch.commit();
    }
  }
}
