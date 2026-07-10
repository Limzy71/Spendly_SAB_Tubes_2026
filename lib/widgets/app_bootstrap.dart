import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

class AppBootstrap {
  static Completer<void>? _supabaseInitCompleter;

  static void start() {
    _supabaseInitCompleter ??= Completer<void>()..complete(_initializeSupabase());
  }

  static Future<void> ensureInitialized() async {
    start();
    await _supabaseInitCompleter!.future;
  }

  static Future<void> _initializeSupabase() async {
    await Supabase.initialize(
      url: SupabaseConfig.url,
      anonKey: SupabaseConfig.anonKey,
    );
  }
}