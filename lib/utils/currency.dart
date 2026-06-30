import 'package:intl/intl.dart';

class CurrencyFormatter {
  CurrencyFormatter._();

  static String taka(num amount, {bool compact = false}) {
    if (compact) {
      if (amount >= 1000000) {
        return '৳${(amount / 1000000).toStringAsFixed(1)}M';
      }
      if (amount >= 1000) {
        return '৳${(amount / 1000).toStringAsFixed(1)}K';
      }
      return '৳${amount.toStringAsFixed(0)}';
    }
    final formatter = NumberFormat.currency(
        symbol: '৳', decimalDigits: amount >= 1000 ? 0 : 2);
    return formatter.format(amount);
  }
}
