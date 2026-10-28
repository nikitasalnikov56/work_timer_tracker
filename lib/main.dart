import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'app/dependencies.dart';
import 'data/local/shared_preferences_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final preferences = await SharedPreferences.getInstance();

  runApp(
    WorkTimeTrackerApp(
      dependencies: AppDependencies.local(
        store: SharedPreferencesStore(preferences),
      ),
    ),
  );
}
