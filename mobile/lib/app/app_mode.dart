enum DataMode { api, local }

const String configuredDataMode = String.fromEnvironment('DATA_MODE');

DataMode parseDataMode(String rawValue) {
  final normalized = rawValue.trim().toLowerCase();
  if (normalized.isEmpty || normalized == 'api') {
    return DataMode.api;
  }
  if (normalized == 'local') {
    return DataMode.local;
  }
  throw ArgumentError.value(rawValue, 'DATA_MODE', 'Expected api or local');
}

DataMode resolveDataMode() => parseDataMode(configuredDataMode);
