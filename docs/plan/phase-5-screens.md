# Phase 5: Screens (Slices 10-11-12)

**Slices:** 10 (ConnectionScreen), 11 (CounterScreen), 12 (SettingsScreen + SettingsViewModel)
**Depends on:** Phase 4 (app shell + ViewModels passing)
**Exit criteria:** All three screens pass widget tests with provider overrides.

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

### What Exists After Phases 1-4

- `lib/data/models/` -- CounterValue, ConnectionConfig
- `lib/data/services/zenoh_service.dart` -- ZenohService
- `lib/data/repositories/` -- abstract + impl for Counter and Settings
- `lib/providers/providers.dart` -- all providers (infra, repo, ViewModel)
- `lib/main.dart` -- ProviderScope + SharedPreferences init
- `lib/app.dart` -- MaterialApp.router + theme
- `lib/ui/core/themes/app_theme.dart` -- Material 3 theme
- `lib/ui/connection/connection_viewmodel.dart` -- ConnectionViewModel + ConnectionState
- `lib/ui/counter/counter_viewmodel.dart` -- CounterViewModel + CounterState
- `lib/routing/app_router.dart` -- minimal router (placeholder routes)
- `test/helpers/fakes.dart` -- FakeCounterRepository, FakeSettingsRepository
- `test/helpers/test_data.dart` -- test fixtures

### Screen Flow

```
App Launch
    |
    v
ConnectionScreen (/connect)
    | (connect button -> connected)
    v
CounterScreen (/counter) ---- (gear icon) ----> SettingsScreen (/settings)
    | (disconnect)                                    | (back)
    v                                                 v
ConnectionScreen                              CounterScreen
```

---

## Slice 10: ConnectionScreen

**Status:** pending

**Source:** `lib/ui/connection/connection_screen.dart`
**Tests:** `test/ui/connection/connection_screen_test.dart`

### Test 1: Displays endpoint text fields and connect button
Given: a ConnectionScreen is pumped with provider overrides (disconnected state)
When: the widget tree settles
Then: text fields for connect endpoint, listen endpoint, and key expression are found; a Connect button is found

### Test 2: Displays error message when in error state
Given: a ConnectionScreen pumped with ConnectionState(status: error, error: 'Connection refused')
When: the widget tree settles
Then: the text 'Connection refused' is displayed

### Test 3: Connect button triggers connect on viewmodel
Given: a ConnectionScreen in disconnected state with endpoint text entered
When: the Connect button is tapped
Then: the ConnectionViewModel.connect method is invoked (verified by state transition)

### Test 4: Navigates to /counter on successful connection
Given: a ConnectionScreen that transitions to connected state
When: the widget rebuilds after connection
Then: navigation to '/counter' occurs (verified via go_router or mock navigator)

### Edge Cases / Error Conditions

### Test 5: Connect button is disabled during connecting state
Given: a ConnectionScreen pumped with ConnectionState(status: connecting)
When: the widget tree settles
Then: the Connect button is disabled (not tappable)

### Test 6: Key expression defaults to demo/counter
Given: a ConnectionScreen in disconnected state
When: the widget tree settles
Then: the key expression field contains 'demo/counter'

### Acceptance Criteria
- [ ] All tests pass
- [ ] Uses ConsumerWidget
- [ ] Widget tests use ProviderScope.overrides only (no zenoh)
- [ ] `fvm flutter analyze` passes

### Phase Tracking

- **RED:** pending
- **GREEN:** pending
- **REFACTOR:** pending

**Depends on:** 6, 7, 8 | **Blocks:** 13

### UI Specification

- Text field: Connect endpoint (hint: `tcp/localhost:7447`)
- Text field: Listen endpoint (hint: `tcp/0.0.0.0:7447`)
- Text field: Key expression (default value: `demo/counter`)
- "Load saved" button (populates from SharedPreferences)
- "Connect" button (calls ConnectionViewModel.connect)
- Connection status indicator
- Error message display (red text)
- On successful connect -> navigate to `/counter`

### Widget Test Pattern

```dart
testWidgets('displays connect button', (tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        connectionViewModelProvider.overrideWith(
          () => FakeConnectionViewModel(),
        ),
      ],
      child: const MaterialApp(home: ConnectionScreen()),
    ),
  );
  expect(find.text('Connect'), findsOneWidget);
});
```

---

## Slice 11: CounterScreen

**Status:** pending

**Source:** `lib/ui/counter/counter_screen.dart`
**Tests:** `test/ui/counter/counter_screen_test.dart`

### Test 1: Displays counter value when state has a value
Given: a CounterScreen pumped with CounterState(value: 42, isSubscribed: true)
When: the widget tree settles
Then: the text '42' is displayed prominently

### Test 2: Displays waiting message when no value received
Given: a CounterScreen pumped with CounterState(value: null, isSubscribed: true)
When: the widget tree settles
Then: a waiting/placeholder message is displayed (e.g., 'Waiting for data...')

