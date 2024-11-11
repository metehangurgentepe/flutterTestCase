import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:test_case/features/chat/provider/chat_room_providers.dart';

class ChatHeader extends StatelessWidget {
  final String roomName;
  final bool isGroup;
  final String? avatarUrl;
  final String? userId;
  final bool isOnline;

  const ChatHeader({
    required this.roomName,
    required this.isGroup,
    this.avatarUrl,
    this.userId,
    this.isOnline = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _buildAvatar(isOnline),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                roomName,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black, 
                ),
                overflow: TextOverflow.ellipsis,
              ),
              if (!isGroup && userId != null)
                Text(
                  isOnline ? 'online' : 'offline',
                  style: TextStyle(
                    fontSize: 12,
                    color: isOnline ? Colors.green : Colors.grey,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAvatar(bool isOnline) {
    return Stack(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.grey[300],
            border: Border.all(
              color: Colors.grey[400]!,
              width: 1,
            ),
          ),
          child: avatarUrl != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.network(
                    avatarUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(Icons.person, size: 24);
                    },
                  ),
                )
              : const Icon(Icons.person, size: 24),
        ),
        if (!isGroup && userId != null)
          Positioned(
            right: 0,
            bottom: 0,
            child: _buildPresenceDot(isOnline),
          ),
      ],
    );
  }

  Widget _buildPresenceDot(bool isOnline) {
    return Consumer(
      builder: (context, ref, child) {
        final presenceAsync = ref.watch(userPresenceProvider(userId!));
        
        return presenceAsync.when(
          data: (presence) {
            return Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isOnline ? Colors.green : Colors.grey[400],
                border: Border.all(
                  color: Colors.white,
                  width: 2,
                ),
              ),
            );
          },
          loading: () => const SizedBox(width: 12, height: 12),
          error: (_, __) => const SizedBox(width: 12, height: 12),
        );
      },
    );
  }
}