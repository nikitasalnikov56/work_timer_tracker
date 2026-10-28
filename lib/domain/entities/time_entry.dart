import 'package:equatable/equatable.dart';

/// Отрезок работы сотрудника над задачей.
///
/// Пока [endedAt] равен `null`, таймер считается запущенным.
class TimeEntry extends Equatable {
  const TimeEntry({
    required this.id,
    required this.employeeId,
    required this.description,
    required this.startedAt,
    this.endedAt,
  });

  final String id;
  final String employeeId;
  final String description;
  final DateTime startedAt;
  final DateTime? endedAt;

  bool get isRunning => endedAt == null;

  /// Момент окончания; для запущенного таймера — [now].
  DateTime endOr(DateTime now) => endedAt ?? now;

  /// Длительность записи. Никогда не бывает отрицательной, даже если
  /// системные часы перевели назад во время работы таймера.
  Duration durationAt(DateTime now) {
    final end = endOr(now);
    return end.isAfter(startedAt) ? end.difference(startedAt) : Duration.zero;
  }

  /// Останавливает таймер в момент [moment] (но не раньше начала записи).
  TimeEntry stoppedAt(DateTime moment) {
    return TimeEntry(
      id: id,
      employeeId: employeeId,
      description: description,
      startedAt: startedAt,
      endedAt: moment.isBefore(startedAt) ? startedAt : moment,
    );
  }

  @override
  List<Object?> get props => [id, employeeId, description, startedAt, endedAt];
}
