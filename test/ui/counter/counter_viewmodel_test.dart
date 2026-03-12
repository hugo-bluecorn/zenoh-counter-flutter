import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zenoh_counter_flutter/providers/providers.dart';

import '../../helpers/fakes.dart';
import '../../helpers/test_data.dart';

void main() {
  group('CounterViewModel', () {
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

    test('initial state has no value and is not subscribed', () {
      final state = container.read(counterViewModelProvider);
      expect(state.value, isNull);
      expect(state.lastUpdate, isNull);
      expect(state.isSubscribed, isFalse);
    });

    test('startListening sets isSubscribed to true', () {
      container.read(counterViewModelProvider.notifier).startListening();
      expect(
        container.read(counterViewModelProvider).isSubscribed,
        isTrue,
      );
    });

    test(
      'startListening updates state on stream emit',
      () async {
        container.read(counterViewModelProvider.notifier).startListening();
        fakeRepo.emit(testCounterValue);
        await Future<void>.delayed(Duration.zero);
        final state = container.read(counterViewModelProvider);
        expect(state.value, 42);
        expect(state.lastUpdate, testTimestamp);
      },
    );

    test('stopListening resets state', () async {
      final vm = container.read(counterViewModelProvider.notifier)
        ..startListening();
      fakeRepo.emit(testCounterValue);
      await Future<void>.delayed(Duration.zero);
      vm.stopListening();
      final state = container.read(counterViewModelProvider);
      expect(state.value, isNull);
      expect(state.isSubscribed, isFalse);
    });

    test(
      'startListening cancels previous subscription',
      () async {
        container.read(counterViewModelProvider.notifier)
          ..startListening()
          ..startListening();
        fakeRepo.emit(testCounterValue);
        await Future<void>.delayed(Duration.zero);
        expect(
          container.read(counterViewModelProvider).value,
          42,
        );
      },
    );
  });
}
