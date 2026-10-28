import 'package:equatable/equatable.dart';

import '../../domain/entities/date_range.dart';
import '../../domain/entities/time_report.dart';

enum ReportStatus { loading, ready, failure }

enum ReportPreset { today, week, month }

class ReportState extends Equatable {
  const ReportState({
    required this.range,
    this.employeeId,
    this.status = ReportStatus.loading,
    this.report,
    this.failureText,
  });

  final DateRange range;

  /// `null` — все сотрудники.
  final String? employeeId;

  final ReportStatus status;

  /// Последний построенный отчёт. Во время перезагрузки остаётся на экране,
  /// чтобы список не мигал.
  final TimeReport? report;

  final String? failureText;

  ReportState copyWith({
    DateRange? range,
    ReportStatus? status,
    TimeReport? report,
    String? failureText,
  }) {
    return ReportState(
      range: range ?? this.range,
      employeeId: employeeId,
      status: status ?? this.status,
      report: report ?? this.report,
      failureText: failureText,
    );
  }

  /// Отдельный метод, потому что через [copyWith] нельзя сбросить фильтр в `null`.
  ReportState withEmployee(String? employeeId) {
    return ReportState(
      range: range,
      employeeId: employeeId,
      status: status,
      report: report,
    );
  }

  @override
  List<Object?> get props => [range, employeeId, status, report, failureText];
}
