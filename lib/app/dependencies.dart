import '../core/clock.dart';
import '../core/id_generator.dart';
import '../core/storage/key_value_store.dart';
import '../data/repositories/local_employee_repository.dart';
import '../data/repositories/local_time_entry_repository.dart';
import '../domain/services/report_service.dart';
import '../domain/services/time_tracking_service.dart';

/// Композиция зависимостей приложения (composition root).
///
/// Единственное место, где выбираются конкретные реализации.
/// Тесты собирают те же сервисы поверх хранилища в памяти и фиктивных часов.
class AppDependencies {
  const AppDependencies({
    required this.clock,
    required this.timeTracking,
    required this.reports,
  });

  factory AppDependencies.local({
    required KeyValueStore store,
    Clock clock = const SystemClock(),
    IdGenerator? ids,
  }) {
    // Оба сервиса работают с одними экземплярами репозиториев,
    // поэтому их кэши в памяти не расходятся.
    final employees = LocalEmployeeRepository(store);
    final entries = LocalTimeEntryRepository(store);
    return AppDependencies(
      clock: clock,
      timeTracking: TimeTrackingService(
        employees: employees,
        entries: entries,
        clock: clock,
        ids: ids ?? RandomIdGenerator(),
      ),
      reports: ReportService(
        employees: employees,
        entries: entries,
        clock: clock,
      ),
    );
  }

  final Clock clock;
  final TimeTrackingService timeTracking;
  final ReportService reports;
}
