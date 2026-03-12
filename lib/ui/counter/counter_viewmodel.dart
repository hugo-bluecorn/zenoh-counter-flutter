import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:zenoh_counter_flutter/data/models/counter_value.dart';
import 'package:zenoh_counter_flutter/providers/providers.dart';

/// Immutable state for the counter screen.
class CounterState {
  /// Creates a [CounterState].
  const CounterState({
    this.value,
    this.lastUpdate,
    this.isSubscribed = false,
  });

  /// The current counter value, or null if not yet received.
  final int? value;

  /// When the last value was received.
  final DateTime? lastUpdate;

  /// Whether the viewmodel is listening to the stream.
  final bool isSubscribed;

  /// Returns a copy with the given fields replaced.
  CounterState copyWith({
    int? value,
    DateTime? lastUpdate,
    bool? isSubscribed,
  }) {
    return CounterState(
      value: value ?? this.value,
      lastUpdate: lastUpdate ?? this.lastUpdate,
      isSubscribed: isSubscribed ?? this.isSubscribed,
    );
  }
}

/// Manages counter subscription and state updates.
class CounterViewModel extends Notifier<CounterState> {
  StreamSubscription<CounterValue>? _subscription;

  @override
  CounterState build() {
    ref.onDispose(() => _subscription?.cancel());
    return const CounterState();
  }

  /// Starts listening to the counter stream.
  void startListening() {
    unawaited(_subscription?.cancel());
    _subscription = ref
        .read(counterRepositoryProvider)
        .counterStream
        .listen(_onCounterValue);
    state = state.copyWith(isSubscribed: true);
  }

  /// Stops listening and resets state.
  void stopListening() {
    unawaited(_subscription?.cancel());
    _subscription = null;
    state = const CounterState();
  }

  void _onCounterValue(CounterValue counterValue) {
    state = state.copyWith(
      value: counterValue.value,
      lastUpdate: counterValue.timestamp,
    );
  }
}
