import 'package:flutter_test/flutter_test.dart';
import 'package:work_time_tracker/domain/entities/employee.dart';
import 'package:work_time_tracker/domain/errors.dart';

import '../helpers/test_environment.dart';

void main() {
  late TestEnvironment env;

  setUp(() => env = TestEnvironment());

  group('Сотрудники', () {
    test('добавляются с нормализованным именем', () async {
      final employee = await env.tracking.addEmployee('  Анна   Смирнова ');

      expect(employee.name, 'Анна Смирнова');
      expect(await env.tracking.getEmployees(), [employee]);
    });

    test('возвращаются отсортированными по имени', () async {
      await env.tracking.addEmployee('Борис');
      await env.tracking.addEmployee('анна');

      final names = (await env.tracking.getEmployees()).map((e) => e.name);
      expect(names, ['анна', 'Борис']);
    });

    test('пустое имя отклоняется', () async {
      await expectLater(
        env.tracking.addEmployee('   '),
        throwsA(isA<ValidationException>()),
      );
      expect(await env.tracking.getEmployees(), isEmpty);
    });

    test('дубликат без учёта регистра отклоняется', () async {
      await env.tracking.addEmployee('Анна Смирнова');

      await expectLater(
        env.tracking.addEmployee('анна смирнова'),
        throwsA(isA<ValidationException>()),
      );
      expect(await env.tracking.getEmployees(), hasLength(1));
    });
  });

  group('Таймер', () {
    late Employee anna;

    setUp(() async => anna = await env.tracking.addEmployee('Анна'));

    test('запуск создаёт запущенную запись с описанием', () async {
      final entry = await env.tracking.startTimer(
        employeeId: anna.id,
        description: 'Вёрстка отчёта',
      );

      expect(entry.isRunning, isTrue);
      expect(entry.description, 'Вёрстка отчёта');
      expect(entry.startedAt, env.clock.now());
      expect(await env.tracking.getRunningEntries(), {anna.id: entry});
    });

    test('повторный запуск при идущем таймере отклоняется '
        'и не создаёт вторую запись', () async {
      final first = await env.tracking.startTimer(
        employeeId: anna.id,
        description: 'Задача 1',
      );

      await expectLater(
        env.tracking.startTimer(employeeId: anna.id, description: 'Задача 2'),
        throwsA(
          isA<TimerAlreadyRunningException>()
              .having((e) => e.runningEntry, 'runningEntry', first),
        ),
      );
      expect(await env.entryRepository.getAll(), [first]);
    });

    test('два одновременных запуска (двойной клик) дают одну запись',
        () async {
      final first = env.tracking.startTimer(
        employeeId: anna.id,
        description: 'Клик 1',
      );
      final second = env.tracking.startTimer(
        employeeId: anna.id,
        description: 'Клик 2',
      );

      await Future.wait([
        expectLater(first, completes),
        expectLater(second, throwsA(isA<TimerAlreadyRunningException>())),
      ]);
      expect(await env.entryRepository.getAll(), hasLength(1));
    });

    test('после остановки таймер можно запустить снова', () async {
      await env.tracking.startTimer(employeeId: anna.id, description: 'A');
      env.clock.advance(const Duration(minutes: 10));
      await env.tracking.stopTimer(anna.id);

      await env.tracking.startTimer(employeeId: anna.id, description: 'B');

      expect(await env.entryRepository.getAll(), hasLength(2));
      expect((await env.tracking.getRunningEntries())[anna.id]?.description,
          'B');
    });

    test('остановка фиксирует время окончания и длительность', () async {
      await env.tracking.startTimer(employeeId: anna.id, description: 'A');
      env.clock.advance(const Duration(minutes: 45));

      final stopped = await env.tracking.stopTimer(anna.id);

      expect(stopped.isRunning, isFalse);
      expect(stopped.endedAt, env.clock.now());
      expect(stopped.durationAt(env.clock.now()), const Duration(minutes: 45));
      expect(await env.tracking.getRunningEntries(), isEmpty);
    });

    test('остановка без запущенного таймера — ошибка', () async {
      await expectLater(
        env.tracking.stopTimer(anna.id),
        throwsA(isA<NoActiveTimerException>()),
      );
    });

    test('запуск без описания задачи отклоняется', () async {
      await expectLater(
        env.tracking.startTimer(employeeId: anna.id, description: '  '),
        throwsA(isA<ValidationException>()),
      );
      expect(await env.entryRepository.getAll(), isEmpty);
    });

    test('запуск для несуществующего сотрудника отклоняется', () async {
      await expectLater(
        env.tracking.startTimer(employeeId: 'нет-такого', description: 'A'),
        throwsA(isA<EmployeeNotFoundException>()),
      );
    });

    test('таймеры разных сотрудников независимы', () async {
      final boris = await env.tracking.addEmployee('Борис');

      await env.tracking.startTimer(employeeId: anna.id, description: 'A');
      await env.tracking.startTimer(employeeId: boris.id, description: 'B');

      expect((await env.tracking.getRunningEntries()).keys,
          unorderedEquals([anna.id, boris.id]));
    });

    test('перевод часов назад не даёт отрицательной длительности', () async {
      await env.tracking.startTimer(employeeId: anna.id, description: 'A');
      env.clock.advance(const Duration(minutes: -30));

      final stopped = await env.tracking.stopTimer(anna.id);

      expect(stopped.durationAt(env.clock.now()), Duration.zero);
    });
  });
}
