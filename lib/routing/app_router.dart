import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:zenoh_counter_flutter/ui/connection/connection_screen.dart';
import 'package:zenoh_counter_flutter/ui/counter/counter_screen.dart';
import 'package:zenoh_counter_flutter/ui/settings/settings_screen.dart';

/// Provides the app-wide [GoRouter] instance.
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/connect',
    routes: [
      GoRoute(
        path: '/connect',
        builder: (context, state) => const ConnectionScreen(),
      ),
      GoRoute(
        path: '/counter',
        builder: (context, state) => const CounterScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
    ],
  );
});
