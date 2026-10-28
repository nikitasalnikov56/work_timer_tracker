import 'package:equatable/equatable.dart';

import '../../domain/entities/employee.dart';
import '../../domain/entities/time_entry.dart';

enum TrackerStatus { loading, ready, failure }

/// Одноразовое сообщение для SnackBar.
///
/// Равенство намеренно по ссылке (без Equatable): два одинаковых текста
/// подряд — это два разных события, и показать нужно оба.
class UiMessage {
  UiMessage(this.text, {this.isError = true});

  final String text;
  final bool isError;
}

class TrackerState extends Equatable {
  const TrackerState({
    this.status = TrackerStatus.loading,
    this.employees = const [],
    this.runningEntries = const {},
    this.busyEmployeeIds = const {},
    this.failureText,
    this.message,
  });

  final TrackerStatus status;
  final List<Employee> employees;

  /// Запущенные таймеры по `employeeId`.
  final Map<String, TimeEntry> runningEntries;

  /// Сотрудники, для которых операция ещё выполняется: их кнопки
  /// блокируются, чтобы двойное нажатие не отправило два запроса.
  final Set<String> busyEmployeeIds;

  final String? failureText;

  /// Не переносится в следующее состояние: [copyWith] сбрасывает его.
  final UiMessage? message;

  TrackerState copyWith({
    TrackerStatus? status,
    List<Employee>? employees,
    Map<String, TimeEntry>? runningEntries,
    Set<String>? busyEmployeeIds,
    String? failureText,
    UiMessage? message,
  }) {
    return TrackerState(
      status: status ?? this.status,
      employees: employees ?? this.employees,
      runningEntries: runningEntries ?? this.runningEntries,
      busyEmployeeIds: busyEmployeeIds ?? this.busyEmployeeIds,
      failureText: failureText,
      message: message,
    );
  }

  @override
  List<Object?> get props => [
        status,
        employees,
        runningEntries,
        busyEmployeeIds,
        failureText,
        message,
      ];
}
