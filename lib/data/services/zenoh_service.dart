import 'dart:typed_data';

import 'package:zenoh/zenoh.dart';

/// Wraps all `package:zenoh` access for the application.
///
/// Only this file should import `package:zenoh` in `lib/`.
class ZenohService {
  Session? _session;
  Subscriber? _subscriber;

  /// Whether a zenoh session is currently open.
  bool get isConnected => _session != null;

  /// Opens a zenoh session with the given endpoints.
  ///
  /// If already connected, this is a no-op (idempotent).
  void connect({
    List<String> connectEndpoints = const [],
    List<String> listenEndpoints = const [],
  }) {
    if (_session != null) return;

    Zenoh.initLog('error');
    final config = Config();

    if (connectEndpoints.isNotEmpty) {
      config.insertJson5('mode', '"client"');
      final json =
          connectEndpoints.map((e) => '"$e"').join(', ');
      config.insertJson5(
        'connect/endpoints',
        '[$json]',
      );
    }
    if (listenEndpoints.isNotEmpty) {
      final json =
          listenEndpoints.map((e) => '"$e"').join(', ');
      config.insertJson5(
        'listen/endpoints',
        '[$json]',
      );
    }

    _session = Session.open(config: config);
  }

  /// Subscribes to the given key expression.
  ///
  /// Returns a stream of raw payload bytes. Closes any
  /// previous subscription before creating a new one.
  ///
  /// Throws [StateError] if not connected.
  Stream<Uint8List> subscribe(String keyExpr) {
    final session = _session;
    if (session == null) {
      throw StateError('Not connected');
    }
    _subscriber?.close();
    _subscriber = session.declareSubscriber(keyExpr);
    return _subscriber!.stream
        .map((sample) => sample.payloadBytes);
  }

  /// Closes the subscriber and session, releasing all
  /// resources. Safe to call multiple times.
  void dispose() {
    _subscriber?.close();
    _subscriber = null;
    _session?.close();
    _session = null;
  }
}
