import 'package:flutter_test/flutter_test.dart';
import 'package:zenoh_counter_flutter/data/models/counter_value.dart';

void main() {
  group('CounterValue', () {
    test('stores value and timestamp', () {
      final timestamp = DateTime(2026, 3, 12, 10, 30);
      const value = 42;

      final counterValue = CounterValue(
        value: value,
        timestamp: timestamp,
      );

      expect(counterValue.value, equals(42));
      expect(counterValue.timestamp, equals(timestamp));
    });
  });
}
