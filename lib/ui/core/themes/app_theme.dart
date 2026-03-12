import 'package:flutter/material.dart';

/// App-wide Material 3 theme configuration.
class AppTheme {
  /// Light theme using Material 3 with a blue color scheme.
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.blue,
      );
}
