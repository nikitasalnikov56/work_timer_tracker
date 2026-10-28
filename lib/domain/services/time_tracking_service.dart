import '../../core/clock.dart';
import '../../core/id_generator.dart';
import '../../core/serial_executor.dart';
import '../entities/employee.dart';
import '../entities/time_entry.dart';
import '../errors.dart';
import '../repositories/employee_repository.dart';
import '../repositories/time_entry_repository.dart';

/// Сценарии учёта времени: сотрудники и таймеры.
///
/// Бизнес-правила живут здесь, а не в UI:
/// * имя сотрудника непустое и уникальное без учёта регистра;
/// * у сотрудника не больше одного запущенного таймера;
/// * таймер нельзя запустить без описания задачи.
class TimeTrackingService {
  TimeTrackingService({
    required EmployeeRepository employees,
    required TimeEntryRepository entries,
    required Clock clock,
    required IdGenerator ids,
  })  : _employees = employees,
        _entries = entries,
        _clock = clock,
        _ids = ids;

  static const maxNameLength = 100;
  static const maxDescriptionLength = 300;

  final EmployeeRepository _employees;
  final TimeEntryRepository _entries;
  final Clock _clock;
  final IdGenerator _ids;

  /// Изменяющие операции выполняются по очереди: проверка
  /// «нет ли уже таймера» и сохранение должны быть атомарными.
  final _queue = SerialExecutor();

  Future<List<Employee>> getEmployees() async {
    final employees = await _employees.getAll();
    return [...employees]..sort(
        (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      );
  }

  Future<Employee> addEmployee(String rawName) {
    return _queue.run(() async {
      final name = _normalize(rawName);
      if (name.isEmpty) {
        throw const ValidationException('Введите имя сотрудника');
      }
      if (name.length > maxNameLength) {
        throw const ValidationException(
          'Имя не должно быть длиннее $maxNameLength символов',
        );
      }

      final existing = await _employees.getAll();
      final key = name.toLowerCase();
      if (existing.any((employee) => employee.name.toLowerCase() == key)) {
        throw ValidationException('Сотрудник «$name» уже есть в списке');
      }

      final employee = Employee(
        id: _ids.next(),
        name: name,
        createdAt: _clock.now(),
      );
      await _employees.add(employee);
      return employee;
    });
  }

  /// Запущенные таймеры, сгруппированные по `employeeId`.
  Future<Map<String, TimeEntry>> getRunningEntries() async {
    final entries = await _entries.getAll();
    return {
      for (final entry in entries)
        if (entry.isRunning) entry.employeeId: entry,
    };
  }

  Future<TimeEntry> startTimer({
    required String employeeId,
    required String description,
  }) {
    return _queue.run(() async {
      final text = _normalize(description);
      if (text.isEmpty) {
        throw const ValidationException(
          'Опишите задачу перед запуском таймера',
        );
      }
      if (text.length > maxDescriptionLength) {
        throw const ValidationException(
          'Описание не должно быть длиннее $maxDescriptionLength символов',
        );
      }
      if (await _employees.findById(employeeId) == null) {
        throw const EmployeeNotFoundException();
      }

      final running = await _entries.findRunning(employeeId);
      if (running != null) throw TimerAlreadyRunningException(running);

      final entry = TimeEntry(
        id: _ids.next(),
        employeeId: employeeId,
        description: text,
        startedAt: _clock.now(),
      );
      await _entries.save(entry);
      return entry;
    });
  }

  Future<TimeEntry> stopTimer(String employeeId) {
    return _queue.run(() async {
      final running = await _entries.findRunning(employeeId);
      if (running == null) throw const NoActiveTimerException();

      final stopped = running.stoppedAt(_clock.now());
      await _entries.save(stopped);
      return stopped;
    });
  }

  /// Обрезает пробелы по краям и схлопывает повторяющиеся внутри.
  static String _normalize(String value) =>
      value.trim().replaceAll(RegExp(r'\s+'), ' ');
}
