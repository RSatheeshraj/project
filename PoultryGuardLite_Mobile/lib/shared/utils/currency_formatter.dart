import 'package:intl/intl.dart';

abstract final class CurrencyFormatter {
  /// Formats a value using the Indian Rupee symbol.
  /// Example: format(50000) -> "₹50,000"
  static String format(double value) {
    final format = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 0,
    );
    return format.format(value);
  }

  /// Formats a value using the Indian Rupee symbol with exact decimals.
  /// Example: formatExact(50000.5) -> "₹50,000.50"
  static String formatExact(double value) {
    final format = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 2,
    );
    return format.format(value);
  }
}
