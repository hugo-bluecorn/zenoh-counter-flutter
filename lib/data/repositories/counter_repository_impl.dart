import 'dart:async';
import 'dart:typed_data';

import 'package:zenoh_counter_flutter/data/models/connection_config.dart';
import 'package:zenoh_counter_flutter/data/models/counter_value.dart';
import 'package:zenoh_counter_flutter/data/repositories/counter_repository.dart';
import 'package:zenoh_counter_flutter/data/services/zenoh_service.dart';

/// Concrete [CounterRepository] backed by [ZenohService].
///
/// Decodes raw int64 little-endian payloads into
/// [CounterValue] instances. Payloads that are not exactly
/// 8 bytes are silently ignored.
class CounterRepositoryImpl implements CounterRepository {
  /// Creates a repository wrapping the given [ZenohService].
  CounterRepositoryImpl(this._zenohService);

  final ZenohService _zenohService;
  final _controller = StreamController<CounterValue>.broadcast();
  StreamSubscription<Uint8List>? _subscription;

  @override
  bool get isConnected => _zenohService.isConnected;

  @override
  Stream<CounterValue> get counterStream => _controller.stream;

  @override
  void connect(ConnectionConfig config) {
    final connectList = config.connectEndpoint.isNotEmpty
        ? [config.connectEndpoint]
        : <String>[];
    final listenList = config.listenEndpoint.isNotEmpty
        ? [config.listenEndpoint]
        : <String>[];

    _zenohService.connect(
      connectEndpoints: connectList,
      listenEndpoints: listenList,
    );

    _subscription =
        _zenohService.subscribe(config.keyExpr).listen(
      _onData,
    );
  }

  void _onData(Uint8List bytes) {
    if (bytes.length != 8) return;
    final value = bytes.buffer
        .asByteData()
        .getInt64(0, Endian.little);
    _controller.add(
      CounterValue(
        value: value,
        timestamp: DateTime.now(),
      ),
    );
  }

  @override
  void disconnect() {
    _subscription?.cancel();
    _subscription = null;
    _zenohService.dispose();
  }

  @override
  void dispose() {
    disconnect();
    _controller.close();
  }
}
