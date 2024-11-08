
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UserProfileNotifier extends StateNotifier<AsyncValue<Map<String, dynamic>>> {
  final SupabaseClient _supabase;
  final String userId;

  UserProfileNotifier(this._supabase, this.userId) : super(const AsyncValue.loading()) {
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final data = await _supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();
      
      if (!mounted) return;
      state = AsyncValue.data(data);
    } catch (e, stack) {
      if (!mounted) return;
      state = AsyncValue.error(e, stack);
    }
  }
}