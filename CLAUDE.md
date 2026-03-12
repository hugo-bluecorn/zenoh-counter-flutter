# CLAUDE.md

This file provides guidance to Claude Code when working with this repository.

## Project Overview

Flutter subscriber app displaying real-time counter values received from the `zenoh-counter-cpp` SHM publisher. This is the third of three template repos:

1. **zenoh-counter-dart** (COMPLETE) -- Pure Dart CLI, validates package:zenoh + SHM
2. **zenoh-counter-cpp** (COMPLETE) -- C++ SHM publisher, validates cross-language interop
3. **zenoh-counter-flutter** (this repo) -- Flutter subscriber UI, validates mobile + desktop deployment

This is a **reference architecture**, not just a counter app. It proves:

- `package:zenoh` works in Flutter (desktop + Android)
- MVVM layering with zenoh as a real-time data source
- Android deployment with cross-compiled native libraries
- Cross-device interop (desktop C++ pub -> Android Flutter sub via zenohd)

## Project Structure

```
zenoh-counter-flutter/
  lib/
    main.dart                          # ProviderScope + runApp
    app.dart                           # MaterialApp.router + theme
    ui/
      core/
        themes/
          app_theme.dart               # App-wide theme
        widgets/                       # Reusable widgets
      connection/
        connection_screen.dart         # Endpoint entry + connect
        connection_viewmodel.dart      # Connection lifecycle
      counter/
        counter_screen.dart            # Real-time counter display
        counter_viewmodel.dart         # Subscription + decode
      settings/
        settings_screen.dart           # Endpoint config (persisted)
        settings_viewmodel.dart        # SharedPreferences access
    data/
      repositories/
        counter_repository.dart        # Abstract interface
        counter_repository_impl.dart   # ZenohService consumer
        settings_repository.dart       # Abstract interface
        settings_repository_impl.dart  # SharedPreferences
      services/
        zenoh_service.dart             # THE zenoh boundary
      models/
        connection_config.dart         # Endpoints + key expr
        counter_value.dart             # Value + timestamp
    providers/
      providers.dart                   # All Riverpod providers
    routing/
      app_router.dart                  # go_router config
  test/
    ui/                                # Widget tests
    data/                              # Integration tests
    helpers/                           # Shared fixtures
  integration_test/                    # Full E2E flow
  scripts/
    dev.sh                             # Start C++ pub for local dev
  context/
    roles/                             # CA/CP/CI session prompts
  docs/
    design/                            # Design spec
  android/                             # Android platform (Flutter-managed)
  linux/                               # Linux platform (Flutter-managed)
```

## Architecture -- MVVM with Riverpod 3.x

### Layer Diagram

```
UI Layer (organized by feature)
  ConnectionScreen <- ConnectionViewModel
  CounterScreen    <- CounterViewModel
  SettingsScreen   <- SettingsViewModel

ViewModel Layer (Riverpod 3.x Notifiers)
  NotifierProvider / AsyncNotifierProvider
  No codegen -- manual provider definitions

Data Layer (organized by type)
  CounterRepository (abstract -> impl)
  SettingsRepository (abstract -> impl)
  ZenohService (wraps package:zenoh)

package:zenoh (external dependency)
  Session, Subscriber, Sample, Config, etc.
```

**Key rule:** Only `ZenohService` imports `package:zenoh` (in `lib/`).
`ZenohService.subscribe()` returns `Stream<Uint8List>` -- no zenoh types leak.
ViewModels never touch FFI types. The UI receives plain Dart types (`int`,
`String`, `DateTime`, enums). Test files MAY import `package:zenoh` directly
for two-session integration tests.

### Counter Protocol (defined by zenoh-counter-cpp)

| Property | Value |
|----------|-------|
| Key expression | `demo/counter` (default, configurable) |
| Payload format | Raw int64, little-endian (8 bytes) |
| Publish interval | 1000ms (C++ side) |
| Transport | SHM zero-copy (transparent to subscribers) |

**Decoding in Dart:**
```dart
// ZenohService.subscribe() returns Stream<Uint8List> (payloadBytes extracted)
// CounterRepositoryImpl decodes the raw bytes:
final value = bytes.buffer.asByteData().getInt64(0, Endian.little);
```

