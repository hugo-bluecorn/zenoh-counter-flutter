import 'package:zenoh_counter_flutter/data/models/connection_config.dart';
import 'package:zenoh_counter_flutter/data/models/counter_value.dart';

/// Fixed timestamp for deterministic tests.
final testTimestamp = DateTime(2026, 3, 12, 10, 30);

/// Standard counter value for tests.
final testCounterValue = CounterValue(
  value: 42,
  timestamp: testTimestamp,
);

/// Standard connection config for tests.
const testConfig = ConnectionConfig(
  connectEndpoint: 'tcp/localhost:7447',
);
