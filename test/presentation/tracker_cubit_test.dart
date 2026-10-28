import 'package:flutter_test/flutter_test.dart';
import 'package:work_time_tracker/presentation/tracker/tracker_cubit.dart';
import 'package:work_time_tracker/presentation/tracker/tracker_state.dart';

import '../helpers/test_environment.dart';

void main() {
  late TestEnvironment env;
  late TrackerCubit cubit;

  setUp(() {
    env = TestEnvironment();
    cubit = TrackerCubit(env.tracking);
  });

  tearDown(() => cubit.close());

  test('загрузка пустого хранилища → готово, сотрудников нет', () async {
    await cubit.load();

    expect(cubit.state.status, TrackerStatus.ready);
    expect(cubit.state.employees, isEmpty);
  });

  test('ошибка валидации возвращается в диалог текстом', () async {
    final error = await cubit.addEmployee('  ');

    expect(error, isNotNull);
    expect(cubit.state.employees, isEmpty);
  });

  test('повторный запуск таймера показывает ошибку, запись остаётся одна',
      () async {
    await cubit.addEmployee('Анна');
    final annaId = cubit.state.employees.single.id;

    await cubit.startTimer(annaId, 'Задача 1');
    expect(cubit.state.runningEntries.keys, [annaId]);
    expect(cubit.state.message, isNull);

    await cubit.startTimer(annaId, 'Задача 2');

    expect(cubit.state.message?.isError, isTrue);
    expect(cubit.state.message?.text, contains('уже запущен'));
    expect(cubit.state.runningEntries[annaId]?.description, 'Задача 1');
    expect(await env.entryRepository.getAll(), hasLength(1));
    expect(cubit.state.busyEmployeeIds, isEmpty);
  });

  test('старт и стоп меняют состояние таймера', () async {
    await cubit.addEmployee('Анна');
    final annaId = cubit.state.employees.single.id;

    await cubit.startTimer(annaId, 'Задача');
    env.clock.advance(const Duration(minutes: 5));
    await cubit.stopTimer(annaId);

    expect(cubit.state.runningEntries, isEmpty);
    final entry = (await env.entryRepository.getAll()).single;
    expect(entry.durationAt(env.clock.now()), const Duration(minutes: 5));
  });
}
