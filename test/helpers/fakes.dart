import 'dart:async';

import 'package:zenoh_counter_flutter/data/models/connection_config.dart';
import 'package:zenoh_counter_flutter/data/models/counter_value.dart';
import 'package:zenoh_counter_flutter/data/repositories/counter_repository.dart';
import 'package:zenoh_counter_flutter/data/repositories/settings_repository.dart';
import 'package:zenoh_counter_flutter/ui/connection/connection_viewmodel.dart';

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
