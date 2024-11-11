import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:test_case/features/auth/providers/providers.dart';
import 'package:test_case/features/auth/view/auth_wrapper.dart';
import 'package:test_case/features/chat/view/chat_view.dart';
import 'package:test_case/features/home/providers/chat_provider.dart';
import 'package:test_case/features/home/view/create_chat_sheet_view.dart';
import 'package:test_case/features/home/view/create_group_sheet_view.dart';
import 'package:test_case/features/home/widgets/chat_list_tile.dart';

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
      appBar: AppBar(
        title: const Text('Messages'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _showLogoutDialog(context),
          ),
          IconButton(
            icon: const Icon(Icons.group_add),
            onPressed: () => _showCreateGroupSheet(context),
          ),
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: () => _showCreateChatSheet(context),
          ),
        ],
      ),
      body: Column(
        children: [
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Chats'),
              Tab(text: 'Groups'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _KeepAliveChatList(
                  child: _PersonalChatsList(userId: userId),
                ),
                _KeepAliveChatList(
                  child: _GroupChatsList(userId: userId),
                ),
              ],
            ),
          ),
        ],
      ),
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
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.chat_bubble_outline, size: 48, color: Colors.grey),
                SizedBox(height: 16),
                Text('No chats yet', style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: personalChats.length,
          itemBuilder: (context, index) {
            final room = personalChats[index];
            return ChatRoomListTile(
              room: room,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatRoomView(
                    roomId: room.id ?? '',
                    roomName: room.name ?? 'Chat',
                  ),
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error: $error')),
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
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.group_outlined, size: 48, color: Colors.grey),
                SizedBox(height: 16),
                Text('No group chats yet',
                    style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: rooms.length,
          itemBuilder: (context, index) {
            final room = rooms[index];
            return ChatRoomListTile(
              room: room,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatRoomView(
                    roomId: room.id ?? '',
                    roomName: room.name ?? 'Group Chat',
                  ),
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error: $error')),
    );
  }
}
