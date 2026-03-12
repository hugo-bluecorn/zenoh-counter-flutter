import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zenoh_counter_flutter/data/models/connection_config.dart';
import 'package:zenoh_counter_flutter/data/repositories/counter_repository.dart';
import 'package:zenoh_counter_flutter/providers/providers.dart';
import 'package:zenoh_counter_flutter/ui/connection/connection_viewmodel.dart';

import '../../helpers/fakes.dart';
import '../../helpers/test_data.dart';

/// Fake that throws on [connect] to simulate connection failure.
class ThrowingFakeCounterRepository extends FakeCounterRepository {
  @override
  void connect(ConnectionConfig config) {
    throw Exception('Connection failed');
  }
}

void main() {
  group('ConnectionViewModel', () {
    late FakeCounterRepository fakeRepo;
    late ProviderContainer container;

    setUp(() {
      fakeRepo = FakeCounterRepository();
      container = ProviderContainer(
        overrides: [
          counterRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );
    });

    tearDown(() => container.dispose());

    test('initial state is disconnected', () {
      final state = container.read(
        connectionViewModelProvider,
      );

      expect(state.status, ConnectionStatus.disconnected);
      expect(state.error, isNull);
    });

    test('connect transitions to connected on success', () {
      final vm = container.read(
        connectionViewModelProvider.notifier,
      );

      vm.connect(testConfig);

      final state = container.read(
        connectionViewModelProvider,
      );
      expect(state.status, ConnectionStatus.connected);
    });

    test('connect transitions to error on failure', () {
      final throwingContainer = ProviderContainer(
        overrides: [
          counterRepositoryProvider.overrideWithValue(
            ThrowingFakeCounterRepository(),
          ),
        ],
      );
      addTearDown(throwingContainer.dispose);

      final vm = throwingContainer.read(
        connectionViewModelProvider.notifier,
      );

      vm.connect(testConfig);

      final state = throwingContainer.read(
        connectionViewModelProvider,
      );
      expect(state.status, ConnectionStatus.error);
      expect(state.error, contains('Connection failed'));
    });

    test('disconnect resets to disconnected state', () {
      final vm = container.read(
        connectionViewModelProvider.notifier,
      );

      vm.connect(testConfig);
      vm.disconnect();

      final state = container.read(
        connectionViewModelProvider,
      );
      expect(state.status, ConnectionStatus.disconnected);
      expect(state.error, isNull);
    });

    test(
      'connect sets connecting status before completion',
      () {
        final states = <ConnectionStatus>[];
        container.listen(
          connectionViewModelProvider,
          (prev, next) => states.add(next.status),
        );

        final vm = container.read(
          connectionViewModelProvider.notifier,
        );

        vm.connect(testConfig);

        expect(states, contains(ConnectionStatus.connecting));
      },
    );
  });
}
