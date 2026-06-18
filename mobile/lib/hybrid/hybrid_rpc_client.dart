import 'package:supabase_flutter/supabase_flutter.dart';

import 'hybrid_auth_service.dart';

class HybridRpcClient {
  HybridRpcClient({
    required SupabaseClient client,
    HybridConnectivityGate? connectivityGate,
  })  : _client = client,
        _connectivityGate = connectivityGate ?? HybridConnectivityGate(client);

  final SupabaseClient _client;
  final HybridConnectivityGate _connectivityGate;

  Future<Map<String, dynamic>> invokeWrite(
    String functionName,
    Map<String, dynamic> params,
  ) async {
    _connectivityGate.requireOnlineSession();
    try {
      final result = await _client.rpc(functionName, params: params);
      if (result is Map<String, dynamic>) {
        return result;
      }
      if (result is Map) {
        return Map<String, dynamic>.from(result);
      }
      throw HybridRpcException('Unexpected RPC response from $functionName');
    } on PostgrestException catch (error) {
      if (error.code == '23505' || error.message.contains('IDEMPOTENCY_CONFLICT')) {
        throw HybridIdempotencyConflictException(error.message);
      }
      throw HybridRpcException(error.message, code: error.code);
    } on HybridOfflineException {
      rethrow;
    }
  }
}

class HybridRpcException implements Exception {
  HybridRpcException(this.message, {this.code});

  final String message;
  final String? code;

  @override
  String toString() => message;
}

class HybridIdempotencyConflictException extends HybridRpcException {
  HybridIdempotencyConflictException(super.message) : super(code: 'IDEMPOTENCY_CONFLICT');
}
