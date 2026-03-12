import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:zenoh_counter_flutter/app.dart';
import 'package:zenoh_counter_flutter/providers/providers.dart';

/// Application entry point.
///
/// Initializes [SharedPreferences] and launches the app
/// inside a [ProviderScope] with the required overrides.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const App(),
    ),
  );
}
