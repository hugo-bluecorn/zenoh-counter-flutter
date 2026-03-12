import 'package:shared_preferences/shared_preferences.dart';
import 'package:zenoh_counter_flutter/data/models/connection_config.dart';
import 'package:zenoh_counter_flutter/data/repositories/settings_repository.dart';

/// [SettingsRepository] backed by [SharedPreferences].
class SettingsRepositoryImpl implements SettingsRepository {
  /// Creates a repository with the given [SharedPreferences].
  SettingsRepositoryImpl(this._prefs);

  final SharedPreferences _prefs;

  static const _connectKey = 'connect_endpoint';
  static const _listenKey = 'listen_endpoint';
  static const _keyExprKey = 'key_expr';

  @override
  Future<ConnectionConfig> load() async {
    return ConnectionConfig(
      connectEndpoint:
          _prefs.getString(_connectKey) ?? '',
      listenEndpoint:
          _prefs.getString(_listenKey) ?? '',
      keyExpr:
          _prefs.getString(_keyExprKey) ?? 'demo/counter',
    );
  }

  @override
  Future<void> save(ConnectionConfig config) async {
    await _prefs.setString(
      _connectKey,
      config.connectEndpoint,
    );
    await _prefs.setString(
      _listenKey,
      config.listenEndpoint,
    );
    await _prefs.setString(
      _keyExprKey,
      config.keyExpr,
    );
  }
}
