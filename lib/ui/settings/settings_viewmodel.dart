import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:zenoh_counter_flutter/data/models/connection_config.dart';
import 'package:zenoh_counter_flutter/providers/providers.dart';

/// Manages settings persistence via the settings repository.
class SettingsViewModel extends AsyncNotifier<ConnectionConfig> {
  @override
  FutureOr<ConnectionConfig> build() async {
    return ref.read(settingsRepositoryProvider).load();
  }

  /// Saves the given [config] to the settings repository.
  Future<void> save(ConnectionConfig config) async {
    state = const AsyncLoading<ConnectionConfig>();
    state = await AsyncValue.guard(() async {
      await ref.read(settingsRepositoryProvider).save(config);
      return config;
    });
  }
}
