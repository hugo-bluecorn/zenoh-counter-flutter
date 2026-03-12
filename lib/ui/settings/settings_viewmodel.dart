import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:zenoh_counter_flutter/data/models/connection_config.dart';

/// Manages settings persistence via the settings repository.
class SettingsViewModel extends AsyncNotifier<ConnectionConfig> {
  @override
  FutureOr<ConnectionConfig> build() {
    throw UnimplementedError();
  }

  /// Saves the given [config] to the settings repository.
  Future<void> save(ConnectionConfig config) async {
    throw UnimplementedError();
  }
}
