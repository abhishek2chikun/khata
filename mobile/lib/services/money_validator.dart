import '../models/api_error.dart';

const moneyValidationMessage =
    'Amount must be greater than zero with at most 2 decimals';

String validateMoneyAmount(String value) {
  final normalized = value.trim();
  final match = RegExp(r'^(\d+)(?:\.(\d{1,2}))?$').firstMatch(normalized);
  if (match == null) {
    throw _moneyValidationError();
  }
  final whole = match.group(1)!;
  final fractional = match.group(2);
  if (whole.length > 12) {
    throw _moneyValidationError();
  }
  if (RegExp(r'^0+$').hasMatch(whole) &&
      (fractional == null || RegExp(r'^0+$').hasMatch(fractional))) {
    throw _moneyValidationError();
  }
  return normalized;
}

ApiError _moneyValidationError() {
  return const ApiError(
    code: 'VALIDATION_ERROR',
    message: moneyValidationMessage,
    statusCode: 422,
  );
}
