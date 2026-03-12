/// Represents a counter value received from a zenoh publisher.
class CounterValue {
  /// Creates a [CounterValue] with the given [value] and [timestamp].
  const CounterValue({
    required this.value,
    required this.timestamp,
  });

  /// The integer counter value.
  final int value;

  /// When the value was received.
  final DateTime timestamp;
}
