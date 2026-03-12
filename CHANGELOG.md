# CHANGELOG

## [0.2.0] - 2026-03-12

### Added
- CounterValue and ConnectionConfig immutable data models
- ZenohService: sole `package:zenoh` boundary with connect,
  subscribe (Stream<Uint8List>), and dispose
- Native library loading validated in Flutter test runner
  (GATE passed — symlink fallback for Isolate.resolvePackageUriSync
  limitation)
- Integration tests with two-session TCP pub/sub pattern
- 10 tests (4 model unit + 6 ZenohService integration)
