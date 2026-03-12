import 'package:flutter_test/flutter_test.dart';
import 'package:zenoh_counter_flutter/data/models/connection_config.dart';

void main() {
  group('ConnectionConfig', () {
    test('has default values', () {
      const config = ConnectionConfig();

      expect(config.connectEndpoint, equals(''));
      expect(config.listenEndpoint, equals(''));
      expect(config.keyExpr, equals('demo/counter'));
    });

    test('copyWith overrides fields', () {
      const config = ConnectionConfig(
        connectEndpoint: 'tcp/localhost:7447',
      );

      final updated = config.copyWith(keyExpr: 'test/key');

      expect(
        updated.connectEndpoint,
        equals('tcp/localhost:7447'),
      );
      expect(updated.keyExpr, equals('test/key'));
    });

    test('copyWith with no arguments returns equivalent config', () {
      const config = ConnectionConfig(
        connectEndpoint: 'tcp/localhost:7447',
        listenEndpoint: 'tcp/0.0.0.0:7448',
        keyExpr: 'custom/key',
      );

      final copied = config.copyWith();

      expect(
        copied.connectEndpoint,
        equals(config.connectEndpoint),
      );
      expect(
        copied.listenEndpoint,
        equals(config.listenEndpoint),
      );
      expect(copied.keyExpr, equals(config.keyExpr));
    });
  });
}
