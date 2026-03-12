// ignore: always_use_package_imports
import 'package:flutter/material.dart' hide ConnectionState;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:zenoh_counter_flutter/providers/providers.dart';
import 'package:zenoh_counter_flutter/ui/connection/connection_screen.dart';
import 'package:zenoh_counter_flutter/ui/connection/connection_viewmodel.dart';

import '../../helpers/fakes.dart';

/// Pumps a [ConnectionScreen] wrapped in required providers.
///
/// Uses [MaterialApp] for basic widget tests, or [GoRouter]
/// when navigation verification is needed.
Widget _buildTestApp({
  ConnectionState initialState = const ConnectionState(),
  GoRouter? router,
}) {
  final fakeVm = FakeConnectionViewModel(initialState);
  final overrides = [
    connectionViewModelProvider.overrideWith(() => fakeVm),
    counterRepositoryProvider.overrideWith(
      (ref) => FakeCounterRepository(),
    ),
  ];

  if (router != null) {
    return ProviderScope(
      overrides: overrides,
      child: MaterialApp.router(
        routerConfig: router,
      ),
    );
  }

  return ProviderScope(
    overrides: overrides,
    child: const MaterialApp(
      home: ConnectionScreen(),
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
          find.widgetWithText(TextField, 'Connect endpoint'),
          findsOneWidget,
        );
        expect(
          find.widgetWithText(TextField, 'Listen endpoint'),
          findsOneWidget,
        );
        expect(
          find.widgetWithText(TextField, 'Key expression'),
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

        expect(find.text('Connection refused'), findsOneWidget);
      },
    );

    testWidgets(
      'connect button triggers connect on viewmodel',
      (tester) async {
        await tester.pumpWidget(_buildTestApp());
        await tester.pumpAndSettle();

        // Enter a connect endpoint.
        await tester.enterText(
          find.widgetWithText(TextField, 'Connect endpoint'),
          'tcp/localhost:7447',
        );

        await tester.tap(
          find.widgetWithText(ElevatedButton, 'Connect'),
        );
        await tester.pumpAndSettle();

        // The FakeConnectionViewModel delegates to the real
        // connect(), which transitions through connecting ->
        // connected (since FakeCounterRepository.connect
        // succeeds). Verify the state reached connected.
        final container = ProviderScope.containerOf(
          tester.element(find.byType(ConnectionScreen)),
        );
        final state = container.read(connectionViewModelProvider);
        expect(
          state.status,
          ConnectionStatus.connected,
        );
      },
    );

    testWidgets(
      'navigates to /counter on successful connection',
      (tester) async {
        final router = GoRouter(
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

        await tester.pumpWidget(
          _buildTestApp(router: router),
        );
        await tester.pumpAndSettle();

        await tester.enterText(
          find.widgetWithText(TextField, 'Connect endpoint'),
          'tcp/localhost:7447',
        );

        await tester.tap(
          find.widgetWithText(ElevatedButton, 'Connect'),
        );
        await tester.pumpAndSettle();

        // Verify we navigated to the counter screen.
        expect(find.text('Counter Screen'), findsOneWidget);
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
          find.widgetWithText(TextField, 'Key expression'),
        );
        expect(textField.controller?.text, 'demo/counter');
      },
    );
  });
}
