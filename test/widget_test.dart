// Сквозные сценарии через UI. Файл назван widget_test.dart намеренно:
// `flutter create .` не перезапишет его шаблонным тестом счётчика.
//
// Пока таймер идёт, на экране тикает Timer.periodic, поэтому после старта
// используется tester.pump(), а не pumpAndSettle(): последний ждал бы
// окончания анимаций бесконечно и падал по таймауту.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:work_time_tracker/app/app.dart';
import 'package:work_time_tracker/presentation/report/report_page.dart';
import 'package:work_time_tracker/presentation/tracker/add_employee_dialog.dart';

import 'helpers/test_environment.dart';

void main() {
  Future<TestEnvironment> openApp(WidgetTester tester) async {
    final env = TestEnvironment(now: DateTime(2026, 10, 27, 10));
    await tester.pumpWidget(WorkTimeTrackerApp(dependencies: env.dependencies));
    await tester.pump();
    return env;
  }

  Future<void> addEmployee(WidgetTester tester, String name) async {
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(AddEmployeeDialog.nameFieldKey), name);
    await tester.tap(find.text('Добавить'));
    await tester.pumpAndSettle();
  }

  testWidgets('сотрудник → таймер → стоп → запись в отчёте', (tester) async {
    final env = await openApp(tester);
    expect(find.text('Добавьте первого сотрудника'), findsOneWidget);

    await addEmployee(tester, 'Анна Смирнова');
    expect(find.text('Анна Смирнова'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Вёрстка отчёта');
    await tester.tap(find.text('Старт'));
    await tester.pump();
    expect(find.text('Стоп'), findsOneWidget);
    expect(find.text('0:00:00'), findsOneWidget);

    env.clock.advance(const Duration(minutes: 90));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('1:30:00'), findsOneWidget);

    await tester.tap(find.text('Стоп'));
    await tester.pump();
    expect(find.text('Старт'), findsOneWidget);

    await tester.tap(find.text('Отчёт'));
    await tester.pump();
    expect(find.text('Вёрстка отчёта'), findsOneWidget);
    expect(find.text('1:30:00'), findsWidgets);
  });

  testWidgets('пустой отчёт показывает понятное сообщение', (tester) async {
    await openApp(tester);

    await tester.tap(find.text('Отчёт'));
    await tester.pump();

    expect(find.text(ReportPage.emptyText), findsOneWidget);
  });

  testWidgets('дубликат сотрудника — ошибка в диалоге', (tester) async {
    await openApp(tester);
    await addEmployee(tester, 'Анна');

    await addEmployee(tester, 'анна');

    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.textContaining('уже есть'), findsOneWidget);
  });
}
