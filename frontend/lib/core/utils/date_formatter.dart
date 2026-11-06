import 'package:intl/intl.dart';

/// Utilitas pemformatan tanggal dan waktu untuk kartu serta detail catatan.
class DateFormatter {
  DateFormatter._();

  static final DateFormat _cardFormat = DateFormat('dd MMM yyyy');
  static final DateFormat _detailFormat = DateFormat('dd MMM yyyy • HH:mm');

  static String formatCardDate(DateTime dateTime) {
    return _cardFormat.format(dateTime.toLocal());
  }

  static String formatDetailDate(DateTime dateTime) {
    return _detailFormat.format(dateTime.toLocal());
  }
}
