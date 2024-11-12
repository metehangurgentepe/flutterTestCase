import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:test_case/features/auth/providers/providers.dart';
import 'package:test_case/features/auth/view/auth_wrapper.dart';
import 'package:test_case/features/chat/view/chat_view.dart';
import 'package:test_case/features/home/models/chat_room_model.dart';
import 'package:test_case/features/home/providers/chat_provider.dart';
import 'package:test_case/features/home/view/create_chat_sheet_view.dart';
import 'package:test_case/features/home/view/create_group_sheet_view.dart';
import 'package:test_case/features/home/widgets/chat_list_tile.dart';
import 'package:test_case/core/widgets/error_view.dart';
import 'package:test_case/core/widgets/loading_view.dart';

class HomeView extends ConsumerStatefulWidget {
  const HomeView({super.key});

  @override
  ConsumerState<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends ConsumerState<HomeView>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(authStateProvider).value;
    final userId = currentUser?.id ?? '';

    return Scaffold(
      appBar: _buildAppBar(context),
      body: _buildBody(userId),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      title: const Text('Messages'),
      automaticallyImplyLeading: false,
      actions: [
        _LogoutButton(onPressed: () => _showLogoutDialog(context)),
        _CreateGroupButton(onPressed: () => _showCreateGroupSheet(context)),
        _CreateChatButton(onPressed: () => _showCreateChatSheet(context)),
      ],
    );
  }

  Widget _buildBody(String userId) {
    return Column(
      children: [
        TabBar(
          controller: _tabController,
          tabs: const [Tab(text: 'Chats'), Tab(text: 'Groups')],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _KeepAliveChatList(child: _PersonalChatsList(userId: userId)),
              _KeepAliveChatList(child: _GroupChatsList(userId: userId)),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _showLogoutDialog(BuildContext context) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (shouldLogout == true && mounted) {
      await ref.read(authStateProvider.notifier).signOut();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const AuthWrapper()),
          (route) => false,
        );
      }
    }
  }

  void _showCreateGroupSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => const CreateGroupSheet(),
    );
  }

  void _showCreateChatSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => const CreateChatSheet(),
    );
  }
}

class _LogoutButton extends StatelessWidget {
  final VoidCallback onPressed;
  
  const _LogoutButton({required this.onPressed});
  
  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.logout),
      onPressed: onPressed,
    );
  }
}

class _CreateGroupButton extends StatelessWidget {
  final VoidCallback onPressed;
  
  const _CreateGroupButton({required this.onPressed});
  
  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.group_add),
      onPressed: onPressed,
    );
  }
}

class _CreateChatButton extends StatelessWidget {
  final VoidCallback onPressed;
  
  const _CreateChatButton({required this.onPressed});
  
  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.person_add),
      onPressed: onPressed,
    );
  }
}

class _KeepAliveChatList extends StatefulWidget {
  final Widget child;

  const _KeepAliveChatList({required this.child});

  @override
  State<_KeepAliveChatList> createState() => _KeepAliveChatListState();
}

class _KeepAliveChatListState extends State<_KeepAliveChatList>
    with AutomaticKeepAliveClientMixin {
  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }

  @override
  bool get wantKeepAlive => true;
}

class _PersonalChatsList extends ConsumerWidget {
  final String userId;

  const _PersonalChatsList({required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatRoomsAsync = ref.watch(chatRoomsProvider(userId));

    return chatRoomsAsync.when(
      data: (rooms) {
        final personalChats = rooms.where((room) => !room.isGroup).toList();

        if (personalChats.isEmpty) {
          return const _EmptyView(
            icon: Icons.chat_bubble_outline,
            message: 'No chats yet',
          );
        }

        return _ChatRoomListView(rooms: personalChats);
      },
      loading: () => const LoadingView(),
      error: (error, stack) => ErrorView(
        message: 'Failed to load chats: $error',
        onRetry: () => ref.refresh(chatRoomsProvider(userId)),
      ),
    );
  }
}

class _GroupChatsList extends ConsumerWidget {
  final String userId;

  const _GroupChatsList({required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupRoomsAsync = ref.watch(groupRoomsProvider(userId));

    return groupRoomsAsync.when(
      data: (rooms) {
        if (rooms.isEmpty) {
          return const _EmptyView(
            icon: Icons.group_outlined,
            message: 'No group chats yet',
          );
        }

        return _ChatRoomListView(rooms: rooms);
      },
      loading: () => const LoadingView(),
      error: (error, stack) => ErrorView(
        message: 'Failed to load group chats: $error',
        onRetry: () => ref.refresh(groupRoomsProvider(userId)),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  final IconData icon;
  final String message;

  const _EmptyView({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 48, color: Colors.grey),
          const SizedBox(height: 16),
          Text(message, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}

class _ChatRoomListView extends StatelessWidget {
  final List<ChatRoom> rooms;

  const _ChatRoomListView({required this.rooms});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: rooms.length,
      itemBuilder: (context, index) {
        final room = rooms[index];
        return ChatRoomListTile(
          room: room,
          onTap: () => _navigateToChatRoom(context, room),
        );
      },
    );
  }

  void _navigateToChatRoom(BuildContext context, ChatRoom room) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatRoomView(
          roomId: room.id ?? '',
          roomName: room.name ?? 'Chat',
        ),
      ),
    );
  }
}
