import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/clock.dart';
import '../../core/storage/storage_exception.dart';
import '../../domain/entities/date_range.dart';
import '../../domain/services/report_service.dart';
import 'report_state.dart';

export 'report_state.dart';

class ReportCubit extends Cubit<ReportState> {
  ReportCubit({required ReportService service, required Clock clock})
      : _service = service,
        _clock = clock,
        super(ReportState(range: DateRange.day(clock.now())));

  final ReportService _service;
  final Clock _clock;

  Future<void> load() async {
    final request = (state.range, state.employeeId);
    emit(state.copyWith(status: ReportStatus.loading));
    try {
      final report = await _service.build(
        state.range,
        employeeId: state.employeeId,
      );
      if (isClosed) return;
      // Пока отчёт строился, фильтр могли сменить: устаревший результат
      // не должен перезаписать актуальный.
      if (request != (state.range, state.employeeId)) return;
      emit(state.copyWith(status: ReportStatus.ready, report: report));
    } on StorageException catch (error) {
      if (isClosed) return;
      emit(
        state.copyWith(
          status: ReportStatus.failure,
          failureText: error.message,
        ),
      );
    }
  }

  Future<void> selectRange(DateRange range) {
    emit(state.copyWith(range: range));
    return load();
  }

  Future<void> selectPreset(ReportPreset preset) {
    final today = _clock.now();
    return selectRange(
      switch (preset) {
        ReportPreset.today => DateRange.day(today),
        ReportPreset.week => DateRange.lastDays(today, 7),
        ReportPreset.month => DateRange.monthToDate(today),
      },
    );
  }

  Future<void> selectEmployee(String? employeeId) {
    emit(state.withEmployee(employeeId));
    return load();
  }
}
