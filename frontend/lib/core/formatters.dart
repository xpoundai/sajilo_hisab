import 'package:intl/intl.dart';

class CurrencyFormatter {
  static final _formatter = NumberFormat.currency(
    locale: 'en_IN',
    symbol: 'NPR ',
    decimalDigits: 0,
  );

  static final _formatterWithDecimals = NumberFormat.currency(
    locale: 'en_IN',
    symbol: 'NPR ',
    decimalDigits: 2,
  );

  static String format(dynamic amount) {
    if (amount == null) return 'NPR 0';
    final val = amount is String ? double.tryParse(amount) ?? 0 : amount.toDouble();
    return _formatter.format(val);
  }

  static String formatWithDecimals(dynamic amount) {
    if (amount == null) return 'NPR 0.00';
    final val = amount is String ? double.tryParse(amount) ?? 0 : amount.toDouble();
    return _formatterWithDecimals.format(val);
  }

  static String compact(dynamic amount) {
    if (amount == null) return '0';
    final val = amount is String ? double.tryParse(amount) ?? 0 : amount.toDouble();
    if (val >= 100000) {
      return '${(val / 100000).toStringAsFixed(1)}L';
    } else if (val >= 1000) {
      return '${(val / 1000).toStringAsFixed(1)}K';
    }
    return val.toStringAsFixed(0);
  }
}

class DateFormatter {
  static String format(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('dd MMM yyyy').format(date);
    } catch (_) {
      return dateStr;
    }
  }

  static String formatShort(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('dd MMM').format(date);
    } catch (_) {
      return dateStr;
    }
  }

  static String today() => DateFormat('yyyy-MM-dd').format(DateTime.now());
}
