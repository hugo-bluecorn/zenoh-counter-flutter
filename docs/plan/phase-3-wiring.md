# Phase 3: Wiring (Slices 5-6)

**Slices:** 5 (Test Helpers & Fakes), 6 (Providers)
**Depends on:** Phase 2 (repositories implemented and passing)
**Exit criteria:** All providers resolve. Disposal test validates cleanup.
Fakes ready for ViewModel and Screen tests.

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

### Import Organization

```dart
// 1. Dart SDK imports
import 'dart:async';

// 2. Package imports (alphabetical)
import 'package:flutter_riverpod/flutter_riverpod.dart';

// 3. Local project imports (alphabetical)
import 'package:zenoh_counter_flutter/data/services/zenoh_service.dart';
```

### What Exists After Phases 1-2

- `lib/data/models/counter_value.dart` -- CounterValue
- `lib/data/models/connection_config.dart` -- ConnectionConfig
- `lib/data/services/zenoh_service.dart` -- ZenohService
- `lib/data/repositories/settings_repository.dart` -- abstract SettingsRepository
- `lib/data/repositories/settings_repository_impl.dart` -- SettingsRepositoryImpl
- `lib/data/repositories/counter_repository.dart` -- abstract CounterRepository
- `lib/data/repositories/counter_repository_impl.dart` -- CounterRepositoryImpl

---

## Slice 5: Test Helpers and Fakes

**Status:** pending

**Source:** `test/helpers/test_data.dart`, `test/helpers/fakes.dart`
**Tests:** (used by other test files, not directly tested)

This slice creates shared test infrastructure used across slices 8-12.

### Contents to provide:

- FakeCounterRepository implementing CounterRepository with controllable StreamController
- FakeSettingsRepository implementing SettingsRepository with in-memory storage
- FakeCounterViewModel extending CounterViewModel with preset state
- FakeConnectionViewModel extending ConnectionViewModel with preset state
- Test fixture constants (sample CounterValue, sample ConnectionConfig, fixed timestamps)

### Acceptance Criteria
- [ ] Fakes are usable by widget tests without importing `package:zenoh`
- [ ] StreamController in FakeCounterRepository is broadcast
- [ ] `fvm flutter analyze` passes on helper files

### Phase Tracking

- **RED:** pending (N/A -- not directly tested)
- **GREEN:** pending
- **REFACTOR:** pending

**Depends on:** 1, 3, 4 | **Blocks:** 8, 9, 10, 11, 12

### Guidance

Fakes implement the abstract interfaces from the data layer. They must NOT
import `package:zenoh` -- they work with plain Dart types only.

```dart
// test/helpers/fakes.dart

class FakeCounterRepository implements CounterRepository {
  final _controller = StreamController<CounterValue>.broadcast();
  bool _connected = false;

  @override
  bool get isConnected => _connected;

  @override
  Stream<CounterValue> get counterStream => _controller.stream;

  @override
  void connect(ConnectionConfig config) => _connected = true;

  @override
  void disconnect() => _connected = false;

  @override
  void dispose() {
    _connected = false;
    _controller.close();
  }

  /// Test helper: emit a value on the stream.
  void emit(CounterValue value) => _controller.add(value);
}

class FakeSettingsRepository implements SettingsRepository {
  ConnectionConfig _config = const ConnectionConfig();

  @override
  Future<ConnectionConfig> load() async => _config;

  @override
  Future<void> save(ConnectionConfig config) async => _config = config;
}
```

```dart
// test/helpers/test_data.dart

final testTimestamp = DateTime(2026, 3, 12, 10, 30);
const testCounterValue = CounterValue(value: 42, timestamp: /* use testTimestamp */);
const testConfig = ConnectionConfig(
  connectEndpoint: 'tcp/localhost:7447',
  keyExpr: 'demo/counter',
);
```

---

## Slice 6: Providers

**Status:** pending

**Source:** `lib/providers/providers.dart`
**Tests:** `test/providers/providers_test.dart`

### Test 1: zenohServiceProvider creates a ZenohService
Given: a ProviderContainer with no overrides
When: zenohServiceProvider is read
Then: it returns a ZenohService instance

### Test 2: settingsRepositoryProvider resolves with SharedPreferences override
Given: a ProviderContainer with sharedPreferencesProvider overridden
When: settingsRepositoryProvider is read
Then: it returns a SettingsRepositoryImpl instance

### Test 3: counterRepositoryProvider resolves with zenohService
Given: a ProviderContainer with no overrides
When: counterRepositoryProvider is read
Then: it returns a CounterRepositoryImpl instance

### Test 4: sharedPreferencesProvider throws without override
Given: a ProviderContainer with no overrides
When: sharedPreferencesProvider is read
Then: an UnimplementedError is thrown

### Edge Cases / Error Conditions

### Test 5: Provider disposal triggers cleanup
Given: a ProviderContainer where zenohServiceProvider has been read AND the ZenohService has been connected (isConnected == true)
When: the container is disposed
Then: the ZenohService is no longer connected (isConnected == false)

### Acceptance Criteria
- [ ] All tests pass
- [ ] All provider definitions in a single file
- [ ] No codegen (no riverpod_annotation)
- [ ] `fvm flutter analyze` passes

### Phase Tracking

- **RED:** pending
- **GREEN:** pending
- **REFACTOR:** pending

**Depends on:** 1, 2, 3, 4 | **Blocks:** 7, 8, 9, 10, 11, 12

### Signatures

```dart
// lib/providers/providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// --- Infrastructure ---

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('Override in main()');
});

final zenohServiceProvider = Provider<ZenohService>((ref) {
  final service = ZenohService();
  ref.onDispose(service.dispose);
  return service;
});

// --- Repositories ---

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return SettingsRepositoryImpl(prefs);
});

final counterRepositoryProvider = Provider<CounterRepository>((ref) {
  final service = ref.watch(zenohServiceProvider);
  final repo = CounterRepositoryImpl(service);
  ref.onDispose(repo.dispose);
  return repo;
});

// --- ViewModels (defined in Phase 4) ---
// connectionViewModelProvider
// counterViewModelProvider
// settingsViewModelProvider
```

**Note:** ViewModel provider definitions will be added in Phase 4 when the
ViewModels are implemented. For now, only infrastructure and repository
providers are defined.

### Testing Pattern

Use `ProviderContainer` for unit testing providers:

```dart
test('zenohServiceProvider creates a ZenohService', () {
  final container = ProviderContainer();
  addTearDown(container.dispose);
  final service = container.read(zenohServiceProvider);
  expect(service, isA<ZenohService>());
});
```

For Test 5 (disposal), connect the service first so isConnected changes
from true to false on disposal:

```dart
test('disposal triggers cleanup', () {
  final container = ProviderContainer();
  final service = container.read(zenohServiceProvider);
  service.connect(listenEndpoints: ['tcp/127.0.0.1:0']);
  expect(service.isConnected, isTrue);
  container.dispose();
  expect(service.isConnected, isFalse);
});
```

---

## What Happens Next

After this phase passes, Phase 4 (ViewModels) implements the app shell,
ConnectionViewModel, and CounterViewModel using the providers and fakes
established here.
