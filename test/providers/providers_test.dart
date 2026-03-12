import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zenoh_counter_flutter/data/repositories/counter_repository.dart';
import 'package:zenoh_counter_flutter/data/repositories/counter_repository_impl.dart';
import 'package:zenoh_counter_flutter/data/repositories/settings_repository.dart';
import 'package:zenoh_counter_flutter/data/repositories/settings_repository_impl.dart';
import 'package:zenoh_counter_flutter/data/services/zenoh_service.dart';
import 'package:zenoh_counter_flutter/providers/providers.dart';

// ignore: depend_on_referenced_packages
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('Providers', () {
    test(
      'zenohServiceProvider creates a ZenohService',
      () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final service = container.read(zenohServiceProvider);

        expect(service, isA<ZenohService>());
      },
    );

    test(
      'settingsRepositoryProvider resolves with '
      'SharedPreferences override',
      () {
        SharedPreferences.setMockInitialValues({});
        final prefs = SharedPreferences.getInstance();

        late final SharedPreferences resolvedPrefs;

        return prefs.then((p) {
          resolvedPrefs = p;

          final container = ProviderContainer(
            overrides: [
              sharedPreferencesProvider.overrideWithValue(
                resolvedPrefs,
              ),
            ],
          );
          addTearDown(container.dispose);

          final repo = container.read(
            settingsRepositoryProvider,
          );

          expect(repo, isA<SettingsRepository>());
          expect(repo, isA<SettingsRepositoryImpl>());
        });
      },
    );

    test(
      'counterRepositoryProvider resolves with zenohService',
      () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final repo = container.read(counterRepositoryProvider);

        expect(repo, isA<CounterRepository>());
        expect(repo, isA<CounterRepositoryImpl>());
      },
    );

    test(
      'sharedPreferencesProvider throws without override',
      () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        expect(
          () => container.read(sharedPreferencesProvider),
          throwsA(isA<UnimplementedError>()),
        );
      },
    );

    test(
      'provider disposal triggers cleanup',
      skip: 'Requires zenoh native libraries',
      () {
        final container = ProviderContainer();

        final service = container.read(zenohServiceProvider);
        service.connect(
          listenEndpoints: ['tcp/127.0.0.1:0'],
        );
        expect(service.isConnected, isTrue);

        container.dispose();

        expect(service.isConnected, isFalse);
      },
    );
  });
}
