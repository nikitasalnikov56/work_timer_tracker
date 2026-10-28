import 'dart:convert';

import '../../core/storage/key_value_store.dart';
import '../../core/storage/storage_exception.dart';

typedef JsonMap = Map<String, Object?>;

/// Хранит список объектов одним JSON-массивом под ключом [key].
///
/// Повреждённые данные не превращаются молча в пустой список:
/// иначе первая же запись перезаписала бы их и данные были бы потеряны.
class JsonListStorage<T> {
  JsonListStorage({
    required KeyValueStore store,
    required this.key,
    required T Function(JsonMap json) fromJson,
    required JsonMap Function(T item) toJson,
  })  : _store = store,
        _fromJson = fromJson,
        _toJson = toJson;

  final String key;
  final KeyValueStore _store;
  final T Function(JsonMap json) _fromJson;
  final JsonMap Function(T item) _toJson;

  Future<List<T>> load() async {
    final raw = await _store.read(key);
    if (raw == null || raw.isEmpty) return [];

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        throw const FormatException('ожидался JSON-массив');
      }
      return [
        for (final item in decoded)
          _fromJson((item as Map<Object?, Object?>).cast<String, Object?>()),
      ];
    } on FormatException catch (error) {
      throw StorageException('Данные «$key» повреждены: ${error.message}');
    } on TypeError catch (error) {
      throw StorageException('Данные «$key» повреждены: $error');
    }
  }

  Future<void> save(List<T> items) {
    return _store.write(key, jsonEncode([for (final item in items) _toJson(item)]));
  }
}
