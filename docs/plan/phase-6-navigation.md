# Phase 6: Navigation + Dev Script (Slices 13-14)

**Slices:** 13 (Navigation / go_router), 14 (Dev Script)
**Depends on:** Phase 5 (all screens passing)
**Exit criteria:** Routes wired. dev.sh executable. `fvm flutter analyze` clean
across entire project.

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

### Import Organization

```dart
// 1. Dart SDK imports
import 'dart:async';

// 2. Package imports (alphabetical)
import 'package:go_router/go_router.dart';

// 3. Local project imports (alphabetical)
import 'package:zenoh_counter_flutter/ui/connection/connection_screen.dart';
```

### What Exists After Phases 1-5

- `lib/data/` -- models, services, repositories (complete)
- `lib/providers/providers.dart` -- all providers (complete)
- `lib/main.dart`, `lib/app.dart` -- app shell (complete)
- `lib/ui/core/themes/app_theme.dart` -- Material 3 theme
- `lib/ui/connection/` -- ConnectionScreen + ConnectionViewModel
- `lib/ui/counter/` -- CounterScreen + CounterViewModel
- `lib/ui/settings/` -- SettingsScreen + SettingsViewModel
- `lib/routing/app_router.dart` -- minimal/placeholder router
- `test/` -- all unit and widget tests passing

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

## Slice 13: Navigation (go_router)

**Status:** pending

**Source:** `lib/routing/app_router.dart`
**Tests:** `test/routing/app_router_test.dart`

### Test 1: Initial location is /connect
Given: a GoRouter created from routerProvider
When: the router is initialized
Then: the initial location is '/connect'

### Test 2: /connect route builds ConnectionScreen
Given: a GoRouter from routerProvider
When: navigating to '/connect'
Then: ConnectionScreen widget is in the tree

### Test 3: /counter route builds CounterScreen
Given: a GoRouter from routerProvider
When: navigating to '/counter'
Then: CounterScreen widget is in the tree

### Test 4: /settings route builds SettingsScreen
Given: a GoRouter from routerProvider
When: navigating to '/settings'
Then: SettingsScreen widget is in the tree

### Edge Cases / Error Conditions

### Test 5: Unknown route does not crash
Given: a GoRouter from routerProvider
When: navigating to '/unknown'
Then: the app does not crash; either redirects or shows error page

### Acceptance Criteria
- [ ] All tests pass
- [ ] routerProvider is a Provider<GoRouter>
- [ ] Three routes defined (/connect, /counter, /settings)
- [ ] `fvm flutter analyze` passes

### Phase Tracking

- **RED:** pending
- **GREEN:** pending
- **REFACTOR:** pending

**Depends on:** 6, 7 | **Blocks:** none

### Signatures

```dart
// lib/routing/app_router.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/connect',
    routes: [
      GoRoute(
        path: '/connect',
        builder: (context, state) => const ConnectionScreen(),
      ),
      GoRoute(
        path: '/counter',
        builder: (context, state) => const CounterScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
    ],
  );
});
```

**Note:** A minimal/placeholder version of this file may already exist from
Phase 4. This slice replaces it with the final implementation and adds tests.

### Testing Pattern

Widget tests for routing need to wrap in a ProviderScope with all required
overrides (ViewModels, repositories) since navigating to a route will
instantiate the screen widget.

```dart
testWidgets('/connect route builds ConnectionScreen', (tester) async {
  final router = GoRouter(
    initialLocation: '/connect',
    routes: [
      GoRoute(
        path: '/connect',
        builder: (_, __) => const ConnectionScreen(),
      ),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        connectionViewModelProvider.overrideWith(
          () => FakeConnectionViewModel(),
        ),
        // ... other overrides as needed
      ],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  expect(find.byType(ConnectionScreen), findsOneWidget);
});
```

---

## Slice 14: Dev Script

**Status:** pending

**Source:** `scripts/dev.sh`
**Tests:** (manual verification -- no automated test)

### Acceptance Criteria
- [ ] `scripts/dev.sh` exists and is executable
- [ ] Default mode starts C++ publisher with `-l tcp/0.0.0.0:7447`
- [ ] `--router` mode starts zenohd then publisher in client mode
- [ ] Script references configurable paths via environment variables
- [ ] `shellcheck scripts/dev.sh` passes (if shellcheck available)

### Phase Tracking

- **RED:** pending (N/A -- no tests)
- **GREEN:** pending
- **REFACTOR:** pending

**Depends on:** none | **Blocks:** none

### Script Content

```bash
#!/bin/bash
# Start the C++ counter publisher for local Flutter development.
#
# Usage:
#   ./scripts/dev.sh                          # peer mode (desktop)
#   ./scripts/dev.sh --router                 # start zenohd + client mode
#   ./scripts/dev.sh --router --ip 192.168.x  # router on specific IP

ZENOH_COUNTER_CPP="${ZENOH_COUNTER_CPP:-../zenoh-counter-cpp}"
ZENOH_DART="${ZENOH_DART:-../zenoh_dart}"

case "$1" in
  --router)
    echo "Starting zenohd router..."
    "${ZENOH_DART}/extern/zenoh/target/release/zenohd" &
    ROUTER_PID=$!
    sleep 1
    echo "Starting C++ counter publisher (client mode)..."
    "${ZENOH_COUNTER_CPP}/build/counter_pub" -e tcp/localhost:7447
    kill $ROUTER_PID 2>/dev/null
    ;;
  *)
    echo "Starting C++ counter publisher (peer mode, listen)..."
    "${ZENOH_COUNTER_CPP}/build/counter_pub" -l tcp/0.0.0.0:7447
    ;;
esac
```

---

## Final Verification

After both slices pass, run the full project verification:

```bash
# All tests pass
fvm flutter test

# Zero analysis issues
fvm flutter analyze
```

### Full Acceptance Criteria (project-wide)

- [ ] All widget tests pass via `fvm flutter test`
- [ ] Code follows `very_good_analysis` style guidelines
- [ ] No static analysis errors (`fvm flutter analyze`)
- [ ] Only ZenohService imports `package:zenoh` (in `lib/`)
- [ ] MVVM layering enforced via Riverpod providers
- [ ] Three routes wired (/connect, /counter, /settings)
- [ ] Dev script executable and shellcheck-clean

## What Happens Next

This is the final phase. After it passes, the project is ready for
`/tdd-release` to finalize the feature: CHANGELOG, push, PR.
