import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zenoh_counter_flutter/app.dart';
import 'package:zenoh_counter_flutter/providers/providers.dart';
import 'package:zenoh_counter_flutter/routing/app_router.dart';

import 'helpers/fakes.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<void> pumpApp(WidgetTester tester) async {
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          counterRepositoryProvider.overrideWithValue(
            FakeCounterRepository(),
          ),
          settingsRepositoryProvider.overrideWithValue(
            FakeSettingsRepository(),
          ),
        ],
        child: const App(),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('App', () {
    testWidgets(
      'renders with ProviderScope and MaterialApp.router',
      (tester) async {
        await pumpApp(tester);

        expect(
          find.byType(MaterialApp),
          findsOneWidget,
        );
      },
    );

    testWidgets('uses Material 3 theme', (tester) async {
      await pumpApp(tester);

      final materialApp = tester.widget<MaterialApp>(
        find.byType(MaterialApp),
      );
      expect(materialApp.theme?.useMaterial3, isTrue);
    });

    testWidgets(
      'shows initial route content',
      (tester) async {
        await pumpApp(tester);

        expect(find.text('Connection'), findsOneWidget);
      },
    );
  });
}
