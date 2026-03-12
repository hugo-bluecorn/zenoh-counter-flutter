import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:zenoh_counter_flutter/data/models/connection_config.dart';
import 'package:zenoh_counter_flutter/data/models/counter_value.dart';
import 'package:zenoh_counter_flutter/data/repositories/counter_repository.dart';
import 'package:zenoh_counter_flutter/data/repositories/settings_repository.dart';
import 'package:zenoh_counter_flutter/ui/connection/connection_viewmodel.dart';
import 'package:zenoh_counter_flutter/ui/counter/counter_viewmodel.dart';
import 'package:zenoh_counter_flutter/ui/settings/settings_viewmodel.dart';

/// Fake [CounterRepository] with a controllable broadcast stream.
class FakeCounterRepository implements CounterRepository {
  final _controller = StreamController<CounterValue>.broadcast();

  bool _connected = false;

  @override
  bool get isConnected => _connected;

  @override
  Stream<CounterValue> get counterStream => _controller.stream;

  @override
  void connect(ConnectionConfig config) => _connected = true;

  @override
  void disconnect() => _connected = false;

  @override
  void dispose() {
    _connected = false;
    unawaited(_controller.close());
  }

  /// Test helper: emit a value on the stream.
  void emit(CounterValue value) => _controller.add(value);
}

/// Fake [SettingsRepository] backed by in-memory storage.
class FakeSettingsRepository implements SettingsRepository {
  ConnectionConfig _config = const ConnectionConfig();

  @override
  Future<ConnectionConfig> load() async => _config;

  @override
  Future<void> save(ConnectionConfig config) async => _config = config;
}

/// Fake [ConnectionViewModel] with controllable initial state.
class FakeConnectionViewModel extends ConnectionViewModel {
  FakeConnectionViewModel([this._initialState = const ConnectionState()]);

  final ConnectionState _initialState;

  @override
  ConnectionState build() => _initialState;
}

/// Fake [SettingsViewModel] with controllable initial state.
class FakeSettingsViewModel extends SettingsViewModel {
  /// Creates a fake with the given initial async state.
  FakeSettingsViewModel(this._initialState);

  final AsyncValue<ConnectionConfig> _initialState;

  /// The last config passed to [save], or null if not called.
  ConnectionConfig? lastSavedConfig;

  @override
  FutureOr<ConnectionConfig> build() {
    return _initialState.when(
      data: (config) => config,
      loading: () => Completer<ConnectionConfig>().future,
      error: (err, stack) =>
          throw err is Exception ? err : Exception('$err'),
    );
  }

  @override
  Future<void> save(ConnectionConfig config) async {
    lastSavedConfig = config;
    state = AsyncData(config);
  }
}

/// Fake [CounterViewModel] with controllable initial state.
class FakeCounterViewModel extends CounterViewModel {
  FakeCounterViewModel([
    this._initialState = const CounterState(),
  ]);

  final CounterState _initialState;

  @override
  CounterState build() => _initialState;

  @override
  void startListening() {}

  @override
  void stopListening() {}
}
