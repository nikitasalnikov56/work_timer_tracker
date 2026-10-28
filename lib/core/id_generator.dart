import 'dart:math';

/// Генератор уникальных идентификаторов сущностей.
abstract interface class IdGenerator {
  String next();
}

/// Время в микросекундах + случайный суффикс: уникально без внешних пакетов
/// и при этом сортируется примерно по времени создания.
class RandomIdGenerator implements IdGenerator {
  RandomIdGenerator({Random? random}) : _random = random ?? Random.secure();

  final Random _random;

  @override
  String next() {
    final timestamp = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
    final suffix = List.generate(
      6,
      (_) => _random.nextInt(36).toRadixString(36),
    ).join();
    return '$timestamp$suffix';
  }
}
