import '../../core/storage/key_value_store.dart';
import '../../domain/entities/time_entry.dart';
import '../../domain/repositories/time_entry_repository.dart';
import '../local/json_list_storage.dart';
import '../local/json_mappers.dart';

class LocalTimeEntryRepository implements TimeEntryRepository {
  LocalTimeEntryRepository(KeyValueStore store)
      : _storage = JsonListStorage<TimeEntry>(
          store: store,
          key: storageKey,
          fromJson: timeEntryFromJson,
          toJson: timeEntryToJson,
        );

  static const storageKey = 'time_entries_v1';

  final JsonListStorage<TimeEntry> _storage;
  List<TimeEntry>? _cache;

  Future<List<TimeEntry>> _items() async => _cache ??= await _storage.load();

  @override
  Future<List<TimeEntry>> getAll() async => List.unmodifiable(await _items());

  @override
  Future<TimeEntry?> findRunning(String employeeId) async {
    for (final entry in await _items()) {
      if (entry.employeeId == employeeId && entry.isRunning) return entry;
    }
    return null;
  }

  @override
  Future<void> save(TimeEntry entry) async {
    final items = await _items();
    final index = items.indexWhere((item) => item.id == entry.id);
    final updated = [...items];
    if (index == -1) {
      updated.add(entry);
    } else {
      updated[index] = entry;
    }
    await _storage.save(updated);
    _cache = updated;
  }
}
