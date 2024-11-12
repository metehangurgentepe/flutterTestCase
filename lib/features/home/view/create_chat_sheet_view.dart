import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:test_case/features/auth/model/user_model.dart';
import 'package:test_case/features/auth/providers/providers.dart';
import 'package:test_case/features/home/models/chat_room_model.dart';
import 'package:test_case/features/chat/view/chat_view.dart';
import 'package:test_case/features/home/providers/chat_provider.dart';
import 'package:test_case/core/widgets/error_view.dart';
import 'package:test_case/core/widgets/loading_view.dart';

class CreateChatSheet extends ConsumerStatefulWidget {
  const CreateChatSheet({super.key});

  @override
  ConsumerState<CreateChatSheet> createState() => _CreateChatSheetState();
}

class _CreateChatSheetState extends ConsumerState<CreateChatSheet> {
  final _searchController = TextEditingController();
  Timer? _debounce;
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      setState(() {
        _searchQuery = query;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(usersProvider(_searchQuery));
    final currentUser = ref.watch(authStateProvider).value;

    if (currentUser == null) {
      return const ErrorView(message: 'User not authenticated');
    }

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) => Container(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Text(
              'Start a Chat',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search users...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                fillColor: Colors.grey[100],
                filled: true,
              ),
              onChanged: _onSearchChanged,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: usersAsync.when(
                data: (users) => _UsersList(
                  users: users,
                  currentUserId: currentUser.id,
                  onUserSelected: (selectedUser) => _createChatRoom(
                    context, 
                    selectedUser, 
                    currentUser,
                  ),
                ),
                loading: () => const LoadingView(),
                error: (error, _) => ErrorView(
                  message: 'Failed to load users: $error',
                  onRetry: () => ref.refresh(usersProvider(_searchQuery)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createChatRoom(
    BuildContext context,
    UserModel selectedUser,
    UserModel currentUser,
  ) async {
    try {
      final room = ChatRoom(
        name: selectedUser.username,
        isGroup: false,
        id: null,
        participants: [currentUser.id, selectedUser.id],
      );

      final createdRoom = await ref
          .read(chatListProvider.notifier)
          .createChatRoom(room);

      if (context.mounted) {
        Navigator.pop(context);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatRoomView(
              roomId: createdRoom.id ?? '',
              roomName: createdRoom.name ?? selectedUser.username,
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create chat room: $e')),
        );
      }
    }
  }
}

// Add this class at the end of the file
class _UsersList extends StatelessWidget {
  final List<UserModel> users;
  final String currentUserId;
  final void Function(UserModel) onUserSelected;

  const _UsersList({
    required this.users,
    required this.currentUserId,
    required this.onUserSelected,
  });

  @override
  Widget build(BuildContext context) {
    final filteredUsers = users.where((user) => user.id != currentUserId).toList();

    if (filteredUsers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_search, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No users found',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: filteredUsers.length,
      itemBuilder: (context, index) {
        final user = filteredUsers[index];
        return ListTile(
          title: Text(user.username),
          onTap: () => onUserSelected(user),
        );
      },
    );
  }
}
