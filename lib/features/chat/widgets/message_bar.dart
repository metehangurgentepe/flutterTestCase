import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:test_case/features/chat/provider/chat_room_providers.dart';

class MessageBar extends ConsumerStatefulWidget {
  final String roomId;
  final Function(Object error)? onError;

  const MessageBar({
    Key? key,
    required this.roomId,
    this.onError,
  }) : super(key: key);

  @override
  ConsumerState<MessageBar> createState() => _MessageBarState();
}

class _MessageBarState extends ConsumerState<MessageBar> {
  late final TextEditingController _controller;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  Future<void> _sendMessage() async {
    if (!_validateMessage()) return;

    await _performSend();
  }

  bool _validateMessage() {
    final content = _controller.text.trim();
    return content.isNotEmpty && !_isSending;
  }

  Future<void> _performSend() async {
    setState(() => _isSending = true);

    try {
      await ref
          .read(messagesProvider(widget.roomId).notifier)
          .sendMessage(_controller.text.trim());
      _controller.clear();
    } catch (e) {
      if (mounted) widget.onError?.call(e);
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: _MessageInputBar(
        controller: _controller,
        isSending: _isSending,
        onSend: _sendMessage,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class _MessageInputBar extends StatelessWidget {
  final TextEditingController controller;
  final bool isSending;
  final VoidCallback onSend;

  const _MessageInputBar({
    required this.controller,
    required this.isSending,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: 'Type a message',
                border: InputBorder.none,
              ),
              onSubmitted: (_) => onSend(),
              enabled: !isSending,
            ),
          ),
          _SendButton(
            isSending: isSending,
            onPressed: onSend,
          ),
        ],
      ),
    );
  }
}

class _SendButton extends StatelessWidget {
  final bool isSending;
  final VoidCallback onPressed;

  const _SendButton({required this.isSending, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: isSending
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.send),
      onPressed: isSending ? null : onPressed,
    );
  }
}