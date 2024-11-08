import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:test_case/features/chat/provider/chat_provider.dart';

class ChatHeader extends StatelessWidget {
  final String roomName;
  final String? avatarUrl;
  final bool isGroup;
  final String? userId;

  const ChatHeader({
    Key? key,
    required this.roomName,
    this.avatarUrl,
    required this.isGroup,
    this.userId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _buildAvatar(),
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
                _buildPresenceStatus(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAvatar() {
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
            child: _buildPresenceDot(),
          ),
      ],
    );
  }

  Widget _buildPresenceDot() {
    return Consumer(
      builder: (context, ref, child) {
        final presenceAsync = ref.watch(userPresenceProvider(userId!));
        
        return presenceAsync.when(
          data: (presence) {
            final isOnline = presence.status == 'online';
            return Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isOnline ? Colors.green : Colors.grey,
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

  Widget _buildPresenceStatus() {
    return Consumer(
      builder: (context, ref, child) {
        final presenceAsync = ref.watch(userPresenceProvider(userId!));
        
        return presenceAsync.when(
          data: (presence) {
            if (presence.status == 'online') {
              return const Text(
                'Online',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.green,
                ),
              );
            } else if (presence.lastSeen != null) {
              final difference = DateTime.now().difference(presence.lastSeen!);
              String lastSeenText;
              
              if (difference.inMinutes < 1) {
                lastSeenText = 'Just now';
              } else if (difference.inHours < 1) {
                lastSeenText = '${difference.inMinutes}m ago';
              } else if (difference.inDays < 1) {
                lastSeenText = '${difference.inHours}h ago';
              } else {
                lastSeenText = '${difference.inDays}d ago';
              }
              
              return Text(
                'Last seen $lastSeenText',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              );
            }
            return const SizedBox();
          },
          loading: () => const SizedBox(),
          error: (_, __) => const SizedBox(),
        );
      },
    );
  }
}