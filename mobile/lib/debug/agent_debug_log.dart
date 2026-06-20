import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

/// Session debug logger for agent investigations (cc4117).
///
/// This instrumentation was used to diagnose a specific auth/sync issue. In
/// release/profile builds it is a no-op so that no debug telemetry, host
/// filesystem paths, or extra logging ship to production devices. The debug
/// build behaviour is preserved for ongoing investigations on the simulator.
class AgentDebugLog {
  AgentDebugLog._();

  static void write({
    required String location,
    required String message,
    required String hypothesisId,
    Map<String, Object?> data = const {},
    String runId = 'pre-fix',
  }) {
    if (kReleaseMode) {
      return;
    }

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

const _sessionId = 'cc4117';
const _logPath = '/Users/abhishek/python_venv/khata_app/.cursor/debug-cc4117.log';
