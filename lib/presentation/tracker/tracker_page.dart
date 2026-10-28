import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../common/status_views.dart';
import 'add_employee_dialog.dart';
import 'employee_timer_card.dart';
import 'tracker_cubit.dart';
import 'tracker_state.dart';

class TrackerPage extends StatelessWidget {
  const TrackerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TrackerCubit, TrackerState>(
      listenWhen: (previous, current) =>
          current.message != null && previous.message != current.message,
      listener: _showMessage,
      builder: (context, state) => switch (state.status) {
        TrackerStatus.loading when state.employees.isEmpty =>
          const Center(child: CircularProgressIndicator()),
        TrackerStatus.failure => StatusView(
            icon: Icons.error_outline,
            title: 'Не удалось загрузить данные',
            description: state.failureText,
            action: FilledButton(
              onPressed: () => context.read<TrackerCubit>().load(),
              child: const Text('Повторить'),
            ),
          ),
        _ when state.employees.isEmpty => StatusView(
            icon: Icons.groups_outlined,
            title: 'Добавьте первого сотрудника',
            description: 'Потом для него можно запускать таймер по задачам.',
            action: FilledButton.tonalIcon(
              onPressed: () => AddEmployeeDialog.show(context),
              icon: const Icon(Icons.person_add_alt_1),
              label: const Text('Добавить сотрудника'),
            ),
          ),
        _ => _EmployeeList(state: state),
      },
    );
  }

  void _showMessage(BuildContext context, TrackerState state) {
    final message = state.message;
    if (message == null) return;

    final colors = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message.text,
            style: message.isError ? TextStyle(color: colors.onError) : null,
          ),
          backgroundColor: message.isError ? colors.error : null,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }
}

class _EmployeeList extends StatelessWidget {
  const _EmployeeList({required this.state});

  final TrackerState state;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      // Нижний отступ — чтобы FAB не перекрывал последнюю карточку.
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      itemCount: state.employees.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final employee = state.employees[index];
        return EmployeeTimerCard(
          key: ValueKey(employee.id),
          employee: employee,
          runningEntry: state.runningEntries[employee.id],
          isBusy: state.busyEmployeeIds.contains(employee.id),
        );
      },
    );
  }
}
