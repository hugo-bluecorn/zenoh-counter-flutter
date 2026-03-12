# Phase 4: ViewModels (Slices 7-8-9)

**Slices:** 7 (App Shell + Theme), 8 (ConnectionViewModel), 9 (CounterViewModel)
**Depends on:** Phase 3 (providers + fakes ready)
**Exit criteria:** App shell renders. Both ViewModels pass with fakes.

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
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// 3. Local project imports (alphabetical)
import 'package:zenoh_counter_flutter/providers/providers.dart';
```

### What Exists After Phases 1-3

- `lib/data/models/` -- CounterValue, ConnectionConfig
- `lib/data/services/zenoh_service.dart` -- ZenohService
- `lib/data/repositories/` -- abstract + impl for Counter and Settings
- `lib/providers/providers.dart` -- infrastructure + repository providers
- `test/helpers/fakes.dart` -- FakeCounterRepository, FakeSettingsRepository
- `test/helpers/test_data.dart` -- test fixtures

---

## Slice 7: App Shell and Theme

**Status:** pending

**Source:** `lib/main.dart`, `lib/app.dart`, `lib/ui/core/themes/app_theme.dart`
**Tests:** `test/app_test.dart`

### Test 1: App renders with ProviderScope and MaterialApp.router
Given: the app is pumped with required provider overrides (SharedPreferences, router)
When: the widget tree is built
Then: a MaterialApp.router is found in the widget tree

### Test 2: App uses Material 3 theme
Given: the app is pumped with required overrides
When: the theme is inspected
Then: useMaterial3 is true

### Edge Cases / Error Conditions

### Test 3: App shows initial route (connection screen placeholder)
Given: the app is pumped with required overrides
When: the widget tree settles
Then: the initial route content is displayed (ConnectionScreen or placeholder)

### Acceptance Criteria
- [ ] All tests pass
- [ ] main.dart initializes SharedPreferences and wraps in ProviderScope
- [ ] app.dart uses MaterialApp.router with routerProvider
- [ ] AppTheme provides a Material 3 ThemeData
- [ ] `fvm flutter analyze` passes

### Phase Tracking

- **RED:** pending
- **GREEN:** pending
- **REFACTOR:** pending

**Depends on:** 6 | **Blocks:** 10, 11, 12

### Signatures

```dart
// lib/main.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const App(),
    ),
  );
}

// lib/app.dart
class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'Zenoh Counter',
      theme: AppTheme.light,
      routerConfig: router,
    );
  }
}

// lib/ui/core/themes/app_theme.dart
class AppTheme {
  static ThemeData get light => ThemeData(
    useMaterial3: true,
    colorSchemeSeed: Colors.blue, // or appropriate seed
  );
}
```

**Note:** The routerProvider is defined in `lib/routing/app_router.dart` which
will be fully implemented in Phase 6. For this phase, create a minimal router
with placeholder routes so the app shell can render.

---

## Slice 8: ConnectionViewModel

**Status:** pending

**Source:** `lib/ui/connection/connection_viewmodel.dart`
**Tests:** `test/ui/connection/connection_viewmodel_test.dart`

### Test 1: Initial state is disconnected
Given: a ConnectionViewModel is created via a ProviderContainer
When: the state is read
Then: status is ConnectionStatus.disconnected; error is null

### Test 2: connect transitions to connected on success
Given: a ConnectionViewModel with counterRepositoryProvider overridden with a fake
When: connect is called with a valid ConnectionConfig
Then: status transitions to ConnectionStatus.connected

### Test 3: connect transitions to error on failure
Given: a ConnectionViewModel with a fake CounterRepository that throws on connect
When: connect is called
Then: status is ConnectionStatus.error; error contains the exception message

### Test 4: disconnect resets to disconnected state
Given: a ConnectionViewModel in connected state
When: disconnect is called
Then: status is ConnectionStatus.disconnected; error is null

### Edge Cases / Error Conditions

### Test 5: connect sets connecting status before completion
Given: a ConnectionViewModel in disconnected state
When: connect is called (observed synchronously)
Then: status passes through ConnectionStatus.connecting

### Acceptance Criteria
- [ ] All tests pass
- [ ] Uses NotifierProvider (not AsyncNotifier)
- [ ] Tests use ProviderContainer with overrides (no zenoh)
- [ ] `fvm flutter analyze` passes

### Phase Tracking

- **RED:** pending
- **GREEN:** pending
- **REFACTOR:** pending

**Depends on:** 1, 4, 5, 6 | **Blocks:** 10

### Signatures

```dart
// lib/ui/connection/connection_viewmodel.dart

enum ConnectionStatus { disconnected, connecting, connected, error }

class ConnectionState {
  const ConnectionState({
    this.status = ConnectionStatus.disconnected,
    this.error,
  });
  final ConnectionStatus status;
  final String? error;

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

class ConnectionViewModel extends Notifier<ConnectionState> {
  @override
  ConnectionState build() => const ConnectionState();

