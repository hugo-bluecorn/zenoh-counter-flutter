import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:zenoh/zenoh.dart';
import 'package:zenoh_counter_flutter/data/services/zenoh_service.dart';

void main() {
  group('ZenohService', () {
    test('is not connected initially', () {
      final service = ZenohService();
      expect(service.isConnected, isFalse);
    });

    group('integration', () {
      late ZenohService service;

      setUp(() {
        service = ZenohService();
      });

      tearDown(() {
        service.dispose();
      });

      test('connects and becomes connected', () {
        service.connect(
          listenEndpoints: ['tcp/127.0.0.1:19447'],
        );
        expect(service.isConnected, isTrue);
      });

      test(
        'subscribe delivers data from a publisher',
        () async {
          service.connect(
            listenEndpoints: ['tcp/127.0.0.1:19447'],
          );

          final stream = service.subscribe(
            'test/zenoh_service',
          );

          final pubConfig = Config();
          pubConfig.insertJson5(
            'connect/endpoints',
            '["tcp/127.0.0.1:19447"]',
          );
          final pubSession = Session.open(
            config: pubConfig,
          );

          // Wait for TCP link establishment.
          await Future<void>.delayed(
            const Duration(seconds: 1),
          );

          final byteData = ByteData(8);
          byteData.setInt64(0, 42, Endian.little);
          final payload = byteData.buffer.asUint8List();

          final zbytes = ZBytes.fromUint8List(
            Uint8List.fromList(payload),
          );
          pubSession.putBytes(
            'test/zenoh_service',
            zbytes,
          );

          final received = await stream.first.timeout(
            const Duration(seconds: 5),
          );

          expect(received, equals(payload));

          pubSession.close();
        },
        timeout: const Timeout(Duration(seconds: 30)),
      );

      test('dispose cleans up session', () {
        service.connect(
          listenEndpoints: ['tcp/127.0.0.1:19447'],
        );
        expect(service.isConnected, isTrue);

        service.dispose();
        expect(service.isConnected, isFalse);
      });

      test('connect is idempotent', () {
        service.connect(
          listenEndpoints: ['tcp/127.0.0.1:19447'],
        );
        expect(service.isConnected, isTrue);

        // Second call should not throw.
        service.connect(
          listenEndpoints: ['tcp/127.0.0.1:19447'],
        );
        expect(service.isConnected, isTrue);
      });
    });

    test('subscribe throws when not connected', () {
      final service = ZenohService();
      expect(
        () => service.subscribe('test/key'),
        throwsStateError,
      );
    });
  });
}
