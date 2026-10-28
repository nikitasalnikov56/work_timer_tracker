import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../presentation/report/report_cubit.dart';
import '../presentation/report/report_page.dart';
import '../presentation/tracker/add_employee_dialog.dart';
import '../presentation/tracker/tracker_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const _trackerTab = 0;
  static const _reportTab = 1;

  int _tab = _trackerTab;

  void _selectTab(int tab) {
    setState(() => _tab = tab);
    // Пока пользователь был на трекере, данные могли измениться.
    if (tab == _reportTab) context.read<ReportCubit>().load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _tab == _trackerTab ? 'Учёт рабочего времени' : 'Отчёт по времени',
        ),
      ),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            // Состояние экранов хранится в Cubit'ах, поэтому неактивную
            // вкладку можно не держать в дереве (в отличие от IndexedStack).
            child: _tab == _trackerTab
                ? const TrackerPage()
                : const ReportPage(),
          ),
        ),
      ),
      floatingActionButton: _tab == _trackerTab
          ? FloatingActionButton.extended(
              onPressed: () => AddEmployeeDialog.show(context),
              icon: const Icon(Icons.person_add_alt_1),
              label: const Text('Сотрудник'),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: _selectTab,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.timer_outlined),
            selectedIcon: Icon(Icons.timer),
            label: 'Трекер',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: 'Отчёт',
          ),
        ],
      ),
    );
  }
}
