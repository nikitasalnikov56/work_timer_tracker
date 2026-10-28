import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../core/clock.dart';
import '../presentation/report/report_cubit.dart';
import '../presentation/tracker/tracker_cubit.dart';
import 'dependencies.dart';
import 'home_page.dart';

class WorkTimeTrackerApp extends StatelessWidget {
  const WorkTimeTrackerApp({super.key, required this.dependencies});

  final AppDependencies dependencies;

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider<Clock>.value(
      value: dependencies.clock,
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (_) => TrackerCubit(dependencies.timeTracking)..load(),
          ),
          BlocProvider(
            create: (_) => ReportCubit(
              service: dependencies.reports,
              clock: dependencies.clock,
            )..load(),
          ),
        ],
        child: MaterialApp(
          title: 'Учёт рабочего времени',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
          ),
          locale: const Locale('ru'),
          supportedLocales: const [Locale('ru'), Locale('en')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: const HomePage(),
        ),
      ),
    );
  }
}
