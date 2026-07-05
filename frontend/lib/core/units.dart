import 'package:intl/intl.dart';

/// The design speaks lbs; the backend stores kg.
class Units {
  static const double _lbsPerKg = 2.2046226218;

  static double kgToLbs(double kg) => kg * _lbsPerKg;

  static double lbsToKg(double lbs) => lbs / _lbsPerKg;
}

final NumberFormat _grouped = NumberFormat('#,##0');

String formatKcal(num kcal) => _grouped.format(kcal);

String formatLbs(double lbs) {
  final rounded = (lbs * 10).roundToDouble() / 10;
  return rounded == rounded.truncateToDouble()
      ? rounded.toStringAsFixed(0)
      : rounded.toStringAsFixed(1);
}

/// "TUESDAY · JULY 7"
String capsDate(DateTime date) {
  final weekday = DateFormat('EEEE').format(date).toUpperCase();
  final monthDay = DateFormat('MMMM d').format(date).toUpperCase();
  return '$weekday · $monthDay';
}

/// "June 7"
String prettyDate(DateTime date) => DateFormat('MMMM d').format(date);

String apiDate(DateTime date) => DateFormat('yyyy-MM-dd').format(date);
