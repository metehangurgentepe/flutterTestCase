import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:test_case/core/errors/chat_exceptions.dart';
import 'package:test_case/features/chat/model/chat_message_model.dart';
import 'package:test_case/features/chat/provider/chat_room_providers.dart';
import 'package:test_case/features/home/models/chat_room_model.dart';
// import 'package:test_case/features/home/providers/chat_provider.dart';
import 'package:test_case/features/chat/provider/presence_provider.dart';
import 'package:test_case/features/chat/widgets/chat_header_view.dart';
import 'package:test_case/features/chat/widgets/message_bar.dart';
import 'package:test_case/features/chat/widgets/message_bubble.dart';
import 'package:test_case/core/widgets/error_view.dart';
import 'package:test_case/features/home/providers/chat_provider.dart'; // Add this import

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

  void _handleError(Object error) {
    String errorMessage = 'An unexpected error occurred';
    
    if (error is ChatRoomCreationException) {
      errorMessage = error.message;
    } else if (error is MessageSendException) {
      errorMessage = error.message;
    } else if (error is ProfileFetchException) {
      errorMessage = 'Could not load user profile';
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(errorMessage),
        backgroundColor: Colors.red,
        action: SnackBarAction(
          label: 'Retry',
          textColor: Colors.white,
          onPressed: () => ref.read(messagesProvider(widget.roomId).notifier).loadMessages(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final roomAsync = ref.watch(roomProvider(widget.roomId));
    ref.watch(messagesProvider(widget.roomId));

    ref.watch(chatProvider);

    ref.listen<AsyncValue>(chatProvider, (_, state) {
      state.whenOrNull(error: (error, _) => _handleError(error));
    });

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true,
        title: roomAsync.when(
          data: (room) => _buildHeader(room),
          loading: () => const CircularProgressIndicator(),
          error: (error, _) => ErrorView(
            message: 'Could not load chat room',
            onRetry: () => ref.refresh(roomProvider(widget.roomId)),
          ),
        ),
        titleSpacing: 0,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    return Column(
      children: [
        Expanded(
          child: _buildMessagesList(),
        ),
        MessageBar(
          roomId: widget.roomId,
          onError: _handleError,
        ),
      ],
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

            final userProfileAsync = ref.watch(userProfileProvider(otherUserId));
            final presenceAsync = ref.watch(presenceProvider(otherUserId));

            return userProfileAsync.when(
              data: (user) => ChatHeader(
                roomName: room.name ?? user?.username ?? 'Unknown User',
                isGroup: false,
                avatarUrl: room.imageUrl ?? user?.avatarUrl,
                userId: otherUserId,
                isOnline: presenceAsync.value ?? false,
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

        return RefreshIndicator(
          onRefresh: () => ref.read(messagesProvider(widget.roomId).notifier).loadMessages(),
          child: ListView.builder(
            reverse: true,
            padding: const EdgeInsets.all(8.0),
            itemCount: messages.length,
            itemBuilder: (context, index) {
              final message = messages[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: MessageBubbleBuilder(
                  message: message,
                  onError: _handleError,
                ),
              );
            },
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => ErrorView(
        message: 'Could not load messages',
        error: error,
        onRetry: () => ref.read(messagesProvider(widget.roomId).notifier).loadMessages(),
      ),
    );
  }
}

class MessageBubbleBuilder extends ConsumerWidget {
  final ChatMessage message;
  final Function(Object error)? onError;

  const MessageBubbleBuilder({
    super.key,
    required this.message,
    this.onError,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUserId = ref.read(supabaseClientProvider).auth.currentUser?.id;
    final isCurrentUser = message.senderId == currentUserId;
    
    // Düzeltilmiş provider çağrısı
    final userData = ref.watch(userProfileProvider(message.senderId));

    return userData.when(
      data: (user) => MessageBubble(
        key: ValueKey(message.id),
        message: message,
        isCurrentUser: isCurrentUser,
        senderName: user?.username ?? 'Unknown User',
        avatarUrl: user?.avatarUrl,
      ),
      loading: () => const MessageBubbleShimmer(),
      error: (error, _) {
        onError?.call(error);
        return MessageBubble(
          key: ValueKey(message.id),
          message: message,
          isCurrentUser: isCurrentUser,
          senderName: 'Unknown User',
        );
      },
    );
  }
}

// Add this new widget
class MessageBubbleShimmer extends StatelessWidget {
  const MessageBubbleShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      // Add shimmer effect implementation
      // ...
    );
  }
}
