import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:zenoh/zenoh.dart';
import 'package:zenoh_counter_flutter/data/models/connection_config.dart';
import 'package:zenoh_counter_flutter/data/repositories/counter_repository.dart';
import 'package:zenoh_counter_flutter/data/repositories/counter_repository_impl.dart';
import 'package:zenoh_counter_flutter/data/services/zenoh_service.dart';

void main() {
  group('CounterRepository', () {
    test('isConnected delegates to ZenohService', () {
      final service = ZenohService();
      final repo = CounterRepositoryImpl(service);

      expect(repo.isConnected, isFalse);

      repo.dispose();
    });

    group('integration', () {
      late ZenohService service;
      late CounterRepositoryImpl repo;

      setUp(() {
        service = ZenohService();
        repo = CounterRepositoryImpl(service);
      });

      tearDown(() {
        repo.dispose();
      });

      test(
        'counterStream emits CounterValue from decoded '
        'payloads',
        () async {
          repo.connect(
            const ConnectionConfig(
              listenEndpoint: 'tcp/127.0.0.1:19547',
              keyExpr: 'test/counter_repo',
            ),
          );

          final pubConfig = Config()
            ..insertJson5(
              'connect/endpoints',
              '["tcp/127.0.0.1:19547"]',
            );
          final pubSession = Session.open(
            config: pubConfig,
          );

          await Future<void>.delayed(
            const Duration(seconds: 1),
          );

          final byteData = ByteData(8)
            ..setInt64(0, 42, Endian.little);
          final payload = byteData.buffer.asUint8List();
          final zbytes = ZBytes.fromUint8List(
            Uint8List.fromList(payload),
          );
          pubSession.putBytes(
            'test/counter_repo',
            zbytes,
          );

          final result = await repo.counterStream.first
              .timeout(const Duration(seconds: 5));

          expect(result.value, equals(42));
          expect(
            result.timestamp.difference(DateTime.now()).abs(),
            lessThan(const Duration(seconds: 2)),
          );

          pubSession.close();
        },
        timeout: const Timeout(Duration(seconds: 30)),
      );

      test(
        'disconnect stops subscription and disposes service',
        () {
          repo.connect(
            const ConnectionConfig(
              listenEndpoint: 'tcp/127.0.0.1:19548',
              keyExpr: 'test/counter_repo_disc',
            ),
          );
          expect(repo.isConnected, isTrue);

          repo.disconnect();
          expect(repo.isConnected, isFalse);
        },
        timeout: const Timeout(Duration(seconds: 30)),
      );

      test(
        'counterStream ignores payloads with wrong size',
        () async {
          repo.connect(
            const ConnectionConfig(
              listenEndpoint: 'tcp/127.0.0.1:19549',
              keyExpr: 'test/counter_repo_size',
            ),
          );

          final pubConfig = Config()
            ..insertJson5(
              'connect/endpoints',
              '["tcp/127.0.0.1:19549"]',
            );
          final pubSession = Session.open(
            config: pubConfig,
          );

          await Future<void>.delayed(
            const Duration(seconds: 1),
          );

          // Send wrong-size payload (4 bytes).
          final wrongData = ByteData(4)
            ..setInt32(0, 1, Endian.little);
          final wrongPayload =
              wrongData.buffer.asUint8List();
          pubSession.putBytes(
            'test/counter_repo_size',
            ZBytes.fromUint8List(
              Uint8List.fromList(wrongPayload),
            ),
          );

          // Small delay so wrong payload arrives first.
          await Future<void>.delayed(
            const Duration(milliseconds: 200),
          );

          // Send valid 8-byte payload.
          final validData = ByteData(8)
            ..setInt64(0, 99, Endian.little);
          final validPayload =
              validData.buffer.asUint8List();
          pubSession.putBytes(
            'test/counter_repo_size',
            ZBytes.fromUint8List(
              Uint8List.fromList(validPayload),
            ),
          );

          final result = await repo.counterStream.first
              .timeout(const Duration(seconds: 5));

          expect(result.value, equals(99));

          pubSession.close();
        },
        timeout: const Timeout(Duration(seconds: 30)),
      );
    });
  });
}
