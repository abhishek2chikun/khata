enum DataMode { api, local, hybrid }

const String configuredDataMode = String.fromEnvironment('DATA_MODE');

DataMode parseDataMode(String rawValue) {
  final normalized = rawValue.trim().toLowerCase();
  if (normalized.isEmpty || normalized == 'hybrid') {
    return DataMode.hybrid;
  }
  if (normalized == 'api') {
    return DataMode.api;
  }
  if (normalized == 'local') {
    return DataMode.local;
  }
  throw ArgumentError.value(rawValue, 'DATA_MODE', 'Expected api, local, or hybrid');
}

DataMode resolveDataMode() {
  if (configuredDataMode.isNotEmpty) {
    return parseDataMode(configuredDataMode);
  }
  return DataMode.hybrid;
}
