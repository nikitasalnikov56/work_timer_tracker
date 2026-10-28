import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/clock.dart';
import '../../domain/entities/date_range.dart';
import '../../domain/entities/employee.dart';
import '../../domain/entities/time_entry.dart';
import '../../domain/entities/time_report.dart';
import '../common/formatters.dart';
import '../common/status_views.dart';
import '../tracker/tracker_cubit.dart';
import '../tracker/tracker_state.dart';
import 'report_cubit.dart';

class ReportPage extends StatelessWidget {
  const ReportPage({super.key});

  static const emptyText = 'За выбранный период записей нет';

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ReportCubit, ReportState>(
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: _Filters(state: state),
            ),
            SizedBox(
              height: 4,
              child: state.status == ReportStatus.loading
                  ? const LinearProgressIndicator()
                  : null,
            ),
            Expanded(child: _ReportBody(state: state)),
          ],
        );
      },
    );
  }
}

class _Filters extends StatelessWidget {
  const _Filters({required this.state});

  final ReportState state;

  static const _presetLabels = {
    ReportPreset.today: 'Сегодня',
    ReportPreset.week: '7 дней',
    ReportPreset.month: 'Этот месяц',
  };

  Future<void> _pickRange(BuildContext context) async {
    final cubit = context.read<ReportCubit>();
    final now = context.read<Clock>().now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 1, 12, 31),
      initialDateRange: DateTimeRange(
        start: state.range.firstDay,
        end: state.range.lastDay,
      ),
      helpText: 'Период отчёта',
    );
    if (picked == null) return;
    await cubit.selectRange(
      DateRange(firstDay: picked.start, lastDay: picked.end),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (final preset in ReportPreset.values)
          ActionChip(
            label: Text(_presetLabels[preset]!),
            onPressed: () =>
                context.read<ReportCubit>().selectPreset(preset),
          ),
        OutlinedButton.icon(
          onPressed: () => _pickRange(context),
          icon: const Icon(Icons.date_range),
          label: Text(formatRange(state.range)),
        ),
        BlocSelector<TrackerCubit, TrackerState, List<Employee>>(
          selector: (trackerState) => trackerState.employees,
          builder: (context, employees) => DropdownButton<String?>(
            value: state.employeeId,
            onChanged: (employeeId) =>
                context.read<ReportCubit>().selectEmployee(employeeId),
            items: [
              const DropdownMenuItem<String?>(
                child: Text('Все сотрудники'),
              ),
              for (final employee in employees)
                DropdownMenuItem<String?>(
                  value: employee.id,
                  child: Text(employee.name),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ReportBody extends StatelessWidget {
  const _ReportBody({required this.state});

  final ReportState state;

  @override
  Widget build(BuildContext context) {
    final report = state.report;

    if (state.status == ReportStatus.failure) {
      return StatusView(
        icon: Icons.error_outline,
        title: 'Не удалось построить отчёт',
        description: state.failureText,
        action: FilledButton(
          onPressed: () => context.read<ReportCubit>().load(),
          child: const Text('Повторить'),
        ),
      );
    }
    if (report == null) return const SizedBox.shrink();
    if (report.isEmpty) {
      return const StatusView(
        icon: Icons.event_busy,
        title: ReportPage.emptyText,
        description: 'Выберите другой период или запустите таймер '
            'на вкладке «Трекер».',
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        _TotalCard(report: report),
        const SizedBox(height: 12),
        for (final employeeReport in report.employees)
          _EmployeeReportCard(report: employeeReport),
      ],
    );
  }
}

class _TotalCard extends StatelessWidget {
  const _TotalCard({required this.report});

  final TimeReport report;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      color: theme.colorScheme.primaryContainer,
      child: ListTile(
        title: const Text('Итого за период'),
        subtitle: Text(formatRange(report.range)),
        trailing: Text(
          formatDuration(report.total),
          style: theme.textTheme.titleLarge?.copyWith(
            color: theme.colorScheme.onPrimaryContainer,
          ),
        ),
      ),
    );
  }
}

class _EmployeeReportCard extends StatelessWidget {
  const _EmployeeReportCard({required this.report});

  final EmployeeReport report;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final count = report.lines.length;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        initiallyExpanded: true,
        shape: const Border(),
        collapsedShape: const Border(),
        title: Text(report.employee.name),
        subtitle: Text(
          '$count ${pluralRu(count, 'запись', 'записи', 'записей')}',
        ),
        trailing: Text(
          formatDuration(report.total),
          style: theme.textTheme.titleMedium,
        ),
        children: [
          for (final line in report.lines) _ReportLineTile(line: line),
        ],
      ),
    );
  }
}

class _ReportLineTile extends StatelessWidget {
  const _ReportLineTile({required this.line});

  final ReportLine line;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      title: Text(line.entry.description),
      subtitle: Text(_interval(line.entry)),
      trailing: Text(formatDuration(line.duration)),
    );
  }

  static String _interval(TimeEntry entry) {
    final start = entry.startedAt;
    final end = entry.endedAt;
    final from = '${formatDate(start)}, ${formatTime(start)}';
    if (end == null) return '$from — идёт сейчас';

    final sameDay = start.year == end.year &&
        start.month == end.month &&
        start.day == end.day;
    final to = sameDay
        ? formatTime(end)
        : '${formatDate(end)}, ${formatTime(end)}';
    return '$from — $to';
  }
}
