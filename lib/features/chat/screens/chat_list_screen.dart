import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../presentation/providers/chat_provider.dart';
import '../domain/entities/chat_room.dart';
import 'chat_room_screen.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isSuperAdmin = auth.user?.role == 'superadmin';
    final isHospitalAdmin =
        auth.user?.role == 'admin' && auth.user?.hospitalId != null;
    final participantId = isSuperAdmin
        ? 'superadmin'
        : (isHospitalAdmin ? auth.user!.hospitalId! : auth.user?.uid);
    final chatProvider = context.read<ChatProvider>();

    if (participantId == null) {
      return const Scaffold(
        body: Center(child: Text('Please log in to view chats.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Messages')),
      body: StreamBuilder<List<ChatRoomEntity>>(
        stream: chatProvider.getChatRoomsStream(
          participantId,
        ), //para ma pakita ang tanang nakachat nmo.
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final chatRooms = snapshot.data ?? [];

          if (chatRooms.isEmpty) {
            return const Center(
              child: Text(
                'No active conversations yet.\nStart a chat from a blood bank profile!',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            );
          }

          return ListView.builder(
            itemCount: chatRooms.length,
            itemBuilder: (context, index) {
              final room = chatRooms[index];
              // Find the other participant's ID
              final otherParticipantId = room.participants.firstWhere(
                (id) => id != participantId,
                orElse: () => 'Unknown',
              );

              // Try to get their name from participantNames, fallback to "User"
              final otherParticipantName = room.participantNames != null
                  ? room.participantNames![otherParticipantId] ?? 'User'
                  : 'User';

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Theme.of(context).primaryColor,
                  child: Text(
                    otherParticipantName.isNotEmpty
                        ? otherParticipantName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                title: Text(
                  otherParticipantName,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  room.lastMessage.isEmpty ? 'Say hi!' : room.lastMessage,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: Text(
                  _formatDate(room.lastUpdateTime),
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatRoomScreen(
                        chatRoomId: room.id,
                        otherParticipantName: otherParticipantName,
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    if (difference.inDays == 0) {
      return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
