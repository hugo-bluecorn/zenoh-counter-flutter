import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Provides the app-wide [GoRouter] instance.
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/connect',
    routes: [
      GoRoute(
        path: '/connect',
        builder: (context, state) => const Scaffold(
          body: Center(child: Text('Connection')),
        ),
      ),
      GoRoute(
        path: '/counter',
        builder: (context, state) => const Scaffold(
          body: Center(child: Text('Counter')),
        ),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const Scaffold(
          body: Center(child: Text('Settings')),
        ),
      ),
    ],
  );
});
