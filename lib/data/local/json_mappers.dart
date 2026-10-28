import '../../domain/entities/employee.dart';
import '../../domain/entities/time_entry.dart';
import 'json_list_storage.dart';

// Время хранится в UTC (ISO 8601 с суффиксом Z) и переводится в локальное
// при чтении: смена часового пояса устройства не сдвигает уже сохранённые
// записи и не ломает расчёт длительности.

String _encodeDate(DateTime value) => value.toUtc().toIso8601String();

DateTime _decodeDate(String value) => DateTime.parse(value).toLocal();

JsonMap employeeToJson(Employee employee) => {
      'id': employee.id,
      'name': employee.name,
      'createdAt': _encodeDate(employee.createdAt),
    };

Employee employeeFromJson(JsonMap json) => Employee(
      id: json['id'] as String,
      name: json['name'] as String,
      createdAt: _decodeDate(json['createdAt'] as String),
    );

JsonMap timeEntryToJson(TimeEntry entry) {
  final endedAt = entry.endedAt;
  return {
    'id': entry.id,
    'employeeId': entry.employeeId,
    'description': entry.description,
    'startedAt': _encodeDate(entry.startedAt),
    'endedAt': endedAt == null ? null : _encodeDate(endedAt),
  };
}

TimeEntry timeEntryFromJson(JsonMap json) {
  final endedAt = json['endedAt'] as String?;
  return TimeEntry(
    id: json['id'] as String,
    employeeId: json['employeeId'] as String,
    description: json['description'] as String,
    startedAt: _decodeDate(json['startedAt'] as String),
    endedAt: endedAt == null ? null : _decodeDate(endedAt),
  );
}
