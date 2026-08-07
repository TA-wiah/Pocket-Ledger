import 'package:intl/intl.dart';

class CurrencyFormatter {
  CurrencyFormatter._();

  static String format(double amount, {String symbol = '\$'}) {
    final formatter = NumberFormat.currency(symbol: symbol, decimalDigits: 2);
    return formatter.format(amount);
  }

  static String formatCompact(double amount, {String symbol = '\$'}) {
    if (amount.abs() >= 1000000) {
      return '$symbol${(amount / 1000000).toStringAsFixed(1)}M';
    }
    if (amount.abs() >= 1000) {
      return '$symbol${(amount / 1000).toStringAsFixed(1)}K';
    }
    return format(amount, symbol: symbol);
  }
}

const Map<String, String> supportedCurrencies = {
  'USD': '\$',
  'EUR': '€',
  'GBP': '£',
  'GHS': 'GH₵',
  'NGN': '₦',
  'KES': 'KSh',
  'ZAR': 'R',
  'INR': '₹',
  'JPY': '¥',
  'CAD': 'CA\$',
};
