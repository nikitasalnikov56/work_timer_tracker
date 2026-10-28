import '../../core/storage/key_value_store.dart';
import '../../domain/entities/employee.dart';
import '../../domain/repositories/employee_repository.dart';
import '../local/json_list_storage.dart';
import '../local/json_mappers.dart';

class LocalEmployeeRepository implements EmployeeRepository {
  LocalEmployeeRepository(KeyValueStore store)
      : _storage = JsonListStorage<Employee>(
          store: store,
          key: storageKey,
          fromJson: employeeFromJson,
          toJson: employeeToJson,
        );

  /// Версия в ключе позволит в будущем мигрировать формат данных.
  static const storageKey = 'employees_v1';

  final JsonListStorage<Employee> _storage;
  List<Employee>? _cache;

  Future<List<Employee>> _items() async => _cache ??= await _storage.load();

  @override
  Future<List<Employee>> getAll() async => List.unmodifiable(await _items());

  @override
  Future<Employee?> findById(String id) async {
    for (final employee in await _items()) {
      if (employee.id == id) return employee;
    }
    return null;
  }

  @override
  Future<void> add(Employee employee) async {
    final updated = [...await _items(), employee];
    // Кэш обновляется только после успешной записи,
    // чтобы память и хранилище не расходились при ошибке.
    await _storage.save(updated);
    _cache = updated;
  }
}
