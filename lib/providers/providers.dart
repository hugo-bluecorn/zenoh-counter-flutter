import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zenoh_counter_flutter/data/repositories/counter_repository.dart';
import 'package:zenoh_counter_flutter/data/repositories/counter_repository_impl.dart';
import 'package:zenoh_counter_flutter/data/repositories/settings_repository.dart';
import 'package:zenoh_counter_flutter/data/repositories/settings_repository_impl.dart';
import 'package:zenoh_counter_flutter/data/services/zenoh_service.dart';
import 'package:zenoh_counter_flutter/ui/connection/connection_viewmodel.dart';

// --- Infrastructure ---

/// Must be overridden in `main()` with the real instance.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) {
    throw UnimplementedError('Override in main()');
  },
);

/// Creates and owns a [ZenohService], disposing on teardown.
final zenohServiceProvider = Provider<ZenohService>((ref) {
  final service = ZenohService();
  ref.onDispose(service.dispose);
  return service;
});

// --- Repositories ---

/// Settings repository backed by [SharedPreferences].
final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) {
    final prefs = ref.watch(sharedPreferencesProvider);
    return SettingsRepositoryImpl(prefs);
  },
);

/// Counter repository backed by [ZenohService].
final counterRepositoryProvider = Provider<CounterRepository>(
  (ref) {
    final service = ref.watch(zenohServiceProvider);
    final repo = CounterRepositoryImpl(service);
    ref.onDispose(repo.dispose);
    return repo;
  },
);

// --- ViewModels ---

/// Connection lifecycle ViewModel.
final connectionViewModelProvider = NotifierProvider<
    ConnectionViewModel, ConnectionState>(
  ConnectionViewModel.new,
);
