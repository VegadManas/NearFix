import 'package:supabase_flutter/supabase_flutter.dart';

/// Fill these in from Supabase Dashboard -> Project Settings -> API.
/// SUPABASE_URL looks like: https://xxxxxxxxxxxx.supabase.co
/// SUPABASE_ANON_KEY is the long "anon / public" key (safe to ship in the app).
class SupabaseConfig {
  static const String url = "https://mznrchdilgkyiezyanoc.supabase.co";
  static const String anonKey =
      "sb_publishable_DMG2Yvl3L7-NsjwvM4daVQ_ABbEl8RD";
}

/// Call this once in main() before runApp().
Future<void> initSupabase() async {
  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );
}

/// Shortcut used everywhere instead of importing Supabase.instance.client
/// in every file.
final supabase = Supabase.instance.client;
