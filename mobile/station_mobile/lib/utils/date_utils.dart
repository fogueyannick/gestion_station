import 'package:intl/intl.dart';

/// Retourne une date formatée selon le [pattern] et la [locale].
/// Par défaut, la locale est 'fr'.
String formatDate(DateTime date, String pattern, {String locale = 'fr'}) {
  return DateFormat(pattern, locale).format(date);
}
