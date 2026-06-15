class GoogleAuthConfiguration {
  const GoogleAuthConfiguration({required this.serverClientId});

  factory GoogleAuthConfiguration.fromEnvironment() {
    return const GoogleAuthConfiguration(
      serverClientId: String.fromEnvironment(
        'GOOGLE_DRIVE_SERVER_CLIENT_ID',
      ),
    );
  }

  final String serverClientId;

  String? get serverClientIdOrNull {
    final value = serverClientId.trim();
    return value.isEmpty ? null : value;
  }
}
