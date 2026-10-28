import '../entities/time_entry.dart';

abstract interface class TimeEntryRepository {
  Future<List<TimeEntry>> getAll();

  /// Запущенный (не остановленный) таймер сотрудника, если он есть.
  Future<TimeEntry?> findRunning(String employeeId);

  /// Добавляет запись или заменяет существующую с тем же `id`.
  Future<void> save(TimeEntry entry);
}
