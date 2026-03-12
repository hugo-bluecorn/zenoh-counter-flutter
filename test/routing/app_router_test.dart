import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zenoh_counter_flutter/data/models/connection_config.dart';
import 'package:zenoh_counter_flutter/providers/providers.dart';
import 'package:zenoh_counter_flutter/routing/app_router.dart';
import 'package:zenoh_counter_flutter/ui/connection/connection_screen.dart';
import 'package:zenoh_counter_flutter/ui/counter/counter_screen.dart';
import 'package:zenoh_counter_flutter/ui/settings/settings_screen.dart';

import '../helpers/fakes.dart';

/// Builds a test app using [routerProvider] with all
/// required provider overrides.
Widget _buildTestApp({
  String? initialLocation,
}) {
  return ProviderScope(
    overrides: [
      connectionViewModelProvider.overrideWith(
        FakeConnectionViewModel.new,
      ),
      counterRepositoryProvider.overrideWith(
        (ref) => FakeCounterRepository(),
      ),
      counterViewModelProvider.overrideWith(
        FakeCounterViewModel.new,
      ),
      settingsViewModelProvider.overrideWith(
        () => FakeSettingsViewModel(
          const AsyncData(ConnectionConfig()),
        ),
      ),
    ],
    child: _RouterApp(
      initialLocation: initialLocation,
    ),
  );
}

/// A consumer widget that reads [routerProvider] to build
/// a [MaterialApp.router].
class _RouterApp extends ConsumerWidget {
  const _RouterApp({this.initialLocation});

  final String? initialLocation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    if (initialLocation != null) {
      router.go(initialLocation!);
    }
    return MaterialApp.router(routerConfig: router);
  }
}

void main() {
  group('AppRouter', () {
    testWidgets(
      'initial location is /connect',
      (tester) async {
        await tester.pumpWidget(_buildTestApp());
        await tester.pumpAndSettle();

        expect(
          find.byType(ConnectionScreen),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      '/connect route builds ConnectionScreen',
      (tester) async {
        await tester.pumpWidget(
          _buildTestApp(initialLocation: '/connect'),
        );
        await tester.pumpAndSettle();

        expect(
          find.byType(ConnectionScreen),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      '/counter route builds CounterScreen',
      (tester) async {
        await tester.pumpWidget(
          _buildTestApp(initialLocation: '/counter'),
        );
        await tester.pumpAndSettle();

        expect(
          find.byType(CounterScreen),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      '/settings route builds SettingsScreen',
      (tester) async {
        await tester.pumpWidget(
          _buildTestApp(initialLocation: '/settings'),
        );
        await tester.pumpAndSettle();

        expect(
          find.byType(SettingsScreen),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'unknown route does not crash',
      (tester) async {
        await tester.pumpWidget(
          _buildTestApp(initialLocation: '/unknown'),
        );
        await tester.pumpAndSettle();

        // App should not crash -- it may redirect or
        // show an error page. We just verify the widget
        // tree is not empty.
        expect(
          find.byType(MaterialApp),
          findsOneWidget,
        );
      },
    );
  });
}
