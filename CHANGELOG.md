# CHANGELOG
## [0.4.0] - 2026-03-12

### Added
- Riverpod provider definitions: sharedPreferencesProvider,
  zenohServiceProvider, settingsRepositoryProvider,
  counterRepositoryProvider (with onDispose cleanup)
- Test fakes: FakeCounterRepository (broadcast stream
  with emit helper), FakeSettingsRepository (in-memory)
- Test fixtures: testTimestamp, testCounterValue, testConfig
- 5 provider tests (resolution, disposal, error on
  missing override)


## [0.3.0] - 2026-03-12

### Added
- SettingsRepository: persists ConnectionConfig via
  SharedPreferences (load/save with defaults)
- CounterRepository: decodes Stream<Uint8List> into
  Stream<CounterValue> via broadcast StreamController
- Abstract interfaces for both repositories (separated
  from implementations)
- 8 new tests (4 SettingsRepository unit + 4
  CounterRepository integration with two-session TCP)

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
