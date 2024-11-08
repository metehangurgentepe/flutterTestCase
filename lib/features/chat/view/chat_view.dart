import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:test_case/features/chat/model/chat_message_model.dart';
import 'package:test_case/features/chat/model/chat_room_model.dart';
import 'package:test_case/features/chat/provider/chat_provider.dart';
import 'package:test_case/features/chat/repository/chat_repository.dart';
import 'package:test_case/features/chat/widgets/chat_header_view.dart';
import 'package:test_case/features/chat/widgets/message_bar.dart';
import 'package:test_case/features/chat/widgets/message_bubble.dart';

class ChatRoomView extends ConsumerStatefulWidget {
  final String roomId;
  final String roomName;

  const ChatRoomView({
    super.key,
    required this.roomId,
    required this.roomName,
  });

  @override
  ConsumerState<ChatRoomView> createState() => _ChatRoomViewState();
}

class _ChatRoomViewState extends ConsumerState<ChatRoomView> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(messagesProvider(widget.roomId).notifier).loadMessages();
    });
  }

  @override
  Widget build(BuildContext context) {
    final roomAsync = ref.watch(roomProvider(widget.roomId));
    ref.watch(messagesProvider(widget.roomId));

    ref.watch(chatProvider);

    ref.listen<AsyncValue>(chatProvider, (_, state) {
      state.whenOrNull(
        error: (error, _) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(error is ChatRoomCreationException
                  ? (error).message
                  : error is MessageSendException
                      ? (error).message
                      : 'An error occurred'),
              backgroundColor: Colors.red,
            ),
          );
        },
      );
    });

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true,
        title: roomAsync.when(
          data: (room) => _buildHeader(room),
          loading: () => const SizedBox.shrink(),
          error: (error, stack) => Text('Error: $error'),
        ),
        titleSpacing: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: _buildMessagesList(),
          ),
          MessageBar(roomId: widget.roomId),
        ],
      ),
    );
  }

  Widget _buildHeader(ChatRoom room) {
    if (room.isGroup) {
      return ChatHeader(
        roomName: room.name ?? 'Unnamed Group',
        isGroup: true,
        avatarUrl: room.imageUrl,
      );
    }

    return Consumer(
      builder: (context, ref, child) {
        final otherUserIdAsync = ref.watch(otherUserIdProvider(widget.roomId));

        return otherUserIdAsync.when(
          data: (otherUserId) {
            if (otherUserId == null || otherUserId.isEmpty) {
              return ChatHeader(
                roomName: room.name ?? 'Unknown User',
                isGroup: false,
                avatarUrl: room.imageUrl,
              );
            }

            final userProfileAsync =
                ref.watch(userProfileProvider(otherUserId));

            return userProfileAsync.when(
              data: (profile) => ChatHeader(
                roomName: room.name ?? profile['displayName'],
                isGroup: false,
                avatarUrl: room.imageUrl ?? profile['avatarUrl'],
                userId: otherUserId,
              ),
              loading: () => const CircularProgressIndicator(),
              error: (error, _) => ChatHeader(
                roomName: room.name ?? 'Unknown User',
                isGroup: false,
                avatarUrl: room.imageUrl,
              ),
            );
          },
          loading: () => const CircularProgressIndicator(),
          error: (error, _) => ChatHeader(
            roomName: room.name ?? 'Error',
            isGroup: false,
            avatarUrl: room.imageUrl,
          ),
        );
      },
    );
  }

  Widget _buildMessagesList() {
    final messagesAsync = ref.watch(messagesProvider(widget.roomId));

    return messagesAsync.when(
      data: (messages) {
        if (messages.isEmpty) {
          return const Center(
            child: Text(
              'No messages yet',
              style: TextStyle(color: Colors.grey),
            ),
          );
        }

        return ListView.builder(
          reverse: true,
          padding: const EdgeInsets.all(8.0),
          itemCount: messages.length,
          itemBuilder: (context, index) {
            final message = messages[index];

            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: MessageBubbleBuilder(message: message),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) {
        return Center(child: Text('Error: $error'));
      },
    );
  }
}

class MessageBubbleBuilder extends ConsumerWidget {
  final ChatMessage message;

  const MessageBubbleBuilder({
    super.key,
    required this.message,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUserId = ref.read(supabaseClientProvider).auth.currentUser?.id;
    final isCurrentUser = message.senderId == currentUserId;

    final userProfileAsync = ref.watch(userProfileProvider(message.senderId));

    return userProfileAsync.when(
      data: (userData) => MessageBubble(
        key: ValueKey(message.id),
        message: message,
        isCurrentUser: isCurrentUser,
        senderName: userData['displayName'] ?? 'Unknown User',
        avatarUrl: userData['avatarUrl'],
      ),
      loading: () => MessageBubble(
        key: ValueKey(message.id),
        message: message,
        isCurrentUser: isCurrentUser,
        senderName: 'Loading...',
      ),
      error: (_, __) => MessageBubble(
        key: ValueKey(message.id),
        message: message,
        isCurrentUser: isCurrentUser,
        senderName: 'Unknown User',
      ),
    );
  }
}
