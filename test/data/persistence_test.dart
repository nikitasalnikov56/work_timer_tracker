import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:work_time_tracker/core/storage/storage_exception.dart';
import 'package:work_time_tracker/data/local/shared_preferences_store.dart';
import 'package:work_time_tracker/data/repositories/local_employee_repository.dart';
import 'package:work_time_tracker/data/repositories/local_time_entry_repository.dart';
import 'package:work_time_tracker/domain/entities/date_range.dart';
import 'package:work_time_tracker/domain/errors.dart';

import '../helpers/test_environment.dart';

void main() {
  group('Данные после перезапуска', () {
    test('сотрудники и завершённые записи сохраняются', () async {
      final env = TestEnvironment(now: DateTime(2026, 10, 27, 9));
      final anna = await env.tracking.addEmployee('Анна');
      await env.logWork(
        anna.id,
        'Отчёт',
        DateTime(2026, 10, 27, 9),
        DateTime(2026, 10, 27, 11),
      );

      final restarted = env.restart();

      expect(await restarted.tracking.getEmployees(), [anna]);
      final report = await restarted.reports.build(
        DateRange.day(DateTime(2026, 10, 27)),
      );
      expect(report.total, const Duration(hours: 2));
    });

    test('запущенный таймер восстанавливается и продолжает идти', () async {
      final env = TestEnvironment(now: DateTime(2026, 10, 27, 9));
      final anna = await env.tracking.addEmployee('Анна');
      final started = await env.tracking.startTimer(
        employeeId: anna.id,
        description: 'Долгая задача',
      );

      final restarted = env.restart();
      restarted.clock.advance(const Duration(hours: 3));

      final running = await restarted.tracking.getRunningEntries();
      expect(running[anna.id], started);
      expect(
        running[anna.id]!.durationAt(restarted.clock.now()),
        const Duration(hours: 3),
      );

      // После перезапуска повторный старт по-прежнему запрещён.
      await expectLater(
        restarted.tracking.startTimer(employeeId: anna.id, description: 'X'),
        throwsA(isA<TimerAlreadyRunningException>()),
      );
      final stopped = await restarted.tracking.stopTimer(anna.id);
      expect(stopped.endedAt, DateTime(2026, 10, 27, 12));
    });

    test('время хранится в UTC', () async {
      final env = TestEnvironment();
      final anna = await env.tracking.addEmployee('Анна');
      await env.tracking.startTimer(employeeId: anna.id, description: 'A');

      final raw = await env.store.read(LocalTimeEntryRepository.storageKey);
      final entries = jsonDecode(raw!) as List<Object?>;
      final entry = entries.single as Map<String, Object?>;

      expect(entry['startedAt'], endsWith('Z'));
      expect(entry['endedAt'], isNull);
    });

    test('повреждённые данные не затираются молча', () async {
      final env = TestEnvironment();
      await env.store.write(LocalEmployeeRepository.storageKey, '{не json');

      await expectLater(
        env.tracking.getEmployees(),
        throwsA(isA<StorageException>()),
      );
      await expectLater(
        env.tracking.addEmployee('Анна'),
        throwsA(isA<StorageException>()),
      );
      expect(
        await env.store.read(LocalEmployeeRepository.storageKey),
        '{не json',
      );
    });
  });

  group('SharedPreferencesStore', () {
    test('читает и записывает строки', () async {
      SharedPreferences.setMockInitialValues({});
      final store = SharedPreferencesStore(
        await SharedPreferences.getInstance(),
      );

      expect(await store.read('key'), isNull);
      await store.write('key', 'значение');
      expect(await store.read('key'), 'значение');
    });
  });
}
