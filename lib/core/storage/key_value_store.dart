/// Минимальный контракт постоянного хранилища «ключ → строка».
///
/// Репозитории зависят только от него, поэтому хранилище можно заменить
/// (SharedPreferences, файл, SQLite) без изменений в остальном коде,
/// а в тестах использовать хранилище в памяти.
abstract interface class KeyValueStore {
  Future<String?> read(String key);

  Future<void> write(String key, String value);
}
