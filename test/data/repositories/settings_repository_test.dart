import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zenoh_counter_flutter/data/models/connection_config.dart';
import 'package:zenoh_counter_flutter/data/repositories/settings_repository.dart';
import 'package:zenoh_counter_flutter/data/repositories/settings_repository_impl.dart';

void main() {
  late SettingsRepository repository;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    repository = SettingsRepositoryImpl(prefs);
  });

  group('SettingsRepositoryImpl', () {
    test(
      'load returns default config when prefs are empty',
      () async {
        final config = await repository.load();

        expect(config.connectEndpoint, '');
        expect(config.listenEndpoint, '');
        expect(config.keyExpr, 'demo/counter');
      },
    );

    test(
      'save persists config and load retrieves it',
      () async {
        const config = ConnectionConfig(
          connectEndpoint: 'tcp/host:7447',
          keyExpr: 'test/key',
        );

        await repository.save(config);
        final loaded = await repository.load();

        expect(loaded.connectEndpoint, 'tcp/host:7447');
        expect(loaded.keyExpr, 'test/key');
      },
    );

    test(
      'save overwrites previous values',
      () async {
        await repository.save(
          const ConnectionConfig(connectEndpoint: 'old'),
        );
        await repository.save(
          const ConnectionConfig(connectEndpoint: 'new'),
        );

        final loaded = await repository.load();

        expect(loaded.connectEndpoint, 'new');
      },
    );

    test(
      'load returns default keyExpr when only endpoints '
      'are saved',
      () async {
        SharedPreferences.setMockInitialValues({
          'connect_endpoint': 'tcp/host:7447',
        });
        final prefs = await SharedPreferences.getInstance();
        final repo = SettingsRepositoryImpl(prefs);

        final config = await repo.load();

        expect(config.connectEndpoint, 'tcp/host:7447');
        expect(config.keyExpr, 'demo/counter');
      },
    );
  });
}
