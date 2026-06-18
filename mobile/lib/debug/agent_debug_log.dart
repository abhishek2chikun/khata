import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

/// Session debug logger for agent investigations (cc4117).
class AgentDebugLog {
  AgentDebugLog._();

  static const _logPath =
      '/Users/abhishek/python_venv/khata_app/.cursor/debug-cc4117.log';
  static const _sessionId = 'cc4117';

  static void write({
    required String location,
    required String message,
    required String hypothesisId,
    Map<String, Object?> data = const {},
    String runId = 'pre-fix',
  }) {
    final payload = <String, Object?>{
      'sessionId': _sessionId,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'location': location,
      'message': message,
      'hypothesisId': hypothesisId,
      'data': data,
      'runId': runId,
    };
    // #region agent log
    debugPrint('[DBG-cc4117] $message ${jsonEncode(data)}');
    try {
      File(_logPath).writeAsStringSync(
        '${jsonEncode(payload)}\n',
        mode: FileMode.append,
        flush: true,
      );
    } on Object {
      // Device builds cannot write to host log path; debugPrint remains.
    }
    // #endregion
  }
}
