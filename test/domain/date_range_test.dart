import 'package:flutter_test/flutter_test.dart';
import 'package:work_time_tracker/domain/entities/date_range.dart';

void main() {
  test('границы приводятся к началу дня, конец — полночь следующего дня', () {
    final range = DateRange(
      firstDay: DateTime(2026, 10, 1, 15, 30),
      lastDay: DateTime(2026, 10, 31, 9),
    );

    expect(range.start, DateTime(2026, 10, 1));
    expect(range.end, DateTime(2026, 11, 1));
  });

  test('последние 7 дней включают сегодняшний', () {
    final range = DateRange.lastDays(DateTime(2026, 10, 3, 12), 7);

    expect(range.firstDay, DateTime(2026, 9, 27));
    expect(range.lastDay, DateTime(2026, 10, 3));
  });

  test('с начала месяца', () {
    final range = DateRange.monthToDate(DateTime(2026, 10, 27, 12));

    expect(range.firstDay, DateTime(2026, 10, 1));
    expect(range.lastDay, DateTime(2026, 10, 27));
  });

  test('конец раньше начала — ошибка', () {
    expect(
      () => DateRange(
        firstDay: DateTime(2026, 10, 27),
        lastDay: DateTime(2026, 10, 26),
      ),
      throwsArgumentError,
    );
  });

  test('overlap обрезает отрезок по границам периода', () {
    final range = DateRange.day(DateTime(2026, 10, 27));

    expect(
      range.overlap(DateTime(2026, 10, 26, 23), DateTime(2026, 10, 27, 2)),
      const Duration(hours: 2),
    );
    expect(
      range.overlap(DateTime(2026, 10, 25), DateTime(2026, 10, 26)),
      Duration.zero,
    );
  });
}
