import 'package:shared_preferences/shared_preferences.dart';

import '../../core/storage/key_value_store.dart';
import '../../core/storage/storage_exception.dart';

/// Хранилище на SharedPreferences: localStorage в вебе,
/// системные настройки на мобильных и десктопе.
class SharedPreferencesStore implements KeyValueStore {
  SharedPreferencesStore(this._preferences);

  final SharedPreferences _preferences;

  @override
  Future<String?> read(String key) async => _preferences.getString(key);

  @override
  Future<void> write(String key, String value) async {
    final saved = await _preferences.setString(key, value);
    if (!saved) {
      throw StorageException('Не удалось сохранить данные ($key)');
    }
  }
}
