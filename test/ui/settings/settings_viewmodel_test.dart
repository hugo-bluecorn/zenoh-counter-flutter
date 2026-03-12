import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:zenoh_counter_flutter/data/models/connection_config.dart';
import 'package:zenoh_counter_flutter/providers/providers.dart';

import '../../helpers/fakes.dart';
import '../../helpers/test_data.dart';

void main() {
  group('SettingsViewModel', () {
    late FakeSettingsRepository fakeRepo;
    late ProviderContainer container;

    setUp(() {
      fakeRepo = FakeSettingsRepository();
      container = ProviderContainer(
        overrides: [
          settingsRepositoryProvider.overrideWithValue(
            fakeRepo,
          ),
        ],
      );
    });

    tearDown(() => container.dispose());

    test('loads config on build', () async {
      // Arrange: seed the fake repo with a known config.
      await fakeRepo.save(testConfig);

      // Act: read the async provider and await build.
      final config = await container.read(
        settingsViewModelProvider.future,
      );

      // Assert: state matches the seeded config.
      expect(config.connectEndpoint, 'tcp/localhost:7447');
      expect(config.listenEndpoint, '');
      expect(config.keyExpr, 'demo/counter');
    });

    test('save persists and updates state', () async {
      // Arrange: wait for initial build.
      await container.read(
        settingsViewModelProvider.future,
      );

      // Act: save a new config.
      const newConfig = ConnectionConfig(
        connectEndpoint: 'tcp/192.168.1.1:7447',
        listenEndpoint: 'tcp/0.0.0.0:7448',
        keyExpr: 'test/key',
      );
      await container.read(settingsViewModelProvider.notifier).save(newConfig);

      // Assert: state is updated.
      final state = container.read(settingsViewModelProvider);
      expect(state.value?.connectEndpoint, newConfig.connectEndpoint);
      expect(state.value?.listenEndpoint, newConfig.listenEndpoint);
      expect(state.value?.keyExpr, newConfig.keyExpr);

      // Assert: repo received the save call.
      final saved = await fakeRepo.load();
      expect(saved.connectEndpoint, newConfig.connectEndpoint);
    });
  });
}
