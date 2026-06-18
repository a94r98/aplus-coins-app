import 'package:intl/intl.dart';

class CurrencyFormatter {
  static String format(double coins, String country, bool isAr) {
    final formatter = NumberFormat('#,##0.##', 'en_US');
    final formatted = formatter.format(coins);
    return isAr ? '$formatted كونز' : '$formatted Coinz';
  }

  static String getLabel(String country, bool isAr) {
    return isAr ? 'الرصيد بالكونز' : 'Coinz Balance';
  }
}
