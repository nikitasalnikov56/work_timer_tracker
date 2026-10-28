import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/employee.dart';
import '../../domain/entities/time_entry.dart';
import '../../domain/services/time_tracking_service.dart';
import '../common/elapsed_time_text.dart';
import '../common/formatters.dart';
import 'tracker_cubit.dart';

/// Карточка сотрудника: поле задачи и «Старт» либо идущий таймер и «Стоп».
class EmployeeTimerCard extends StatefulWidget {
  const EmployeeTimerCard({
    super.key,
    required this.employee,
    required this.runningEntry,
    required this.isBusy,
  });

  final Employee employee;
  final TimeEntry? runningEntry;
  final bool isBusy;

  @override
  State<EmployeeTimerCard> createState() => _EmployeeTimerCardState();
}

class _EmployeeTimerCardState extends State<EmployeeTimerCard> {
  final _taskController = TextEditingController();

  @override
  void dispose() {
    _taskController.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    final cubit = context.read<TrackerCubit>();
    final employeeId = widget.employee.id;
    await cubit.startTimer(employeeId, _taskController.text);
    // Поле очищается только при успешном запуске, чтобы при ошибке
    // валидации пользователь не терял набранный текст.
    if (mounted && cubit.state.runningEntries.containsKey(employeeId)) {
      _taskController.clear();
    }
  }

  Future<void> _stop() {
    return context.read<TrackerCubit>().stopTimer(widget.employee.id);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final entry = widget.runningEntry;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                CircleAvatar(child: Text(_initials(widget.employee.name))),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.employee.name,
                    style: theme.textTheme.titleMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (entry != null)
                  ElapsedTimeText(
                    entry: entry,
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (entry != null) _buildRunning(entry) else _buildIdle(),
          ],
        ),
      ),
    );
  }

  Widget _buildRunning(TimeEntry entry) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(Icons.timelapse, size: 20, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            '${entry.description} · с ${formatTime(entry.startedAt)}',
            style: theme.textTheme.bodyMedium,
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          ),
        ),
        const SizedBox(width: 12),
        FilledButton.tonalIcon(
          onPressed: widget.isBusy ? null : _stop,
          icon: const Icon(Icons.stop),
          label: const Text('Стоп'),
        ),
      ],
    );
  }

  Widget _buildIdle() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _taskController,
            enabled: !widget.isBusy,
            maxLength: TimeTrackingService.maxDescriptionLength,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(
              hintText: 'Над какой задачей работаете?',
              border: OutlineInputBorder(),
              isDense: true,
              counterText: '',
            ),
            onSubmitted: (_) => _start(),
          ),
        ),
        const SizedBox(width: 12),
        FilledButton.icon(
          onPressed: widget.isBusy ? null : _start,
          icon: const Icon(Icons.play_arrow),
          label: const Text('Старт'),
        ),
      ],
    );
  }

  static String _initials(String name) {
    final letters = name
        .split(' ')
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part.characters.first.toUpperCase());
    return letters.join();
  }
}
