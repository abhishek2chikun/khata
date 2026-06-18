enum DataMode { api, local, hybrid }

const String configuredDataMode = String.fromEnvironment('DATA_MODE');

DataMode parseDataMode(String rawValue) {
  final normalized = rawValue.trim().toLowerCase();
  if (normalized.isEmpty || normalized == 'hybrid') {
    return DataMode.hybrid;
  }
  throw ArgumentError.value(
    rawValue,
    'DATA_MODE',
    'Hybrid-only runtime accepts only empty or hybrid',
  );
}

DataMode resolveDataMode() {
  if (configuredDataMode.isNotEmpty) {
    return parseDataMode(configuredDataMode);
  }
  return DataMode.hybrid;
}
