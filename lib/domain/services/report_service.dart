import '../../core/clock.dart';
import '../entities/date_range.dart';
import '../entities/time_report.dart';
import '../repositories/employee_repository.dart';
import '../repositories/time_entry_repository.dart';

/// Строит отчёт: записи и итоговое время каждого сотрудника за период.
///
/// Запись учитывается только той частью, что попала в период: работа
/// с 23:00 до 01:30 даст 1 ч в первый день и 1 ч 30 мин во второй.
/// Запущенный таймер считается до текущего момента.
class ReportService {
  ReportService({
    required EmployeeRepository employees,
    required TimeEntryRepository entries,
    required Clock clock,
  })  : _employees = employees,
        _entries = entries,
        _clock = clock;

  final EmployeeRepository _employees;
  final TimeEntryRepository _entries;
  final Clock _clock;

  Future<TimeReport> build(DateRange range, {String? employeeId}) async {
    final now = _clock.now();
    final employees = await _employees.getAll();
    final entries = await _entries.getAll();

    final linesByEmployee = <String, List<ReportLine>>{};
    for (final entry in entries) {
      if (employeeId != null && entry.employeeId != employeeId) continue;

      final end = entry.endOr(now);
      if (!range.intersects(entry.startedAt, end)) continue;

      linesByEmployee.putIfAbsent(entry.employeeId, () => []).add(
            ReportLine(
              entry: entry,
              duration: range.overlap(entry.startedAt, end),
            ),
          );
    }

    final reports = <EmployeeReport>[];
    for (final employee in employees) {
      final lines = linesByEmployee[employee.id];
      if (lines == null) continue;
      lines.sort((a, b) => a.entry.startedAt.compareTo(b.entry.startedAt));
      reports.add(EmployeeReport(employee: employee, lines: lines));
    }
    reports.sort(
      (a, b) => a.employee.name
          .toLowerCase()
          .compareTo(b.employee.name.toLowerCase()),
    );

    return TimeReport(range: range, employees: reports);
  }
}
