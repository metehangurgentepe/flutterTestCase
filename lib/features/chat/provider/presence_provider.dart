import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:test_case/features/chat/provider/chat_provider.dart';

final presenceProvider = StreamProvider.family<bool, String>((ref, userId) {
  final presenceService = ref.watch(presenceServiceProvider);
  return presenceService.getUserPresence(userId).map((presence) {
    return presence['status'] == 'online';
  });
});
