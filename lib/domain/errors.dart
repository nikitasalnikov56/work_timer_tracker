import 'entities/time_entry.dart';

/// Нарушение бизнес-правила. Текст [message] предназначен для пользователя.
sealed class DomainException implements Exception {
  const DomainException(this.message);

  final String message;

  @override
  String toString() => message;
}

final class ValidationException extends DomainException {
  const ValidationException(super.message);
}

final class EmployeeNotFoundException extends DomainException {
  const EmployeeNotFoundException() : super('Сотрудник не найден');
}

/// Повторный запуск таймера, пока предыдущий не остановлен.
final class TimerAlreadyRunningException extends DomainException {
  TimerAlreadyRunningException(this.runningEntry)
      : super(
          'Таймер уже запущен (задача «${runningEntry.description}»). '
          'Сначала остановите его.',
        );

  final TimeEntry runningEntry;
}

final class NoActiveTimerException extends DomainException {
  const NoActiveTimerException() : super('Нет запущенного таймера');
}
