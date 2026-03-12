import 'package:zenoh_counter_flutter/data/models/connection_config.dart';
import 'package:zenoh_counter_flutter/data/models/counter_value.dart';

/// Abstract interface for accessing counter data from zenoh.
abstract class CounterRepository {
  /// Whether the underlying service is connected.
  bool get isConnected;

  /// Stream of decoded counter values.
  Stream<CounterValue> get counterStream;

  /// Connects to zenoh and starts subscribing.
  void connect(ConnectionConfig config);

  /// Stops the subscription and disconnects.
  void disconnect();

  /// Releases all resources. Safe to call multiple times.
  void dispose();
}
