import '../../domain/entities/date_range.dart';

/// `1:05:09` — часы не ограничены 24, чтобы итог за месяц читался как есть.
String formatDuration(Duration duration) {
  final safe = duration.isNegative ? Duration.zero : duration;
  final hours = safe.inHours;
  final minutes = safe.inMinutes.remainder(60);
  final seconds = safe.inSeconds.remainder(60);
  return '$hours:${_twoDigits(minutes)}:${_twoDigits(seconds)}';
}

/// `27.10.2026`
String formatDate(DateTime date) =>
    '${_twoDigits(date.day)}.${_twoDigits(date.month)}.${date.year}';

/// `09:05`
String formatTime(DateTime time) =>
    '${_twoDigits(time.hour)}:${_twoDigits(time.minute)}';

String formatRange(DateRange range) {
  if (range.firstDay == range.lastDay) return formatDate(range.firstDay);
  return '${formatDate(range.firstDay)} — ${formatDate(range.lastDay)}';
}

/// Русское склонение: 1 запись, 2 записи, 5 записей, 11 записей, 21 запись.
String pluralRu(int count, String one, String few, String many) {
  final mod10 = count % 10;
  final mod100 = count % 100;
  if (mod10 == 1 && mod100 != 11) return one;
  if (mod10 >= 2 && mod10 <= 4 && (mod100 < 12 || mod100 > 14)) return few;
  return many;
}

String _twoDigits(int value) => value.toString().padLeft(2, '0');
