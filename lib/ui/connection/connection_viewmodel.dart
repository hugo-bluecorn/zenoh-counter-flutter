import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zenoh_counter_flutter/data/models/connection_config.dart';
import 'package:zenoh_counter_flutter/providers/providers.dart';

/// Connection lifecycle status.
enum ConnectionStatus {
  /// Not connected to zenoh.
  disconnected,

  /// Connection attempt in progress.
  connecting,

  /// Successfully connected to zenoh.
  connected,

  /// Connection failed with an error.
  error,
}

/// Immutable state for the connection screen.
class ConnectionState {
  /// Creates a [ConnectionState] with the given status and error.
  const ConnectionState({
    this.status = ConnectionStatus.disconnected,
    this.error,
  });

  /// Current connection status.
  final ConnectionStatus status;

  /// Error message if status is [ConnectionStatus.error].
  final String? error;

  /// Returns a copy with the given fields replaced.
  ConnectionState copyWith({
    ConnectionStatus? status,
    String? error,
  }) {
    return ConnectionState(
      status: status ?? this.status,
      error: error,
    );
  }
}

/// Manages connection lifecycle via the counter repository.
class ConnectionViewModel extends Notifier<ConnectionState> {
  @override
  ConnectionState build() => const ConnectionState();

  /// Connects to zenoh using the given [config].
  void connect(ConnectionConfig config) {
    state = state.copyWith(
      status: ConnectionStatus.connecting,
    );
    try {
      ref.read(counterRepositoryProvider).connect(config);
      state = state.copyWith(
        status: ConnectionStatus.connected,
      );
    } on Exception catch (e) {
      state = state.copyWith(
        status: ConnectionStatus.error,
        error: e.toString(),
      );
    }
  }

  /// Disconnects from zenoh and resets state.
  void disconnect() {
    ref.read(counterRepositoryProvider).disconnect();
    state = const ConnectionState();
  }
}
