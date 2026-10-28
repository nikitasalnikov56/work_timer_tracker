import '../../core/storage/key_value_store.dart';

/// Хранилище в памяти. Используется в тестах: «перезапуск приложения»
/// моделируется созданием новых репозиториев поверх того же экземпляра.
class InMemoryStore implements KeyValueStore {
  final Map<String, String> _values = {};

  @override
  Future<String?> read(String key) async => _values[key];

  @override
  Future<void> write(String key, String value) async {
    _values[key] = value;
  }
}
