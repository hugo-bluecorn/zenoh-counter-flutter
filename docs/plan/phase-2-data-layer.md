# Phase 2: Data Layer (Slices 3-4)

**Slices:** 3 (SettingsRepository), 4 (CounterRepository)
**Depends on:** Phase 1 (models + ZenohService gate passed)
**Exit criteria:** Both repositories pass. `Stream<Uint8List>` boundary validated
end-to-end with two-session tests.

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
import 'package:shared_preferences/shared_preferences.dart';

// 3. Local project imports (alphabetical)
import 'package:zenoh_counter_flutter/data/models/connection_config.dart';
```

### What Exists After Phase 1

- `lib/data/models/counter_value.dart` -- CounterValue (immutable, const constructor)
- `lib/data/models/connection_config.dart` -- ConnectionConfig (immutable, copyWith, defaults)
- `lib/data/services/zenoh_service.dart` -- ZenohService (connect, subscribe -> Stream<Uint8List>, dispose)

### Counter Protocol

| Property | Value |
|----------|-------|
| Key expression | `demo/counter` (default, configurable) |
| Payload format | Raw int64, little-endian (8 bytes) |
| Decoding | `bytes.buffer.asByteData().getInt64(0, Endian.little)` |

---

## Slice 3: SettingsRepository

**Status:** pending

**Source:** `lib/data/repositories/settings_repository.dart`, `lib/data/repositories/settings_repository_impl.dart`
**Tests:** `test/data/repositories/settings_repository_test.dart`

### Test 1: load returns default config when prefs are empty
Given: a SharedPreferences instance with no stored values
When: SettingsRepositoryImpl.load is called
Then: the returned ConnectionConfig has empty connectEndpoint, empty listenEndpoint, and keyExpr 'demo/counter'

### Test 2: save persists config and load retrieves it
Given: a SharedPreferences instance
When: save is called with a ConnectionConfig(connectEndpoint: 'tcp/host:7447', keyExpr: 'test/key'); then load is called
Then: the loaded config has connectEndpoint 'tcp/host:7447' and keyExpr 'test/key'

### Test 3: save overwrites previous values
Given: a config was previously saved with connectEndpoint 'old'
When: save is called with connectEndpoint 'new'; then load is called
Then: the loaded config has connectEndpoint 'new'

### Edge Cases / Error Conditions

### Test 4: load returns default keyExpr when only endpoints are saved
Given: SharedPreferences has connectEndpoint stored but no keyExpr
When: load is called
Then: keyExpr defaults to 'demo/counter'

### Acceptance Criteria
- [ ] All tests pass
- [ ] Abstract interface defined separately from implementation
- [ ] Uses `SharedPreferences.setMockInitialValues({})` for testing
- [ ] `fvm flutter analyze` passes

### Phase Tracking

- **RED:** pending
- **GREEN:** pending
- **REFACTOR:** pending

**Depends on:** 1 | **Blocks:** 6, 12

### Signatures

```dart
// lib/data/repositories/settings_repository.dart
abstract class SettingsRepository {
  Future<ConnectionConfig> load();
  Future<void> save(ConnectionConfig config);
}

// lib/data/repositories/settings_repository_impl.dart
class SettingsRepositoryImpl implements SettingsRepository {
  SettingsRepositoryImpl(this._prefs);
  final SharedPreferences _prefs;

  static const _connectKey = 'connect_endpoint';
  static const _listenKey = 'listen_endpoint';
  static const _keyExprKey = 'key_expr';

  @override
  Future<ConnectionConfig> load() async {
    return ConnectionConfig(
      connectEndpoint: _prefs.getString(_connectKey) ?? '',
      listenEndpoint: _prefs.getString(_listenKey) ?? '',
      keyExpr: _prefs.getString(_keyExprKey) ?? 'demo/counter',
    );
  }

