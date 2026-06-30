import 'package:intl/intl.dart';
import 'package:medicore/utils/currency.dart';

class Formatters {
  static String formatDate(DateTime date) {
    // Example: Oct 27, 2025
    return DateFormat.yMMMd().format(date);
  }

  static String formatTime(DateTime time) {
    // Example: 09:30 AM
    return DateFormat.jm().format(time);
  }

  static String formatCurrency(double amount) {
    // Use unified Taka currency formatting
    return CurrencyFormatter.taka(amount);
  }
}
