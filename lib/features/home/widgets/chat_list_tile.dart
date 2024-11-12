import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:test_case/features/auth/providers/providers.dart';
import 'package:test_case/features/home/models/chat_room_model.dart';
import 'package:test_case/core/utils/date_formatter.dart';
import 'package:test_case/features/chat/view/chat_view.dart';
import 'package:test_case/features/home/providers/chat_provider.dart';

class ChatRoomListTile extends ConsumerWidget {
  final ChatRoom room;
  final VoidCallback onTap;

  const ChatRoomListTile({
    super.key,
    required this.room,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(authStateProvider).value;
    
    if (room.isGroup) {
      return _buildGroupTile(context);
    }

    final otherUserId = room.participants
        .firstWhere((id) => id != currentUser?.id, orElse: () => '');
    
    final otherUserAsync = ref.watch(userProfileProvider(otherUserId));

    return otherUserAsync.when(
      data: (otherUser) => ListTile(
        leading: CircleAvatar(
          backgroundImage: otherUser?.avatarUrl != null
              ? NetworkImage(otherUser!.avatarUrl!)
              : null,
          child: otherUser?.avatarUrl == null
              ? Text(otherUser?.username[0].toUpperCase() ?? '?')
              : null,
        ),
        title: Text(otherUser?.username ?? 'Unknown User'),
        subtitle: _buildSubtitle(),
        trailing: _buildTrailing(),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatRoomView(
              roomId: room.id ?? '',
              roomName: otherUser?.username ?? 'Unknown User',
            ),
          ),
        ),
      ),
      loading: () => const ListTile(
        leading: CircleAvatar(child: CircularProgressIndicator()),
        title: Text('Loading...'),
      ),
      error: (_, __) => const ListTile(
        leading: CircleAvatar(child: Icon(Icons.error)),
        title: Text('Error loading user'),
      ),
    );
  }

  Widget _buildGroupTile(BuildContext context) {
    return ListTile(
      leading: const CircleAvatar(child: Icon(Icons.group)),
      title: Text(room.name ?? 'Unnamed Group'),
      subtitle: _buildSubtitle(),
      trailing: _buildTrailing(),
      onTap: onTap,
    );
  }

  Widget? _buildSubtitle() {
    if (room.lastMessage == null) return null;
    
    return Text(
      room.lastMessage!,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget? _buildTrailing() {
    if (room.lastMessageTime == null) return null;
    
    return Text(
      DateFormatter.formatChatDateTime(room.lastMessageTime!),
      style: const TextStyle(
        color: Colors.grey,
        fontSize: 12,
      ),
    );
  }
}
