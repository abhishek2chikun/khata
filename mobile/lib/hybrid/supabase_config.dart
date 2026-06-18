class SupabaseConfig {
  const SupabaseConfig({
    required this.url,
    required this.anonKey,
  });

  final String url;
  final String anonKey;

  static const urlDefine = String.fromEnvironment('SUPABASE_URL');
  static const anonKeyDefine = String.fromEnvironment('SUPABASE_ANON_KEY');

  static SupabaseConfig? fromEnvironment() {
    if (urlDefine.isEmpty || anonKeyDefine.isEmpty) {
      return null;
    }
    return SupabaseConfig(url: urlDefine, anonKey: anonKeyDefine);
  }

  bool get isConfigured => url.isNotEmpty && anonKey.isNotEmpty;
}
