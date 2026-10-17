import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  // Yahan apna Project URL aur Legacy Anon Key daalein
  static const String supabaseUrl = 'https://bpycutoucttomyjpeioa.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJweWN1dG91Y3R0b215anBlaW9hIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTE4NjUyMTQsImV4cCI6MjEwNzQ0MTIxNH0.zG28Pe4vsY7pmjj9GK8MvyRnris3FHioROlOalgZXnQ';

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
  }

  static SupabaseClient get client => Supabase.instance.client;
}