
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:test_case/core/utils/helpers/presence_service.dart';

final presenceServiceProvider = Provider<PresenceService>((ref) {
  final supabase = Supabase.instance.client;
  return PresenceService(supabase);
});
