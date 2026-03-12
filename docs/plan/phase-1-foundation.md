# Phase 1: Foundation (Slices 1-2)

**Slices:** 1 (Data Models), 2 (ZenohService -- GATE)
**Depends on:** nothing (first phase)
**Exit criteria:** Models pass. All 6 ZenohService tests pass -- native libs
load in Flutter test runner. If the gate fails, stop and resolve before any
further work.

---

## Project Context

This is a Flutter subscriber app (`zenoh-counter-flutter`) displaying real-time
counter values from a C++ SHM publisher. MVVM architecture with Riverpod 3.x
(no codegen), go_router, SharedPreferences.

### Key Constraints

- All commands via `fvm flutter ...` / `fvm dart ...` (bare flutter NOT on PATH)
- Riverpod 3.x, NO codegen (no riverpod_annotation, no build_runner)
- `very_good_analysis` for linting
- Only `ZenohService` imports `package:zenoh` (in `lib/`)
- Line length: 80 characters max
- Functions < 20 lines, files < 400 lines
- `dart:developer` log function, NOT `print`
- Sound null safety -- avoid `!` unless guaranteed non-null
- One class per file (exceptions for tightly coupled classes)

### Import Organization

```dart
// 1. Dart SDK imports
import 'dart:async';

// 2. Package imports (alphabetical)
import 'package:flutter/material.dart';

// 3. Local project imports (alphabetical)
import 'package:zenoh_counter_flutter/data/models/counter_value.dart';
```

### Design Spec

Full design spec at `docs/design/flutter-counter-design.md`. Code sketches for
models (section 5.2) and ZenohService (section 5.1) are the primary references
for this phase.

### zenoh-dart API (upstream reference)

Available at `../zenoh_dart/packages/zenoh`. Key classes:

- `Zenoh` -- `initLog(level)` for logger init
- `Config` -- `insertJson5(key, value)` for session config
- `Session` -- `open(config:)`, `declareSubscriber()`, `declarePublisher()`, `close()`
- `Subscriber` -- `stream` (Stream<Sample>), `close()`
- `Publisher` -- `put()`, `putBytes()`, `close()`
- `Sample` -- `keyExpr`, `payload`, `payloadBytes` (Uint8List), `kind`, `encoding`
- `ZenohException` -- error type

### Counter Protocol

| Property | Value |
|----------|-------|
| Key expression | `demo/counter` (default, configurable) |
| Payload format | Raw int64, little-endian (8 bytes) |
| Publish interval | 1000ms (C++ side) |

---

## Slice 1: Data Models

**Status:** pending

**Source:** `lib/data/models/counter_value.dart`, `lib/data/models/connection_config.dart`
**Tests:** `test/data/models/counter_value_test.dart`, `test/data/models/connection_config_test.dart`

### Test 1: CounterValue stores value and timestamp
Given: an int value of 42 and a DateTime timestamp
When: a CounterValue is constructed with those arguments
Then: the value property equals 42; the timestamp property equals the provided DateTime

### Test 2: ConnectionConfig has default values
Given: no arguments provided
When: a ConnectionConfig is constructed with defaults
Then: connectEndpoint equals ''; listenEndpoint equals ''; keyExpr equals 'demo/counter'

### Test 3: ConnectionConfig.copyWith overrides fields
Given: a ConnectionConfig with connectEndpoint 'tcp/localhost:7447'
When: copyWith is called with keyExpr 'test/key'
Then: the new config has connectEndpoint 'tcp/localhost:7447' and keyExpr 'test/key'

### Edge Cases / Error Conditions

### Test 4: ConnectionConfig.copyWith with no arguments returns equivalent config
Given: a ConnectionConfig with all fields set
When: copyWith is called with no arguments
Then: the returned config has identical field values to the original

### Acceptance Criteria
- [ ] All tests pass
- [ ] Models are immutable (final fields, const constructors)
- [ ] `fvm flutter analyze` passes on model files

### Phase Tracking

- **RED:** pending
- **GREEN:** pending
- **REFACTOR:** pending

**Depends on:** none | **Blocks:** 3, 4, 5, 6

### Signatures

```dart
class CounterValue {
  const CounterValue({required this.value, required this.timestamp});
  final int value;
  final DateTime timestamp;
}

class ConnectionConfig {
  const ConnectionConfig({
    this.connectEndpoint = '',
    this.listenEndpoint = '',
    this.keyExpr = 'demo/counter',
  });
  final String connectEndpoint;
  final String listenEndpoint;
  final String keyExpr;

  ConnectionConfig copyWith({
    String? connectEndpoint,
    String? listenEndpoint,
    String? keyExpr,
  });
}
```

---

## Slice 2: ZenohService (GATE)

