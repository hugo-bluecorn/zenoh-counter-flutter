# CHANGELOG
## [0.6.0] - 2026-03-12

### Added
- ConnectionScreen: endpoint text fields (connect, listen,
  key expression), connect button with disabled state during
  connecting, error display, navigation to /counter on success
- CounterScreen: large centered counter display, last update
  timestamp, connection status indicator, settings icon
  navigation, disconnect button
- SettingsScreen: endpoint config fields populated from saved
  config, Save and Reset to defaults buttons, loading indicator
  and error state display
- SettingsViewModel: AsyncNotifier loading/saving ConnectionConfig
  via SettingsRepository, settingsViewModelProvider added to
  providers
- 19 new widget/unit tests (6 ConnectionScreen + 6 CounterScreen
  + 5 SettingsScreen + 2 SettingsViewModel) using
  ProviderScope.overrides with fakes

## [0.5.0] - 2026-03-12

### Added
- App shell: ProviderScope + MaterialApp.router with
  Material 3 theme, go_router with placeholder routes
- ConnectionViewModel: connect/disconnect lifecycle
  with status enum (disconnected, connecting, connected,
  error) via NotifierProvider
- CounterViewModel: stream subscription management
  with startListening/stopListening, state updates
  from CounterRepository, StreamSubscription disposal
  via ref.onDispose
- 13 new tests (3 app shell + 5 ConnectionViewModel
  + 5 CounterViewModel) using ProviderContainer
  with fake repositories

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
