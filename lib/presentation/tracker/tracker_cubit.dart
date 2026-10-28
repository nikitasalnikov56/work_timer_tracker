import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/storage/storage_exception.dart';
import '../../domain/errors.dart';
import '../../domain/services/time_tracking_service.dart';
import 'tracker_state.dart';

class TrackerCubit extends Cubit<TrackerState> {
  TrackerCubit(this._service) : super(const TrackerState());

  final TimeTrackingService _service;

  Future<void> load() async {
    emit(state.copyWith(status: TrackerStatus.loading));
    try {
      final employees = await _service.getEmployees();
      final running = await _service.getRunningEntries();
      if (isClosed) return;
      emit(
        state.copyWith(
          status: TrackerStatus.ready,
          employees: employees,
          runningEntries: running,
        ),
      );
    } on StorageException catch (error) {
      if (isClosed) return;
      emit(
        state.copyWith(
          status: TrackerStatus.failure,
          failureText: error.message,
        ),
      );
    }
  }

  /// Возвращает текст ошибки для показа в диалоге или `null` при успехе.
  Future<String?> addEmployee(String name) async {
    try {
      final employee = await _service.addEmployee(name);
      final employees = await _service.getEmployees();
      if (!isClosed) {
        emit(
          state.copyWith(
            employees: employees,
            message: UiMessage(
              'Сотрудник «${employee.name}» добавлен',
              isError: false,
            ),
          ),
        );
      }
      return null;
    } on DomainException catch (error) {
      return error.message;
    } on StorageException catch (error) {
      return error.message;
    }
  }

  Future<void> startTimer(String employeeId, String description) {
    return _runFor(
      employeeId,
      () => _service.startTimer(
        employeeId: employeeId,
        description: description,
      ),
    );
  }

  Future<void> stopTimer(String employeeId) {
    return _runFor(employeeId, () => _service.stopTimer(employeeId));
  }

  Future<void> _runFor(
    String employeeId,
    Future<Object?> Function() action,
  ) async {
    if (state.busyEmployeeIds.contains(employeeId)) return;
    emit(
      state.copyWith(
        busyEmployeeIds: {...state.busyEmployeeIds, employeeId},
      ),
    );

    UiMessage? message;
    try {
      await action();
    } on DomainException catch (error) {
      message = UiMessage(error.message);
    } on StorageException catch (error) {
      message = UiMessage(error.message);
    }

    // Состояние перечитывается и после ошибки: например, если таймер
    // уже запущен в другом месте, кнопка должна смениться на «Стоп».
    var running = state.runningEntries;
    try {
      running = await _service.getRunningEntries();
    } on StorageException catch (error) {
      message ??= UiMessage(error.message);
    }

    if (isClosed) return;
    emit(
      state.copyWith(
        runningEntries: running,
        busyEmployeeIds: {...state.busyEmployeeIds}..remove(employeeId),
        message: message,
      ),
    );
  }
}
