
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:test_case/core/utils/helpers/life_cycle_handler.dart';

final lifecycleHandlerProvider = Provider<LifecycleHandler>((ref) {
  final handler = LifecycleHandler(ref);
  ref.onDispose(() => handler.dispose());
  return handler;
});