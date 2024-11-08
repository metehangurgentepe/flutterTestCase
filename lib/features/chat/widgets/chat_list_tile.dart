import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:test_case/features/auth/model/user_model.dart';
import 'package:test_case/features/auth/providers/auth_providers.dart';
import 'package:test_case/features/chat/model/chat_room_model.dart';
import 'package:test_case/core/utils/date_formatter.dart';
import 'package:test_case/features/chat/view/chat_view.dart';


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
    final supabase = Supabase.instance.client;

    return FutureBuilder<UserModel?>(
      future: _getOtherUser(currentUser?.id ?? '', supabase),
      builder: (context, snapshot) {
        final otherUser = snapshot.data;

        return ListTile(
          leading: CircleAvatar(
            backgroundImage: otherUser?.avatarUrl != null
                ? NetworkImage(otherUser!.avatarUrl!)
                : null,
            child: otherUser?.avatarUrl == null
                ? Text(otherUser?.username[0].toUpperCase() ?? '?')
                : null,
          ),
          title: Text(
            room.isGroup
                ? room.name ?? 'Unnamed Group'
                : otherUser?.username ?? 'Unknown User',
          ),
          subtitle: room.lastMessage != null
              ? Text(
                  room.lastMessage!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                )
              : null,
          trailing: room.lastMessageTime != null
              ? Text(
                  DateFormatter.formatChatDateTime(room.lastMessageTime!),
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                )
              : null,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChatRoomView(
                  roomId: room.id ?? '',
                  roomName: room.isGroup
                      ? room.name ?? 'Unnamed Group'
                      : otherUser?.username ?? 'Unknown User',
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<UserModel?> _getOtherUser(String currentUserId, SupabaseClient supabase) async {
    if (room.isGroup) return null;
    
    final otherUserId = room.participants.firstWhere(
      (id) => id != currentUserId,
      orElse: () => '',
    );
    
    if (otherUserId.isEmpty) return null;

    final response = await supabase
        .from('profiles')
        .select()
        .eq('id', otherUserId)
        .single();
        
    return UserModel.fromJson(response);
  }
}