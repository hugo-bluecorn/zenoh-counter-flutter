# zenoh-counter-flutter

Flutter subscriber app displaying real-time counter values received over [Zenoh](https://zenoh.io/). Runs on Linux desktop and Android.

## What This Is

A Flutter app that subscribes to an incrementing int64 counter published via Zenoh shared memory. It demonstrates `package:zenoh` working inside Flutter with cross-compiled native libraries, MVVM architecture, and real-time data delivery from a C++ publisher to a mobile device over WiFi.

```
C++ SHM publisher ──> zenohd router ──> WiFi ──> Pixel 9a Flutter app
```

This is the third of three template repos:

| Repo | Purpose | Status |
|------|---------|--------|
| [zenoh-counter-dart](https://github.com/hugo-bluecorn/zenoh-counter-dart) | Pure Dart CLI, validates package:zenoh + SHM | v0.1.1 |
| [zenoh-counter-cpp](https://github.com/hugo-bluecorn/zenoh-counter-cpp) | C++ SHM publisher, validates cross-language interop | v0.4.0 |
| **zenoh-counter-flutter** (this) | Flutter subscriber UI, validates mobile + desktop deployment | v0.7.0 |

## Architecture

MVVM with Riverpod 3.x (no codegen). Only `ZenohService` imports `package:zenoh` -- no FFI types leak into ViewModels or UI.

```
UI Layer (Flutter widgets)
  ConnectionScreen -> ConnectionViewModel
  CounterScreen    -> CounterViewModel
  SettingsScreen   -> SettingsViewModel

ViewModel Layer (Riverpod 3.x Notifiers)

Data Layer
  CounterRepository -> ZenohService -> package:zenoh
  SettingsRepository -> SharedPreferences
```

## Quick Start

### Prerequisites

- [FVM](https://fvm.app/) (Flutter Version Manager)
- [zenoh-counter-cpp](https://github.com/hugo-bluecorn/zenoh-counter-cpp) built (provides the publisher)
- Native libraries built from [zenoh_dart](https://github.com/hugo-bluecorn/zenoh_dart)

### Desktop (Linux)

```bash
# Terminal 1: Start C++ publisher
./scripts/dev.sh

# Terminal 2: Run Flutter app
fvm flutter run -d linux
# Enter endpoint: tcp/localhost:7447
```

### Android

Requires zenohd router on the host and a WiFi connection between host and device:

```bash
# Terminal 1: Start router + publisher
./scripts/dev.sh --router

# Terminal 2: Run Flutter app on device
fvm flutter run -d <device-id>
# Enter endpoint: tcp/<host-ip>:7447
```

## Network Topologies

### Desktop -- Peer Mode

C++ publisher listens, Flutter subscriber connects directly. No router needed.

```
C++ pub (-l tcp/0.0.0.0:7447) <--- TCP ---> Flutter sub (-e tcp/localhost:7447)
```

### Android -- Router Mode

Android lacks reliable UDP multicast. The Flutter app connects to zenohd in client mode via TCP over WiFi.

```
zenohd (:7447) <--- TCP ---> C++ pub (-e tcp/localhost:7447)
    ^
    |--- WiFi (TCP) ---> Flutter sub (-e tcp/<host-ip>:7447)
```

## Counter Protocol

| Property | Value |
|----------|-------|
| Key expression | `demo/counter` (default, configurable) |
| Payload format | Raw int64, little-endian (8 bytes) |
| Publish interval | 1000ms (C++ side) |
| Transport | SHM zero-copy (transparent to subscribers) |

Binary-compatible with zenoh-counter-dart and zenoh-counter-cpp.

## Testing

```bash
# Widget tests (no zenoh needed)
fvm flutter test

# Integration tests (requires C++ publisher running)
fvm flutter test integration_test/
```

## Dependencies

- [package:zenoh](https://github.com/hugo-bluecorn/zenoh_dart) -- Dart FFI bindings for zenoh-c v1.7.2
- [flutter_riverpod](https://pub.dev/packages/flutter_riverpod) ^3.3.1 -- state management
- [go_router](https://pub.dev/packages/go_router) ^17.1.0 -- navigation
- [shared_preferences](https://pub.dev/packages/shared_preferences) ^2.5.4 -- endpoint persistence

## License

Apache 2.0 -- see [LICENSE](LICENSE).
