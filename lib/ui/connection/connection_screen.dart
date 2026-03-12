import 'package:flutter/material.dart' hide ConnectionState;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:zenoh_counter_flutter/data/models/connection_config.dart';
import 'package:zenoh_counter_flutter/providers/providers.dart';
import 'package:zenoh_counter_flutter/ui/connection/connection_viewmodel.dart';

/// Screen for entering zenoh connection details and connecting.
class ConnectionScreen extends ConsumerStatefulWidget {
  /// Creates a [ConnectionScreen].
  const ConnectionScreen({super.key});

  @override
  ConsumerState<ConnectionScreen> createState() =>
      _ConnectionScreenState();
}

class _ConnectionScreenState
    extends ConsumerState<ConnectionScreen> {
  late final TextEditingController _connectCtrl;
  late final TextEditingController _listenCtrl;
  late final TextEditingController _keyExprCtrl;

  @override
  void initState() {
    super.initState();
    _connectCtrl = TextEditingController();
    _listenCtrl = TextEditingController();
    _keyExprCtrl = TextEditingController(
      text: 'demo/counter',
    );
  }

  @override
  void dispose() {
    _connectCtrl.dispose();
    _listenCtrl.dispose();
    _keyExprCtrl.dispose();
    super.dispose();
  }

  void _onConnect() {
    final config = ConnectionConfig(
      connectEndpoint: _connectCtrl.text,
      listenEndpoint: _listenCtrl.text,
      keyExpr: _keyExprCtrl.text,
    );
    ref
        .read(connectionViewModelProvider.notifier)
        .connect(config);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(connectionViewModelProvider);

    ref.listen<ConnectionState>(
      connectionViewModelProvider,
      (previous, next) {
        if (next.status == ConnectionStatus.connected) {
          context.go('/counter');
        }
      },
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Connect')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _EndpointField(
              controller: _connectCtrl,
              label: 'Connect endpoint',
              hint: 'tcp/localhost:7447',
            ),
            const SizedBox(height: 12),
            _EndpointField(
              controller: _listenCtrl,
              label: 'Listen endpoint',
              hint: 'tcp/0.0.0.0:7447',
            ),
            const SizedBox(height: 12),
            _EndpointField(
              controller: _keyExprCtrl,
              label: 'Key expression',
            ),
            const SizedBox(height: 24),
            _ConnectButton(
              status: state.status,
              onPressed: _onConnect,
            ),
            if (state.error != null) ...[
              const SizedBox(height: 16),
              _ErrorText(message: state.error!),
            ],
          ],
        ),
      ),
    );
  }
}

class _EndpointField extends StatelessWidget {
  const _EndpointField({
    required this.controller,
    required this.label,
    this.hint,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
      ),
    );
  }
}

class _ConnectButton extends StatelessWidget {
  const _ConnectButton({
    required this.status,
    required this.onPressed,
  });

  final ConnectionStatus status;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final isDisabled =
        status == ConnectionStatus.connecting;
    return ElevatedButton(
      onPressed: isDisabled ? null : onPressed,
      child: const Text('Connect'),
    );
  }
}

class _ErrorText extends StatelessWidget {
  const _ErrorText({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Text(
      message,
      style: const TextStyle(color: Colors.red),
    );
  }
}
