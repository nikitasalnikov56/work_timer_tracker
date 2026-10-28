/// Источник текущего времени.
///
/// Вся логика берёт «сейчас» только отсюда, поэтому тесты подменяют часы
/// и проверяют сценарии вроде «прошло 90 минут» без реального ожидания.
abstract interface class Clock {
  DateTime now();
}

class SystemClock implements Clock {
  const SystemClock();

  @override
  DateTime now() => DateTime.now();
}
