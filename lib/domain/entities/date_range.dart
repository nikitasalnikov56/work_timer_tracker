import 'package:equatable/equatable.dart';

/// Период отчёта в днях, обе границы включительно: [firstDay; lastDay].
///
/// Внутри период — полуинтервал [start; end), где [end] — полночь дня,
/// следующего за [lastDay]. Он вычисляется конструктором `DateTime`, а не
/// прибавлением `Duration(days: 1)`: в дни перехода на летнее/зимнее время
/// сутки длятся 23 или 25 часов, и прибавление 24 часов дало бы 23:00 или 01:00.
class DateRange extends Equatable {
  DateRange({required DateTime firstDay, required DateTime lastDay})
      : firstDay = _startOfDay(firstDay),
        lastDay = _startOfDay(lastDay) {
    if (this.lastDay.isBefore(this.firstDay)) {
      throw ArgumentError('Конец периода раньше его начала');
    }
  }

  /// Один календарный день.
  factory DateRange.day(DateTime day) => DateRange(firstDay: day, lastDay: day);

  /// Последние [days] дней, включая [today].
  factory DateRange.lastDays(DateTime today, int days) {
    if (days < 1) throw ArgumentError.value(days, 'days', 'должно быть ≥ 1');
    return DateRange(
      firstDay: DateTime(today.year, today.month, today.day - (days - 1)),
      lastDay: today,
    );
  }

  /// С первого числа текущего месяца по [today].
  factory DateRange.monthToDate(DateTime today) {
    return DateRange(
      firstDay: DateTime(today.year, today.month),
      lastDay: today,
    );
  }

  final DateTime firstDay;
  final DateTime lastDay;

  DateTime get start => firstDay;

  DateTime get end => DateTime(lastDay.year, lastDay.month, lastDay.day + 1);

  bool contains(DateTime moment) =>
      !moment.isBefore(start) && moment.isBefore(end);

  /// Попадает ли отрезок [from; to] в период.
  ///
  /// Запись, которая закончилась ровно в полночь начала периода, сюда
  /// не относится, а запись нулевой длины внутри периода — относится.
  bool intersects(DateTime from, DateTime to) =>
      contains(from) || (from.isBefore(end) && to.isAfter(start));

  /// Сколько времени отрезка [from; to] приходится на период.
  Duration overlap(DateTime from, DateTime to) {
    final clippedFrom = from.isAfter(start) ? from : start;
    final clippedTo = to.isBefore(end) ? to : end;
    return clippedTo.isAfter(clippedFrom)
        ? clippedTo.difference(clippedFrom)
        : Duration.zero;
  }

  static DateTime _startOfDay(DateTime moment) {
    final local = moment.toLocal();
    return DateTime(local.year, local.month, local.day);
  }

  @override
  List<Object?> get props => [firstDay, lastDay];
}