  void connect(ConnectionConfig config) {
    state = state.copyWith(
      status: ConnectionStatus.connecting,
      error: null,
    );
    try {
      ref.read(counterRepositoryProvider).connect(config);
      state = state.copyWith(status: ConnectionStatus.connected);
    } catch (e) {
      state = state.copyWith(
        status: ConnectionStatus.error,
        error: e.toString(),
      );
    }
  }

  void disconnect() {
    ref.read(counterRepositoryProvider).disconnect();
    state = const ConnectionState();
  }
}
```

**Provider definition** (add to `lib/providers/providers.dart`):

```dart
final connectionViewModelProvider =
    NotifierProvider<ConnectionViewModel, ConnectionState>(
  ConnectionViewModel.new,
);
```

### Testing Pattern

Use FakeCounterRepository from `test/helpers/fakes.dart`:

```dart
test('connect transitions to connected', () {
  final fake = FakeCounterRepository();
  final container = ProviderContainer(
    overrides: [counterRepositoryProvider.overrideWithValue(fake)],
  );
  addTearDown(container.dispose);
  final vm = container.read(connectionViewModelProvider.notifier);
  vm.connect(const ConnectionConfig(connectEndpoint: 'tcp/host:7447'));
  expect(
    container.read(connectionViewModelProvider).status,
    ConnectionStatus.connected,
  );
});
```

---

## Slice 9: CounterViewModel

**Status:** pending

**Source:** `lib/ui/counter/counter_viewmodel.dart`
**Tests:** `test/ui/counter/counter_viewmodel_test.dart`

### Test 1: Initial state has no value and is not subscribed
Given: a CounterViewModel is created via a ProviderContainer
When: the state is read
Then: value is null; lastUpdate is null; isSubscribed is false

### Test 2: startListening sets isSubscribed to true
Given: a CounterViewModel with a fake CounterRepository providing a broadcast stream
When: startListening is called
Then: isSubscribed becomes true

### Test 3: startListening updates state when counterStream emits
Given: a CounterViewModel listening to a fake CounterRepository
When: the fake stream emits CounterValue(value: 42, timestamp: fixedTime)
Then: state.value equals 42; state.lastUpdate equals fixedTime

### Test 4: stopListening resets state
Given: a CounterViewModel that is currently listening with value 42
When: stopListening is called
Then: value is null; isSubscribed is false

### Edge Cases / Error Conditions

### Test 5: startListening cancels previous subscription
Given: a CounterViewModel already listening
When: startListening is called again
Then: no duplicate subscriptions; only latest stream events update state

### Acceptance Criteria
- [ ] All tests pass
- [ ] Uses NotifierProvider (sync)
- [ ] Disposes StreamSubscription via ref.onDispose
- [ ] Tests use ProviderContainer with fake CounterRepository
- [ ] `fvm flutter analyze` passes

### Phase Tracking

- **RED:** pending
- **GREEN:** pending
- **REFACTOR:** pending

**Depends on:** 1, 4, 5, 6 | **Blocks:** 11

### Signatures

```dart
// lib/ui/counter/counter_viewmodel.dart

class CounterState {
  const CounterState({
    this.value,
    this.lastUpdate,
    this.isSubscribed = false,
  });
  final int? value;
  final DateTime? lastUpdate;
  final bool isSubscribed;

  CounterState copyWith({
    int? value,
    DateTime? lastUpdate,
    bool? isSubscribed,
  }) {
    return CounterState(
      value: value ?? this.value,
      lastUpdate: lastUpdate ?? this.lastUpdate,
      isSubscribed: isSubscribed ?? this.isSubscribed,
    );
  }
}

class CounterViewModel extends Notifier<CounterState> {
  StreamSubscription<CounterValue>? _subscription;

  @override
  CounterState build() {
    ref.onDispose(() => _subscription?.cancel());
    return const CounterState();
  }

  void startListening() {
    _subscription?.cancel();
    _subscription = ref
        .read(counterRepositoryProvider)
        .counterStream
        .listen((counterValue) {
      state = state.copyWith(
        value: counterValue.value,
        lastUpdate: counterValue.timestamp,
        isSubscribed: true,
      );
    });
    state = state.copyWith(isSubscribed: true);
  }

  void stopListening() {
    _subscription?.cancel();
    _subscription = null;
    state = const CounterState();
  }
}
```

**Provider definition** (add to `lib/providers/providers.dart`):

```dart
final counterViewModelProvider =
    NotifierProvider<CounterViewModel, CounterState>(
  CounterViewModel.new,
);
```

### Testing Pattern

Use FakeCounterRepository to control stream emissions:

```dart
test('startListening updates state on stream emit', () async {
  final fake = FakeCounterRepository();
  final container = ProviderContainer(
    overrides: [counterRepositoryProvider.overrideWithValue(fake)],
  );
  addTearDown(container.dispose);
  final vm = container.read(counterViewModelProvider.notifier);
  vm.startListening();
  fake.emit(CounterValue(value: 42, timestamp: testTimestamp));
  await Future<void>.delayed(Duration.zero); // let stream propagate
  expect(container.read(counterViewModelProvider).value, 42);
});
```

---

## What Happens Next

After this phase passes, Phase 5 (Screens) implements ConnectionScreen,
CounterScreen, and SettingsScreen + SettingsViewModel using the ViewModels
and fakes established here.
