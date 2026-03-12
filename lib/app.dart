import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:zenoh_counter_flutter/routing/app_router.dart';
import 'package:zenoh_counter_flutter/ui/core/themes/app_theme.dart';

/// Root application widget.
class App extends ConsumerWidget {
  /// Creates the root [App] widget.
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'Zenoh Counter',
      theme: AppTheme.light,
      routerConfig: router,
    );
  }
}
