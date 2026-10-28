import 'package:flutter_test/flutter_test.dart';
import 'package:work_time_tracker/domain/entities/date_range.dart';
import 'package:work_time_tracker/domain/entities/employee.dart';

import '../helpers/test_environment.dart';

void main() {
  late TestEnvironment env;
  late Employee anna;
  late Employee boris;

  final oct26 = DateTime(2026, 10, 26);
  final oct27 = DateTime(2026, 10, 27);

  DateTime at(DateTime day, int hour, [int minute = 0]) =>
      DateTime(day.year, day.month, day.day, hour, minute);

  setUp(() async {
    env = TestEnvironment(now: at(oct27, 18));
    anna = await env.tracking.addEmployee('Анна');
    boris = await env.tracking.addEmployee('Борис');
  });

  test('пустой отчёт, когда записей нет вообще', () async {
    final report = await env.reports.build(DateRange.day(oct27));

    expect(report.isEmpty, isTrue);
    expect(report.employees, isEmpty);
    expect(report.total, Duration.zero);
  });

  test('пустой отчёт, когда все записи вне периода', () async {
    await env.logWork(anna.id, 'Вчера', at(oct26, 10), at(oct26, 12));
    env.clock.setNow(at(oct27, 18));

    final report = await env.reports.build(DateRange.day(oct27));

    expect(report.isEmpty, isTrue);
  });

  test('суммирует время каждого сотрудника отдельно', () async {
    await env.logWork(anna.id, 'A1', at(oct27, 9), at(oct27, 10, 30));
    await env.logWork(anna.id, 'A2', at(oct27, 11), at(oct27, 12));
    await env.logWork(boris.id, 'B1', at(oct27, 9), at(oct27, 9, 15));
    env.clock.setNow(at(oct27, 18));

    final report = await env.reports.build(DateRange.day(oct27));

    expect(report.employees.map((e) => e.employee), [anna, boris]);
    expect(report.employees[0].total, const Duration(hours: 2, minutes: 30));
    expect(report.employees[0].lines.map((l) => l.entry.description),
        ['A1', 'A2']);
    expect(report.employees[1].total, const Duration(minutes: 15));
    expect(report.total, const Duration(hours: 2, minutes: 45));
  });

  test('запись через полночь делится между днями', () async {
    await env.logWork(anna.id, 'Релиз', at(oct26, 23), at(oct27, 1, 30));

    final day1 = await env.reports.build(DateRange.day(oct26));
    final day2 = await env.reports.build(DateRange.day(oct27));
    final both = await env.reports.build(
      DateRange(firstDay: oct26, lastDay: oct27),
    );

    expect(day1.total, const Duration(hours: 1));
    expect(day2.total, const Duration(hours: 1, minutes: 30));
    expect(both.total, const Duration(hours: 2, minutes: 30));
  });

  test('запись, закончившаяся ровно в полночь, не попадает в следующий день',
      () async {
    await env.logWork(anna.id, 'Вечер', at(oct26, 22), oct27);

    final report = await env.reports.build(DateRange.day(oct27));

    expect(report.isEmpty, isTrue);
  });

  test('запущенный таймер учитывается до текущего момента', () async {
    env.clock.setNow(at(oct27, 14));
    await env.tracking.startTimer(employeeId: anna.id, description: 'Идёт');
    env.clock.setNow(at(oct27, 15, 20));

    final report = await env.reports.build(DateRange.day(oct27));

    expect(report.employees.single.total, const Duration(hours: 1, minutes: 20));
    expect(report.employees.single.lines.single.entry.isRunning, isTrue);
  });

  test('фильтр по сотруднику оставляет только его записи', () async {
    await env.logWork(anna.id, 'A', at(oct27, 9), at(oct27, 10));
    await env.logWork(boris.id, 'B', at(oct27, 9), at(oct27, 11));

    final report = await env.reports.build(
      DateRange.day(oct27),
      employeeId: boris.id,
    );

    expect(report.employees.single.employee, boris);
    expect(report.total, const Duration(hours: 2));
  });
}
