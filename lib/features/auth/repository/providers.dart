import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:test_case/core/providers/notification_provider.dart';
import 'auth_repository.dart';


final authRepositoryProvider = riverpod.Provider<IAuthRepository>((ref) {
  return AuthRepository(Supabase.instance.client, ref.watch(notificationServiceProvider));
});
