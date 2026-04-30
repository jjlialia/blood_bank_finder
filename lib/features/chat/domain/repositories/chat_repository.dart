import '../entities/chat_room.dart';
import '../entities/message.dart';

abstract class IChatRepository {
  Stream<List<ChatRoomEntity>> getChatRoomsStream(String userId);
  Stream<List<MessageEntity>> getMessagesStream(String chatId);
  Future<void> sendMessage(String chatId, String senderId, String text);
  Future<String> createOrGetChat(String currentUserId, String otherUserId, Map<String, dynamic>? names);
  Future<void> markMessagesAsRead(String chatId, String userId);
}
