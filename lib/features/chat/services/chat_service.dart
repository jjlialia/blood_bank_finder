import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/chat_room_model.dart';
import '../models/message_model.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get stream of chat rooms for a specific user
  Stream<List<ChatRoom>> getChatRoomsStream(String userId) {
    return _firestore
        .collection('chats')
        .where('participants', arrayContains: userId)
        // Removed .orderBy to prevent the Firebase Composite Index Error
        .snapshots()
        .map((snapshot) {
           final rooms = snapshot.docs
            .map((doc) => ChatRoom.fromFirestore(doc))
            .toList();
           
           // Sort the chats locally in Dart
           rooms.sort((a, b) => b.lastUpdateTime.compareTo(a.lastUpdateTime));
           return rooms;
        });
  }

  // Get stream of messages for a specific chat room
  Stream<List<Message>> getMessagesStream(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true) // Most recent first
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Message.fromFirestore(doc))
            .toList());
  }

  // Send a message
  Future<void> sendMessage(String chatId, String senderId, String text) async {
    final messageData = {
      'senderId': senderId,
      'text': text,
      'timestamp': FieldValue.serverTimestamp(),
      'isRead': false,
    };

    // Add message to subcollection
    await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .add(messageData);

    // Update the last message in the chat room document
    await _firestore.collection('chats').doc(chatId).update({
      'lastMessage': text,
      'lastUpdateTime': FieldValue.serverTimestamp(),
    });
  }

  // Initialize a new chat if it doesn't exist
  Future<String> createOrGetChat(
      String currentUserId, String otherUserId, Map<String, dynamic>? names) async {
    // Generate an ID (sort them to always be the same regardless of who starts)
    final ids = [currentUserId, otherUserId];
    ids.sort();
    final chatId = ids.join('_');

    final docRef = _firestore.collection('chats').doc(chatId);
    final docSnapshot = await docRef.get();

    if (!docSnapshot.exists) {
      final newChat = ChatRoom(
        id: chatId,
        participants: [currentUserId, otherUserId],
        lastMessage: '',
        lastUpdateTime: DateTime.now(),
        participantNames: names,
      );
      // Wait, the toMap will use serverTimestamp for lastUpdateTime.
      await docRef.set(newChat.toMap());
    }

    return chatId;
  }
}
