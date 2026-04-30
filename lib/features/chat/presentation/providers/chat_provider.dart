import 'package:flutter/material.dart';
import '../../domain/entities/chat_room.dart';
import '../../domain/entities/message.dart';
import '../../domain/repositories/chat_repository.dart';

class ChatProvider with ChangeNotifier {
  final IChatRepository _repository;

  ChatProvider(this._repository);

  Stream<List<ChatRoomEntity>> getChatRoomsStream(String userId) {
    return _repository.getChatRoomsStream(userId);
  }

  Stream<List<MessageEntity>> getMessagesStream(String chatId) {
    return _repository.getMessagesStream(chatId);
  }

  Future<void> sendMessage(String chatId, String senderId, String text) async {
    await _repository.sendMessage(chatId, senderId, text);
    notifyListeners();
  }

  Future<String> createOrGetChat(String currentUserId, String otherUserId, Map<String, dynamic>? names) async {
    return await _repository.createOrGetChat(currentUserId, otherUserId, names);
  }

  Future<void> markMessagesAsRead(String chatId, String userId) async {
    await _repository.markMessagesAsRead(chatId, userId);
  }
}
