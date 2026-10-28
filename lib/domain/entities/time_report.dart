import 'package:equatable/equatable.dart';

import 'date_range.dart';
import 'employee.dart';
import 'time_entry.dart';

/// Запись в отчёте вместе с той частью её длительности,
/// что пришлась на выбранный период.
class ReportLine extends Equatable {
  const ReportLine({required this.entry, required this.duration});

  final TimeEntry entry;
  final Duration duration;

  @override
  List<Object?> get props => [entry, duration];
}

class EmployeeReport extends Equatable {
  const EmployeeReport({required this.employee, required this.lines});

  final Employee employee;

  /// Записи, отсортированные по времени начала.
  final List<ReportLine> lines;

  Duration get total =>
      lines.fold<Duration>(Duration.zero, (sum, line) => sum + line.duration);

  @override
  List<Object?> get props => [employee, lines];
}

class TimeReport extends Equatable {
  const TimeReport({required this.range, required this.employees});

  final DateRange range;

  /// Только сотрудники, у которых есть записи за период.
  final List<EmployeeReport> employees;

  bool get isEmpty => employees.isEmpty;

  Duration get total => employees.fold<Duration>(
        Duration.zero,
        (sum, employee) => sum + employee.total,
      );

  @override
  List<Object?> get props => [range, employees];
}
