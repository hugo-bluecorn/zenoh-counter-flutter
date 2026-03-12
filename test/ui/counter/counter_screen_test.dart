import 'package:flutter/material.dart' hide ConnectionState;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:zenoh_counter_flutter/providers/providers.dart';
import 'package:zenoh_counter_flutter/ui/connection/connection_viewmodel.dart';
import 'package:zenoh_counter_flutter/ui/counter/counter_screen.dart';
import 'package:zenoh_counter_flutter/ui/counter/counter_viewmodel.dart';

import '../../helpers/fakes.dart';
import '../../helpers/test_data.dart';

GoRouter _testRouter() {
  return GoRouter(
    initialLocation: '/counter',
    routes: [
      GoRoute(
        path: '/counter',
        builder: (_, _) => const CounterScreen(),
      ),
      GoRoute(
        path: '/connect',
        builder: (_, _) => const Scaffold(
          body: Center(child: Text('connect-page')),
        ),
      ),
      GoRoute(
        path: '/settings',
        builder: (_, _) => const Scaffold(
          body: Center(child: Text('settings-page')),
        ),
      ),
    ],
  );
}

Widget _buildTestApp({
  CounterState counterState = const CounterState(),
  ConnectionState connectionState = const ConnectionState(
    status: ConnectionStatus.connected,
  ),
  GoRouter? router,
}) {
  return ProviderScope(
    overrides: [
      counterViewModelProvider.overrideWith(
        () => FakeCounterViewModel(counterState),
      ),
      connectionViewModelProvider.overrideWith(
        () => FakeConnectionViewModel(connectionState),
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
  group('CounterScreen', () {
    testWidgets(
      'displays counter value when state has a value',
      (tester) async {
        await tester.pumpWidget(
          _buildTestApp(
            counterState: const CounterState(
              value: 42,
              isSubscribed: true,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('42'), findsOneWidget);
      },
    );

    testWidgets(
      'displays waiting message when no value received',
      (tester) async {
        await tester.pumpWidget(
          _buildTestApp(
            counterState: const CounterState(
              isSubscribed: true,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.text('Waiting for data...'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'displays last update timestamp',
      (tester) async {
        await tester.pumpWidget(
          _buildTestApp(
            counterState: CounterState(
              value: 42,
              lastUpdate: testTimestamp,
              isSubscribed: true,
            ),
          ),
        );
        await tester.pumpAndSettle();

        // testTimestamp is 2026-03-12 10:30
        expect(
          find.textContaining('10:30'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'disconnect button navigates to /connect',
      (tester) async {
        await tester.pumpWidget(
          _buildTestApp(
            counterState: const CounterState(
              isSubscribed: true,
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Disconnect'));
        await tester.pumpAndSettle();

        expect(
          find.text('connect-page'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'settings icon navigates to /settings',
      (tester) async {
        await tester.pumpWidget(
          _buildTestApp(
            counterState: const CounterState(
              isSubscribed: true,
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.settings));
        await tester.pumpAndSettle();

        expect(
          find.text('settings-page'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'shows connection status indicator when connected',
      (tester) async {
        await tester.pumpWidget(
          _buildTestApp(
            counterState: const CounterState(
              isSubscribed: true,
            ),
            // Default connectionState already has connected
            // status, so no override needed here.
          ),
        );
        await tester.pumpAndSettle();

        // Green dot indicator for connected status
        final greenIcon = find.byWidgetPredicate(
          (widget) =>
              widget is Icon &&
              widget.icon == Icons.circle &&
              widget.color == Colors.green,
        );
        expect(greenIcon, findsOneWidget);
      },
    );
  });
}