## Dependencies

### package:zenoh (path dependency)

```yaml
dependencies:
  zenoh:
    path: ../zenoh_dart/packages/zenoh
```

The zenoh package provides: Session, Subscriber, Sample, Config, Zenoh,
KeyExpr, ZBytes, ZenohException, and related types.

### zenoh-dart Reference (upstream repo)

The zenoh-dart monorepo at `/home/hugo-bluecorn/bluecorn/CSR/git/zenoh_dart/`
is the source of truth for the zenoh Dart API. When planning or implementing,
consult:

| What | Where |
|------|-------|
| Dart API source | `packages/zenoh/lib/src/*.dart` |
| Subscribe example | `packages/zenoh/example/z_sub.dart` |
| Integration tests | `packages/zenoh/test/*.dart` |
| C shim source | `src/zenoh_dart.{h,c}` |
| Project conventions | `CLAUDE.md` |

### Native Libraries Required

Two native shared libraries are required at runtime:
- `libzenoh_dart.so` -- C shim (built from zenoh-dart's `src/`)
- `libzenohc.so` -- zenoh-c runtime (built from zenoh-dart's `extern/zenoh-c/`)

These are registered via build hooks in the upstream `package:zenoh`. Runtime
loading uses `DynamicLibrary.open()` with path resolution via
`Isolate.resolvePackageUriSync()`. No `LD_LIBRARY_PATH` is needed for pure
Dart consumers.

**Flutter integration is untested** -- build hooks may behave differently in
Flutter's build pipeline. If hooks don't bundle correctly, fallback to manual
native lib placement in platform directories.

### zenoh-counter-cpp Reference (companion publisher)

The C++ SHM publisher at `/home/hugo-bluecorn/bluecorn/CSR/git/zenoh-counter-cpp/`
provides the counter data stream. It publishes int64 LE values on `demo/counter`
via SHM zero-copy. CLI flags: `-k`, `-e`, `-l`, `-i`.

## FVM Requirement

**Dart and Flutter are NOT on PATH.** All commands must use `fvm`:

```bash
fvm flutter ...
fvm dart ...
fvm flutter run -d linux
fvm flutter test
fvm flutter analyze
```

## Build & Run

### Desktop (Linux)

```bash
# Terminal 1: Start C++ publisher (from zenoh-counter-cpp)
./build/counter_pub -l tcp/0.0.0.0:7447

# Terminal 2: Run Flutter app
fvm flutter run -d linux
# Enter endpoint: tcp/localhost:7447
```

Or use the dev script:
```bash
# Terminal 1: Start publisher
./scripts/dev.sh

# Terminal 2: Run Flutter app
fvm flutter run -d linux
```

### Android

Requires zenohd router on the host:
```bash
# Terminal 1: Start router + publisher
./scripts/dev.sh --router

# Terminal 2: Run Flutter app on device
fvm flutter run -d <device-id>
# Enter endpoint: tcp://<host-ip>:7447
```

### Testing

```bash
# Widget tests (no zenoh needed)
fvm flutter test

# Integration tests (requires C++ publisher running)
fvm flutter test integration_test/
```

### Analysis

```bash
fvm flutter analyze
```

## Network Topologies

### Desktop -- Peer Mode

C++ publisher listens, Flutter subscriber connects. No router needed.

```
C++ pub (-l tcp/0.0.0.0:7447) <--- TCP ---> Flutter sub (-e tcp/localhost:7447)
```

### Android -- Router Mode

Android has no reliable UDP multicast. Flutter app connects to zenohd
in client mode via TCP. User enters endpoint in settings screen.

```
zenohd (:7447) <--- TCP ---> C++ pub (-e tcp/localhost:7447)
    ^
    |--- WiFi (TCP) ---> Flutter sub (-e tcp://<host-ip>:7447)
```

## State Management -- Riverpod 3.x

- **flutter_riverpod: ^3.3.1** -- no codegen
- **No** `riverpod_annotation`, `riverpod_generator`, or `build_runner`
- Manual `NotifierProvider` / `AsyncNotifierProvider` definitions
- `ConsumerWidget` for reactive UI
- `ref.watch()` for rebuilds, `ref.read()` for one-shot access
- `ref.mounted` check after every `await`
- `ref.onDispose()` for cleanup

### Provider Types Used

| Provider | Use Case |
|----------|----------|
| `NotifierProvider` | ConnectionViewModel, CounterViewModel (sync mutable state) |
| `AsyncNotifierProvider` | SettingsViewModel (async SharedPreferences) |
| `Provider` | ZenohService, repositories (DI singletons) |
| `StreamProvider` | Not used -- counter stream managed by ViewModel |

## Navigation -- go_router

Three routes:
- `/connect` -- connection screen (initial)
- `/counter` -- counter display (after connect)
- `/settings` -- endpoint configuration

## Linting

Uses `very_good_analysis` (configured in `analysis_options.yaml`).

```bash
fvm flutter analyze
```

## Code Quality Rules

- Functions < 20 lines (single responsibility)
- Line length: 80 characters max
- No files exceed 400 lines
- PascalCase for classes, camelCase for members/variables/functions/enums
- snake_case for files and directories
- Sound null safety -- avoid `!` unless guaranteed non-null
- Use `dart:developer` log function, NOT `print`
- One class per file (exceptions for tightly coupled classes)

## Import Organization

```dart
// 1. Dart SDK imports
import 'dart:async';

// 2. Package imports (alphabetical)
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// 3. Local project imports (alphabetical)
import 'package:zenoh_counter_flutter/data/services/zenoh_service.dart';
```

## Commit Scope Naming

Use the primary module as `<scope>` in commit messages:
- `feat(connection): ...` for connection screen/viewmodel
- `feat(counter): ...` for counter screen/viewmodel
- `feat(settings): ...` for settings screen/viewmodel
- `feat(zenoh): ...` for ZenohService
- `feat(repo): ...` for repositories
- `test(counter): ...` for counter tests
- `docs: ...` for documentation changes
- `chore: ...` for build, deps, config changes

## Session Roles

This project uses a three-session workflow:

| Session | Role | Scope |
|---------|------|-------|
| **CA** | Architect / Reviewer | Decisions, reviews, memory |
| **CP** | Planner | Slice decomposition, TDD plans |
| **CI** | Implementer | Code, tests, releases |

Role prompts are in `context/roles/`. Each session reads its role doc
before starting.

## TDD Workflow Plugin

This project uses the **tdd-workflow** Claude Code plugin for structured
test-driven development.

### Available Commands

- **`/tdd-plan <feature description>`** -- Create a TDD implementation plan
- **`/tdd-implement`** -- Start or resume TDD implementation for pending slices
- **`/tdd-release`** -- Finalize and release a completed TDD feature

### Session State

If `.tdd-progress.md` exists at the project root, a TDD session is in progress.
Read it to understand the current state before making changes.

### Testing Constraints

- Widget tests use Riverpod `ProviderScope.overrides` -- no zenoh needed
- Integration tests use real zenoh sessions -- no mocking of FFI layer
- Two-session testing: use explicit TCP listen/connect with unique ports
- All test commands via `fvm flutter test`
- Native libraries resolved via build hooks (no `LD_LIBRARY_PATH`)
- `Subscriber.stream` is single-subscription (non-broadcast)
- Session, Subscriber have idempotent close

### zenoh-dart API Reference (Phase 5)

Available classes from `package:zenoh`:
- `Zenoh` -- `initLog(level)` for logger initialization
- `Config` -- `insertJson5(key, value)` for session configuration
- `Session` -- `open(config:)`, `declareSubscriber()`, `close()`
- `Subscriber` -- `stream` (Stream<Sample>), `close()`
- `Sample` -- `keyExpr`, `payload` (String), `payloadBytes` (Uint8List), `kind`, `encoding`
- `SampleKind` -- `put`, `delete`
- `ZBytes` -- binary payload container
- `KeyExpr` -- key expression validation
- `ZenohException` -- error type

### Session Directives

When /tdd-plan completes, always show the FULL plan text produced by the planner
agent -- every slice with Given/When/Then, acceptance criteria, and dependencies.
Never summarize or abbreviate the plan output.
