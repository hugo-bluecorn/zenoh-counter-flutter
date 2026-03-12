/// Configuration for connecting to a zenoh network.
class ConnectionConfig {
  /// Creates a [ConnectionConfig] with optional endpoint and key
  /// expression overrides.
  const ConnectionConfig({
    this.connectEndpoint = '',
    this.listenEndpoint = '',
    this.keyExpr = 'demo/counter',
  });

  /// The endpoint to connect to (e.g., 'tcp/localhost:7447').
  final String connectEndpoint;

  /// The endpoint to listen on (e.g., 'tcp/0.0.0.0:7448').
  final String listenEndpoint;

  /// The zenoh key expression to subscribe to.
  final String keyExpr;

  /// Returns a copy with the given fields replaced.
  ConnectionConfig copyWith({
    String? connectEndpoint,
    String? listenEndpoint,
    String? keyExpr,
  }) {
    return ConnectionConfig(
      connectEndpoint:
          connectEndpoint ?? this.connectEndpoint,
      listenEndpoint:
          listenEndpoint ?? this.listenEndpoint,
      keyExpr: keyExpr ?? this.keyExpr,
    );
  }
}
