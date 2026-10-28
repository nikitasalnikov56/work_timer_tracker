import '../entities/employee.dart';

abstract interface class EmployeeRepository {
  Future<List<Employee>> getAll();

  Future<Employee?> findById(String id);

  Future<void> add(Employee employee);
}
