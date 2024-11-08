import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:test_case/features/chat/provider/chat_provider.dart';
import 'package:test_case/features/auth/providers/auth_providers.dart';

class CreateGroupSheet extends ConsumerStatefulWidget {
  const CreateGroupSheet({super.key});

  @override
  ConsumerState<CreateGroupSheet> createState() => _CreateGroupSheetState();
}

class _CreateGroupSheetState extends ConsumerState<CreateGroupSheet> {
  final _groupNameController = TextEditingController();
  final List<String> _selectedUsers = [];

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(usersProvider(''));
    final currentUser = ref.watch(authStateProvider).value;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _groupNameController,
            decoration: const InputDecoration(
              labelText: 'Group Name',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Select Members:'),
          SizedBox(
            height: 200,
            child: usersAsync.when(
              data: (users) {
                final filteredUsers = users.where((user) => user.id != currentUser?.id).toList();
                return ListView.builder(
                  itemCount: filteredUsers.length,
                  itemBuilder: (context, index) {
                    final user = filteredUsers[index];
                    return CheckboxListTile(
                      title: Text(user.username),
                      value: _selectedUsers.contains(user.id),
                      onChanged: (selected) {
                        setState(() {
                          if (selected == true) {
                            _selectedUsers.add(user.id);
                          } else {
                            _selectedUsers.remove(user.id);
                          }
                        });
                      },
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(child: Text('Error: $error')),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_groupNameController.text.isNotEmpty && _selectedUsers.isNotEmpty) {
                final allParticipants = [..._selectedUsers];
                if (currentUser?.id != null) {
                  allParticipants.add(currentUser!.id);
                }

                await ref.read(chatProvider.notifier).createGroupRoom(
                      _groupNameController.text,
                      allParticipants,
                    );
                if (context.mounted) Navigator.pop(context);
              }
            },
            child: const Text('Create Group'),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _groupNameController.dispose();
    super.dispose();
  }
} 