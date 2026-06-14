import '../models/api_error.dart';

const hsnMaxLength = 32;
const maxIntegralQuantity = 99999999999;

String? normalizeHsn(String? value) {
  if (value == null) {
    return null;
  }
  final normalized = value.trim();
  if (normalized.isEmpty) {
    return null;
  }
  if (normalized.length > hsnMaxLength) {
    throw _validationError(
      'hsn_code must be at most $hsnMaxLength characters',
    );
  }
  return normalized;
}

double validateUnitPrice(double value) {
  if (value <= 0) {
    throw _validationError('unit price must be greater than zero');
  }
  if (!value.isFinite) {
    throw _validationError('unit price must be finite');
  }
  if (!_hasAtMostDecimalPlaces(value, 3)) {
    throw _validationError('unit price must have at most three decimal places');
  }
  return roundUnitPrice(value);
}

double validatePositiveIntegralQuantity(double value) {
  if (value <= 0) {
    throw _validationError('quantity must be greater than zero');
  }
  if (!value.isFinite) {
    throw _validationError('quantity must be finite');
  }
  if (value != value.truncateToDouble()) {
    throw _validationError('quantity must be a whole number');
  }
  if (value > maxIntegralQuantity) {
    throw _validationError('quantity exceeds maximum supported value');
  }
  return value;
}

double validateNonNegativeIntegralQuantity(double value) {
  if (value < 0) {
    throw _validationError('quantity must be non-negative');
  }
  if (!value.isFinite) {
    throw _validationError('quantity must be finite');
  }
  if (value != value.truncateToDouble()) {
    throw _validationError('quantity must be a whole number');
  }
  return value;
}

double validateNonZeroIntegralQuantity(double value) {
  if (value == 0) {
    throw _validationError('quantity delta must be non-zero');
  }
  validatePositiveIntegralQuantity(value.abs());
  return value;
}

double validateDiscountDisabled(double value) {
  if (value != 0) {
    throw _validationError('discounts are disabled');
  }
  return value;
}

String canonicalUnitPriceString(double value) {
  return roundUnitPrice(value).toStringAsFixed(3);
}

String canonicalIntegralQuantityString(double value) {
  return validatePositiveIntegralQuantity(value).toInt().toString();
}

double roundUnitPrice(double value) => _roundHalfUp(value, 3);

bool _hasAtMostDecimalPlaces(double value, int places) {
  final text = value.toString();
  final exponentParts = text.toLowerCase().split('e');
  final decimalPart = exponentParts.first.split('.');
  final decimals = decimalPart.length == 1 ? 0 : decimalPart.last.length;
  final exponent =
      exponentParts.length == 1 ? 0 : int.tryParse(exponentParts.last) ?? 0;
  return decimals - exponent <= places;
}

double _roundHalfUp(double value, int places) {
  if (!value.isFinite) {
    throw ArgumentError.value(value, 'value', 'Decimal value must be finite');
  }
  final negative = value < 0;
  final text = value.abs().toStringAsFixed(places + 6);
  final parts = text.split('.');
  final whole = int.parse(parts.first);
  final fraction = parts.length == 1 ? '' : parts.last;
  final kept = fraction.padRight(places, '0').substring(0, places);
  final nextDigit =
      fraction.length > places ? int.parse(fraction[places]) : 0;
  var scaled = whole * _pow10(places) + int.parse(kept.isEmpty ? '0' : kept);
  if (nextDigit >= 5) {
    scaled += 1;
  }
  final rounded = scaled / _pow10(places);
  return negative ? -rounded : rounded;
}

int _pow10(int exponent) {
  var result = 1;
  for (var index = 0; index < exponent; index += 1) {
    result *= 10;
  }
  return result;
}

ApiError _validationError(String message) {
  return ApiError(
    code: 'VALIDATION_ERROR',
    message: message,
    statusCode: 400,
  );
}
