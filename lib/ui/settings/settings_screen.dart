import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:zenoh_counter_flutter/data/models/connection_config.dart';
import 'package:zenoh_counter_flutter/providers/providers.dart';

/// Settings screen for configuring connection endpoints.
class SettingsScreen extends ConsumerStatefulWidget {
  /// Creates a [SettingsScreen].
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _connectCtrl = TextEditingController();
  final _listenCtrl = TextEditingController();
  final _keyExprCtrl = TextEditingController();

  @override
  void dispose() {
    _connectCtrl.dispose();
    _listenCtrl.dispose();
    _keyExprCtrl.dispose();
    super.dispose();
  }

  void _populateFields(ConnectionConfig config) {
    _connectCtrl.text = config.connectEndpoint;
    _listenCtrl.text = config.listenEndpoint;
    _keyExprCtrl.text = config.keyExpr;
  }

  void _onSave() {
    final config = ConnectionConfig(
      connectEndpoint: _connectCtrl.text,
      listenEndpoint: _listenCtrl.text,
      keyExpr: _keyExprCtrl.text,
    );
    unawaited(
      ref.read(settingsViewModelProvider.notifier).save(config),
    );
  }

  void _onReset() {
    const defaults = ConnectionConfig();
    _populateFields(defaults);
  }

  @override
  Widget build(BuildContext context) {
    final asyncState = ref.watch(settingsViewModelProvider);

    ref.listen<AsyncValue<ConnectionConfig>>(
      settingsViewModelProvider,
      (prev, next) {
        if (next is AsyncData<ConnectionConfig>) {
          _populateFields(next.value);
        }
      },
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: asyncState.when(
        loading: _buildLoading,
        error: _buildError,
        data: _buildForm,
      ),
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  Widget _buildError(Object error, StackTrace stack) {
    return Center(child: Text('Error: $error'));
  }

  Widget _buildForm(ConnectionConfig config) {
    if (_connectCtrl.text.isEmpty &&
        _listenCtrl.text.isEmpty &&
        _keyExprCtrl.text == '') {
      _populateFields(config);
    }
    return _SettingsForm(
      connectCtrl: _connectCtrl,
      listenCtrl: _listenCtrl,
      keyExprCtrl: _keyExprCtrl,
      onSave: _onSave,
      onReset: _onReset,
    );
  }
}

class _SettingsForm extends StatelessWidget {
  const _SettingsForm({
    required this.connectCtrl,
    required this.listenCtrl,
    required this.keyExprCtrl,
    required this.onSave,
    required this.onReset,
  });

  final TextEditingController connectCtrl;
  final TextEditingController listenCtrl;
  final TextEditingController keyExprCtrl;
  final VoidCallback onSave;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            controller: connectCtrl,
            decoration: const InputDecoration(
              labelText: 'Connect endpoint',
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: listenCtrl,
            decoration: const InputDecoration(
              labelText: 'Listen endpoint',
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: keyExprCtrl,
            decoration: const InputDecoration(
              labelText: 'Key expression',
            ),
          ),
          const SizedBox(height: 24),
          _SettingsButtons(
            onSave: onSave,
            onReset: onReset,
          ),
        ],
      ),
    );
  }
}

class _SettingsButtons extends StatelessWidget {
  const _SettingsButtons({
    required this.onSave,
    required this.onReset,
  });

  final VoidCallback onSave;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        ElevatedButton(
          onPressed: onSave,
          child: const Text('Save'),
        ),
        TextButton(
          onPressed: onReset,
          child: const Text('Reset to defaults'),
        ),
      ],
    );
  }
}