  @override
  Future<void> save(ConnectionConfig config) async {
    await _prefs.setString(_connectKey, config.connectEndpoint);
    await _prefs.setString(_listenKey, config.listenEndpoint);
    await _prefs.setString(_keyExprKey, config.keyExpr);
  }
}
```

### Testing Pattern

Use `SharedPreferences.setMockInitialValues({})` in setUp to initialize the
mock backing store. No real SharedPreferences instance needed.

```dart
setUp(() {
  SharedPreferences.setMockInitialValues({});
});
```

---

## Slice 4: CounterRepository

**Status:** pending

**Source:** `lib/data/repositories/counter_repository.dart`, `lib/data/repositories/counter_repository_impl.dart`
**Tests:** `test/data/repositories/counter_repository_test.dart`

CounterRepositoryImpl receives `Stream<Uint8List>` from ZenohService, not
`Stream<Sample>`. It never imports `package:zenoh`.

### Test 1: isConnected delegates to ZenohService
Given: a CounterRepositoryImpl with a ZenohService
When: isConnected is queried before any connection
Then: it returns false

### Test 2: counterStream emits CounterValue from decoded payloads (integration)
Given: a CounterRepositoryImpl connected to a ZenohService listening on `tcp/127.0.0.1:<unique-port>`; a second session (via `package:zenoh` directly in the test) publishing 8-byte int64 LE payloads on `'test/counter_repo'`
When: the publisher puts the int64 value 42 as little-endian bytes
Then: counterStream emits a CounterValue with value 42 and a recent timestamp

**Test mechanism:** Use a second session (direct `package:zenoh` import in the
test file only) with explicit TCP listen/connect on a unique port per test
group. This is the established pattern from zenoh-dart's own test suite.

### Test 3: disconnect stops subscription and disposes service
Given: a connected CounterRepositoryImpl
When: disconnect is called
Then: isConnected returns false; no further events on counterStream

### Edge Cases / Error Conditions

### Test 4: counterStream ignores payloads with wrong size (integration)
Given: a CounterRepositoryImpl connected and subscribed; a second session publishing on the same key
When: a payload with length != 8 is published
Then: counterStream does not emit a value for that payload

### Acceptance Criteria
- [ ] All tests pass
- [ ] Abstract interface defined separately from implementation
- [ ] Broadcast StreamController used for counterStream
- [ ] Does NOT import `package:zenoh` -- receives `Stream<Uint8List>` from ZenohService
- [ ] Integration tests use two-session TCP pattern with unique ports
- [ ] `fvm flutter analyze` passes

### Phase Tracking

- **RED:** pending
- **GREEN:** pending
- **REFACTOR:** pending

**Depends on:** 1, 2 | **Blocks:** 5, 6, 8, 9

### Signatures

```dart
// lib/data/repositories/counter_repository.dart
abstract class CounterRepository {
  bool get isConnected;
  Stream<CounterValue> get counterStream;
  void connect(ConnectionConfig config);
  void disconnect();
  void dispose();
}

// lib/data/repositories/counter_repository_impl.dart
class CounterRepositoryImpl implements CounterRepository {
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
    _zenohService.connect(
      connectEndpoints: config.connectEndpoint.isNotEmpty
          ? [config.connectEndpoint] : [],
      listenEndpoints: config.listenEndpoint.isNotEmpty
          ? [config.listenEndpoint] : [],
    );
    _subscription = _zenohService.subscribe(config.keyExpr).listen(
      (bytes) {
        if (bytes.length == 8) {
          final value = bytes.buffer
              .asByteData().getInt64(0, Endian.little);
          _controller.add(CounterValue(
            value: value,
            timestamp: DateTime.now(),
          ));
        }
      },
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
```

**Note:** `_subscription` is `StreamSubscription<Uint8List>` (not
`StreamSubscription<Sample>`) because ZenohService.subscribe() returns
`Stream<Uint8List>`.

### Two-Session Test Pattern

For integration tests, use a second zenoh session directly in the test file:

```dart
// Test file MAY import package:zenoh directly
// 1. ZenohService (inside CounterRepositoryImpl) listens on unique port
// 2. Second session connects to same port
// 3. Second session publishes int64 LE bytes
// 4. counterStream emits decoded CounterValue
```

Use unique ports per test group. Key expression should be unique per test
(e.g., `'test/counter_repo'`) to avoid cross-test interference.

---

## Dependencies for This Phase

```yaml
# Already in pubspec.yaml
dependencies:
  shared_preferences: ^2.5.4
  zenoh:
    path: ../zenoh_dart/packages/zenoh
```

## What Happens Next

After this phase passes, Phase 3 (Wiring) creates test helpers/fakes and
provider definitions that wire everything together.
