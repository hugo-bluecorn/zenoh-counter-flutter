import 'package:zenoh_counter_flutter/data/models/connection_config.dart';

/// Abstract interface for persisting connection settings.
abstract class SettingsRepository {
  /// Loads the saved [ConnectionConfig], or defaults if none.
  Future<ConnectionConfig> load();

  /// Persists the given [ConnectionConfig].
  Future<void> save(ConnectionConfig config);
}