### Test 3: Displays last update timestamp
Given: a CounterScreen pumped with CounterState(value: 42, lastUpdate: fixedDateTime)
When: the widget tree settles
Then: the formatted timestamp is displayed

### Test 4: Disconnect button navigates to /connect
Given: a CounterScreen in connected state
When: the disconnect button is tapped
Then: navigation to '/connect' occurs

### Test 5: Settings icon navigates to /settings
Given: a CounterScreen in connected state
When: the gear/settings icon is tapped
Then: navigation to '/settings' occurs

### Edge Cases / Error Conditions

### Test 6: Counter screen shows connection status indicator
Given: a CounterScreen pumped with connected ConnectionState
When: the widget tree settles
Then: a connection status indicator (e.g., green dot) is visible

### Acceptance Criteria
- [ ] All tests pass
- [ ] Uses ConsumerWidget
- [ ] Large centered counter display
- [ ] Widget tests use ProviderScope.overrides only (no zenoh)
- [ ] `fvm flutter analyze` passes

### Phase Tracking

- **RED:** pending
- **GREEN:** pending
- **REFACTOR:** pending

**Depends on:** 6, 7, 8, 9 | **Blocks:** 13

### UI Specification

- Large centered counter value (prominent text style)
- "Last update" timestamp below the counter
- App bar with:
  - Connection status indicator (green dot when connected)
  - Gear icon -> navigate to `/settings`
- Disconnect button -> navigate to `/connect`
- Auto-starts subscription on screen entry via CounterViewModel.startListening()

---

## Slice 12: SettingsScreen and SettingsViewModel

**Status:** pending

**Source:** `lib/ui/settings/settings_screen.dart`, `lib/ui/settings/settings_viewmodel.dart`
**Tests:** `test/ui/settings/settings_screen_test.dart`, `test/ui/settings/settings_viewmodel_test.dart`

### Test 1: SettingsViewModel loads config on build
Given: a SettingsViewModel with a fake SettingsRepository returning a known config
When: the provider is read (async build completes)
Then: state is AsyncData with the loaded ConnectionConfig

### Test 2: SettingsViewModel.save persists and updates state
Given: a SettingsViewModel with a fake SettingsRepository
When: save is called with a new ConnectionConfig
Then: state becomes AsyncData with the new config; the fake repository received the save call

### Test 3: SettingsScreen displays loaded endpoint values
Given: a SettingsScreen pumped with AsyncData(ConnectionConfig(connectEndpoint: 'tcp/host:7447'))
When: the widget tree settles
Then: the connect endpoint field contains 'tcp/host:7447'

### Test 4: SettingsScreen save button persists config
Given: a SettingsScreen with endpoint fields filled in
When: the Save button is tapped
Then: the SettingsViewModel.save is invoked (verified by state update)

### Test 5: SettingsScreen reset button restores defaults
Given: a SettingsScreen with modified endpoint values
When: the Reset to defaults button is tapped
Then: fields show default values (empty endpoints, 'demo/counter')

### Edge Cases / Error Conditions

### Test 6: SettingsScreen shows loading indicator during async operations
Given: a SettingsScreen pumped with AsyncLoading state
When: the widget tree settles
Then: a CircularProgressIndicator is displayed

### Test 7: SettingsScreen shows error on load failure
Given: a SettingsScreen pumped with AsyncError state
When: the widget tree settles
Then: an error message is displayed

### Acceptance Criteria
- [ ] All tests pass
- [ ] SettingsViewModel uses AsyncNotifierProvider
- [ ] Widget tests use ProviderScope.overrides only
- [ ] `fvm flutter analyze` passes

### Phase Tracking

- **RED:** pending
- **GREEN:** pending
- **REFACTOR:** pending

**Depends on:** 1, 3, 5, 6, 7 | **Blocks:** 13

### Signatures

```dart
// lib/ui/settings/settings_viewmodel.dart

class SettingsViewModel extends AsyncNotifier<ConnectionConfig> {
  @override
  FutureOr<ConnectionConfig> build() async {
    return await ref.read(settingsRepositoryProvider).load();
  }

  Future<void> save(ConnectionConfig config) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(settingsRepositoryProvider).save(config);
      return config;
    });
  }
}
```

**Provider definition** (add to `lib/providers/providers.dart`):

```dart
final settingsViewModelProvider =
    AsyncNotifierProvider<SettingsViewModel, ConnectionConfig>(
  SettingsViewModel.new,
);
```

### UI Specification

- Text field: Connect endpoint (populated from loaded config)
- Text field: Listen endpoint (populated from loaded config)
- Text field: Key expression (populated from loaded config)
- "Save" button (persists to SharedPreferences via SettingsViewModel)
- "Reset to defaults" button (clears fields to defaults)
- Loading indicator during async operations
- Error message on failure
- Back navigation to CounterScreen

---

## What Happens Next

After this phase passes, Phase 6 (Navigation + Dev Script) wires up go_router
with all three screens and creates the dev script.
