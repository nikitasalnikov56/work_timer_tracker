import 'package:work_time_tracker/app/dependencies.dart';
import 'package:work_time_tracker/core/clock.dart';
import 'package:work_time_tracker/core/id_generator.dart';
import 'package:work_time_tracker/data/local/in_memory_store.dart';
import 'package:work_time_tracker/data/repositories/local_employee_repository.dart';
import 'package:work_time_tracker/data/repositories/local_time_entry_repository.dart';
import 'package:work_time_tracker/domain/services/report_service.dart';
import 'package:work_time_tracker/domain/services/time_tracking_service.dart';

/// Часы, которыми управляет тест.
class FakeClock implements Clock {
  FakeClock(this._now);

  DateTime _now;

  @override
  DateTime now() => _now;

  void setNow(DateTime value) => _now = value;

  void advance(Duration duration) => _now = _now.add(duration);
}

/// Предсказуемые идентификаторы. Счётчик общий для всех экземпляров,
/// чтобы после «перезапуска» не появились дубликаты id.
class SequentialIdGenerator implements IdGenerator {
  static int _counter = 0;

  @override
  String next() => 'id-${++_counter}';
}

/// Приложение без UI: настоящие сервисы и репозитории поверх хранилища
/// в памяти и управляемых часов.
class TestEnvironment {
  TestEnvironment({DateTime? now, InMemoryStore? store})
      : clock = FakeClock(now ?? DateTime(2026, 10, 27, 9)),
        store = store ?? InMemoryStore() {
    employeeRepository = LocalEmployeeRepository(this.store);
    entryRepository = LocalTimeEntryRepository(this.store);
    tracking = TimeTrackingService(
      employees: employeeRepository,
      entries: entryRepository,
      clock: clock,
      ids: SequentialIdGenerator(),
    );
    reports = ReportService(
      employees: employeeRepository,
      entries: entryRepository,
      clock: clock,
    );
  }

  final FakeClock clock;
  final InMemoryStore store;
  late final LocalEmployeeRepository employeeRepository;
  late final LocalTimeEntryRepository entryRepository;
  late final TimeTrackingService tracking;
  late final ReportService reports;

  AppDependencies get dependencies => AppDependencies(
        clock: clock,
        timeTracking: tracking,
        reports: reports,
      );

  /// Имитирует перезапуск приложения: всё создаётся заново,
  /// общим остаётся только постоянное хранилище.
  TestEnvironment restart() => TestEnvironment(now: clock.now(), store: store);

  /// Записывает отрезок работы с [from] по [to] через публичные сценарии.
  Future<void> logWork(
    String employeeId,
    String description,
    DateTime from,
    DateTime to,
  ) async {
    clock.setNow(from);
    await tracking.startTimer(employeeId: employeeId, description: description);
    clock.setNow(to);
    await tracking.stopTimer(employeeId);
  }
}
