import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

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
      url: 'https://kkyqghphrvnfycukwpyk.supabase.co',
      anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImtreXFnaHBocnZuZnljdWt3cHlrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzg1OTIwMDQsImV4cCI6MjA5NDE2ODAwNH0.0-YLNAcZG1U4ZL6Nrz0EdY4_Dioaq4C7sEy-VhWDtaA',
    );
  }
}