import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:test_case/features/auth/providers/providers.dart';
import 'package:test_case/features/chat/provider/chat_room_providers.dart';
import 'package:test_case/features/home/providers/chat_provider.dart';
import 'package:flutter/material.dart';


class LifecycleHandler extends WidgetsBindingObserver {
  final Ref _ref;
  AppLifecycleState? _previousState;

  LifecycleHandler(this._ref) {
    WidgetsBinding.instance.addObserver(this);
    _updatePresence(AppLifecycleState.resumed);
  }

  Future<void> _updatePresence(AppLifecycleState state) async {
    if (state == _previousState) return;
    _previousState = state;

    final presenceService = _ref.read(presenceServiceProvider);
    final auth = _ref.read(authStateProvider);
    
    if (auth.value != null) {
      try {
        switch (state) {
          case AppLifecycleState.paused:
          case AppLifecycleState.inactive:
          case AppLifecycleState.detached:
            await presenceService.updateStatus('offline');
            break;
            
          case AppLifecycleState.resumed:
            await presenceService.updateStatus('online');
            break;
          case AppLifecycleState.hidden:
            break;
        }
      } catch (e) {
        print('Error updating presence in lifecycle: $e');
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    await _updatePresence(state);
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
  }
}