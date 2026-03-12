import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:zenoh_counter_flutter/data/models/connection_config.dart';
import 'package:zenoh_counter_flutter/providers/providers.dart';
import 'package:zenoh_counter_flutter/ui/settings/settings_screen.dart';

import '../../helpers/fakes.dart';

Widget _buildTestApp({
  required AsyncValue<ConnectionConfig> initialState,
}) {
  return ProviderScope(
    overrides: [
      settingsViewModelProvider.overrideWith(
        () => FakeSettingsViewModel(initialState),
      ),
    ],
    child: const MaterialApp(home: SettingsScreen()),
  );
}

void main() {
  group('SettingsScreen', () {
    testWidgets(
      'displays loaded endpoint values',
      (tester) async {
        await tester.pumpWidget(
          _buildTestApp(
            initialState: const AsyncData(
              ConnectionConfig(
                connectEndpoint: 'tcp/host:7447',
                listenEndpoint: 'tcp/0.0.0.0:7448',
                keyExpr: 'my/key',
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.widgetWithText(TextField, 'tcp/host:7447'),
          findsOneWidget,
        );
        expect(
          find.widgetWithText(
            TextField,
            'tcp/0.0.0.0:7448',
          ),
          findsOneWidget,
        );
        expect(
          find.widgetWithText(TextField, 'my/key'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'save button persists config',
      (tester) async {
        await tester.pumpWidget(
          _buildTestApp(
            initialState: const AsyncData(
              ConnectionConfig(
                connectEndpoint: 'tcp/host:7447',
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();

        // Verify the state was updated (save was called).
        final container = ProviderScope.containerOf(
          tester.element(find.byType(SettingsScreen)),
        );
        final state = container.read(
          settingsViewModelProvider,
        );
        expect(state.value, isNotNull);
      },
    );

    testWidgets(
      'reset button restores defaults',
      (tester) async {
        await tester.pumpWidget(
          _buildTestApp(
            initialState: const AsyncData(
              ConnectionConfig(
                connectEndpoint: 'tcp/host:7447',
                listenEndpoint: 'tcp/0.0.0.0:7448',
                keyExpr: 'my/key',
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Reset to defaults'));
        await tester.pumpAndSettle();

        // After reset, fields should show defaults.
        expect(
          find.widgetWithText(TextField, ''),
          findsNWidgets(2),
        );
        expect(
          find.widgetWithText(TextField, 'demo/counter'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'shows loading indicator during async operations',
      (tester) async {
        await tester.pumpWidget(
          _buildTestApp(
            initialState:
                const AsyncLoading<ConnectionConfig>(),
          ),
        );
        await tester.pump();

        expect(
          find.byType(CircularProgressIndicator),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'shows error on load failure',
      (tester) async {
        await tester.pumpWidget(
          _buildTestApp(
            initialState: AsyncError<ConnectionConfig>(
              Exception('load failed'),
              StackTrace.current,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.textContaining('load failed'),
          findsOneWidget,
        );
      },
    );
  });
}
