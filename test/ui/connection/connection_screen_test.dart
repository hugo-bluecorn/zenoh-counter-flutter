import 'package:flutter/material.dart' hide ConnectionState;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:zenoh_counter_flutter/providers/providers.dart';
import 'package:zenoh_counter_flutter/ui/connection/connection_screen.dart';
import 'package:zenoh_counter_flutter/ui/connection/connection_viewmodel.dart';

import '../../helpers/fakes.dart';

GoRouter _testRouter() {
  return GoRouter(
    initialLocation: '/connect',
    routes: [
      GoRoute(
        path: '/connect',
        builder: (context, state) =>
            const ConnectionScreen(),
      ),
      GoRoute(
        path: '/counter',
        builder: (context, state) => const Scaffold(
          body: Center(child: Text('Counter Screen')),
        ),
      ),
    ],
  );
}

/// Builds a test app with [ConnectionScreen] and
/// required provider overrides.
Widget _buildTestApp({
  ConnectionState initialState = const ConnectionState(),
  GoRouter? router,
}) {
  return ProviderScope(
    overrides: [
      connectionViewModelProvider.overrideWith(
        () => FakeConnectionViewModel(initialState),
      ),
      counterRepositoryProvider.overrideWith(
        (ref) => FakeCounterRepository(),
      ),
    ],
    child: MaterialApp.router(
      routerConfig: router ?? _testRouter(),
    ),
  );
}

void main() {
  group('ConnectionScreen', () {
    testWidgets(
      'displays endpoint text fields and connect button',
      (tester) async {
        await tester.pumpWidget(_buildTestApp());
        await tester.pumpAndSettle();

        expect(
          find.widgetWithText(
            TextField,
            'Connect endpoint',
          ),
          findsOneWidget,
        );
        expect(
          find.widgetWithText(
            TextField,
            'Listen endpoint',
          ),
          findsOneWidget,
        );
        expect(
          find.widgetWithText(
            TextField,
            'Key expression',
          ),
          findsOneWidget,
        );
        expect(
          find.widgetWithText(ElevatedButton, 'Connect'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'displays error message when in error state',
      (tester) async {
        await tester.pumpWidget(
          _buildTestApp(
            initialState: const ConnectionState(
              status: ConnectionStatus.error,
              error: 'Connection refused',
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.text('Connection refused'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'connect button triggers connect on viewmodel',
      (tester) async {
        await tester.pumpWidget(_buildTestApp());
        await tester.pumpAndSettle();

        await tester.enterText(
          find.widgetWithText(
            TextField,
            'Connect endpoint',
          ),
          'tcp/localhost:7447',
        );

        await tester.tap(
          find.widgetWithText(ElevatedButton, 'Connect'),
        );
        await tester.pumpAndSettle();

        // After connect succeeds, navigation to /counter
        // occurs. Verify by finding the counter screen.
        expect(
          find.text('Counter Screen'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'navigates to /counter on successful connection',
      (tester) async {
        await tester.pumpWidget(_buildTestApp());
        await tester.pumpAndSettle();

        await tester.enterText(
          find.widgetWithText(
            TextField,
            'Connect endpoint',
          ),
          'tcp/localhost:7447',
        );

        await tester.tap(
          find.widgetWithText(ElevatedButton, 'Connect'),
        );
        await tester.pumpAndSettle();

        expect(
          find.text('Counter Screen'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'connect button is disabled during connecting state',
      (tester) async {
        await tester.pumpWidget(
          _buildTestApp(
            initialState: const ConnectionState(
              status: ConnectionStatus.connecting,
            ),
          ),
        );
        await tester.pumpAndSettle();

        final button = tester.widget<ElevatedButton>(
          find.widgetWithText(ElevatedButton, 'Connect'),
        );
        expect(button.onPressed, isNull);
      },
    );

    testWidgets(
      'key expression defaults to demo/counter',
      (tester) async {
        await tester.pumpWidget(_buildTestApp());
        await tester.pumpAndSettle();

        final textField = tester.widget<TextField>(
          find.widgetWithText(
            TextField,
            'Key expression',
          ),
        );
        expect(
          textField.controller?.text,
          'demo/counter',
        );
      },
    );
  });
}