**Status:** pending

**Source:** `lib/data/services/zenoh_service.dart`
**Tests:** `test/data/services/zenoh_service_test.dart`

> **GATE:** All 6 tests must pass before proceeding to any subsequent slice.
> If native library loading fails in Flutter's test runner, stop and resolve
> the loading mechanism before writing any more code. No skip annotations.

### Test 1: ZenohService is not connected initially
Given: a freshly constructed ZenohService
When: isConnected is queried
Then: it returns false

### Test 2: ZenohService connects and becomes connected (integration)
Given: a ZenohService instance; no active session
When: connect is called with valid listenEndpoints
Then: isConnected returns true

### Test 3: subscribe delivers data from a publisher (integration)
Given: a ZenohService connected with listenEndpoints `['tcp/127.0.0.1:<port>']`; a second session (via `package:zenoh` directly in the test) publishing on the same key
When: the publisher puts an 8-byte payload on `'test/zenoh_service'`
Then: the subscriber's stream emits a `Uint8List` matching the published bytes

This validates the full FFI pipeline (Session -> Subscriber -> NativePort -> Stream -> Uint8List) inside Flutter's test runner.

**Note:** Test files MAY import `package:zenoh` directly to create publisher sessions. The "only ZenohService imports `package:zenoh`" rule applies to production code in `lib/`, not test infrastructure.

### Test 4: ZenohService dispose cleans up session (integration)
Given: a connected ZenohService
When: dispose is called
Then: isConnected returns false

### Edge Cases / Error Conditions

### Test 5: ZenohService connect is idempotent (integration)
Given: an already-connected ZenohService
When: connect is called again
Then: no error is thrown; isConnected remains true

### Test 6: ZenohService subscribe throws when not connected
Given: a ZenohService that has not called connect
When: subscribe is called
Then: a StateError is thrown

### Acceptance Criteria
- [ ] All 6 tests pass (GATE -- no skip annotations)
- [ ] Integration tests validate full FFI pipeline in Flutter's test runner
- [ ] Only this file imports `package:zenoh` (in `lib/`)
- [ ] `subscribe()` returns `Stream<Uint8List>`, not `Stream<Sample>`
- [ ] `fvm flutter analyze` passes

### Phase Tracking

- **RED:** pending
- **GREEN:** pending
- **REFACTOR:** pending

**Depends on:** none | **Blocks:** 4, 6

### Signature

`subscribe()` returns `Stream<Uint8List>`, not `Stream<Sample>`. ZenohService
extracts `sample.payloadBytes` internally:

```dart
class ZenohService {
  Session? _session;
  Subscriber? _subscriber;

  bool get isConnected => _session != null;

  void connect({
    List<String> connectEndpoints = const [],
    List<String> listenEndpoints = const [],
  }) {
    if (_session != null) return;
    Zenoh.initLog('error');
    final config = Config();
    if (connectEndpoints.isNotEmpty) {
      config.insertJson5('mode', '"client"');
      final json = connectEndpoints.map((e) => '"$e"').join(', ');
      config.insertJson5('connect/endpoints', '[$json]');
    }
    if (listenEndpoints.isNotEmpty) {
      final json = listenEndpoints.map((e) => '"$e"').join(', ');
      config.insertJson5('listen/endpoints', '[$json]');
    }
    _session = Session.open(config: config);
  }

  Stream<Uint8List> subscribe(String keyExpr) {
    final session = _session;
    if (session == null) throw StateError('Not connected');
    _subscriber?.close();
    _subscriber = session.declareSubscriber(keyExpr);
    return _subscriber!.stream.map((sample) => sample.payloadBytes);
  }

  void dispose() {
    _subscriber?.close();
    _subscriber = null;
    _session?.close();
    _session = null;
  }
}
```

### Two-Session Test Pattern

For Test 3, use a second zenoh session directly in the test to publish data:

```dart
// In the test file (MAY import package:zenoh directly):
// 1. ZenohService listens on tcp/127.0.0.1:<port>
// 2. Second session connects to same port
// 3. Second session publishes 8-byte payload
// 4. ZenohService's subscribe stream emits matching Uint8List
```

Use unique ports per test group to avoid conflicts. This is the established
pattern from zenoh-dart's own test suite.

---

## Dependencies for This Phase

```yaml
# pubspec.yaml (already configured)
dependencies:
  zenoh:
    path: ../zenoh_dart/packages/zenoh

dev_dependencies:
  flutter_test:
    sdk: flutter
  very_good_analysis: ^10.2.0
```

## What Happens Next

After this phase passes, Phase 2 (Data Layer) implements SettingsRepository
and CounterRepository. The ZenohService gate ensures native libs work before
building anything on top.
