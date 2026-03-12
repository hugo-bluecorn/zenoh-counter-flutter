import 'package:flutter/material.dart' hide ConnectionState;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:zenoh_counter_flutter/providers/providers.dart';
import 'package:zenoh_counter_flutter/ui/connection/connection_viewmodel.dart';
import 'package:zenoh_counter_flutter/ui/counter/counter_viewmodel.dart';

/// Screen displaying real-time counter values from zenoh.
class CounterScreen extends ConsumerStatefulWidget {
  /// Creates a [CounterScreen].
  const CounterScreen({super.key});

  @override
  ConsumerState<CounterScreen> createState() => _CounterScreenState();
}

class _CounterScreenState extends ConsumerState<CounterScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(counterViewModelProvider.notifier).startListening();
    });
  }

  void _onDisconnect() {
    ref.read(connectionViewModelProvider.notifier).disconnect();
    context.go('/connect');
  }

  @override
  Widget build(BuildContext context) {
    final counterState = ref.watch(counterViewModelProvider);
    final connState = ref.watch(connectionViewModelProvider);

    return Scaffold(
      appBar: _CounterAppBar(
        connStatus: connState.status,
        onSettings: () => context.go('/settings'),
      ),
      body: _CounterBody(
        state: counterState,
        onDisconnect: _onDisconnect,
      ),
    );
  }
}

class _CounterAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _CounterAppBar({
    required this.connStatus,
    required this.onSettings,
  });

  final ConnectionStatus connStatus;
  final VoidCallback onSettings;

  @override
  Size get preferredSize => const Size.fromHeight(
    kToolbarHeight,
  );

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: const Text('Counter'),
      actions: [
        _ConnectionIndicator(status: connStatus),
        IconButton(
          icon: const Icon(Icons.settings),
          onPressed: onSettings,
        ),
      ],
    );
  }
}

class _ConnectionIndicator extends StatelessWidget {
  const _ConnectionIndicator({required this.status});

  final ConnectionStatus status;

  @override
  Widget build(BuildContext context) {
    final color = status == ConnectionStatus.connected
        ? Colors.green
        : Colors.grey;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Icon(
        Icons.circle,
        color: color,
        size: 12,
      ),
    );
  }
}

class _CounterBody extends StatelessWidget {
  const _CounterBody({
    required this.state,
    required this.onDisconnect,
  });

  final CounterState state;
  final VoidCallback onDisconnect;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _CounterDisplay(state: state),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: onDisconnect,
            child: const Text('Disconnect'),
          ),
        ],
      ),
    );
  }
}

class _CounterDisplay extends StatelessWidget {
  const _CounterDisplay({required this.state});

  final CounterState state;

  @override
  Widget build(BuildContext context) {
    if (state.value == null) {
      return const Text('Waiting for data...');
    }
    return Column(
      children: [
        Text(
          '${state.value}',
          style: Theme.of(context).textTheme.displayLarge,
        ),
        if (state.lastUpdate != null)
          _TimestampLabel(
            timestamp: state.lastUpdate!,
          ),
      ],
    );
  }
}

class _TimestampLabel extends StatelessWidget {
  const _TimestampLabel({required this.timestamp});

  final DateTime timestamp;

  @override
  Widget build(BuildContext context) {
    final h = timestamp.hour.toString().padLeft(2, '0');
    final m = timestamp.minute.toString().padLeft(2, '0');
    final s = timestamp.second.toString().padLeft(2, '0');
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text(
        'Last update: $h:$m:$s',
        style: Theme.of(context).textTheme.bodySmall,
      ),
    );
  }
}
