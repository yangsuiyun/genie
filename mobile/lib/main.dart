import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'screens/main_layout.dart';
import 'screens/focus_mode_screen.dart';
import 'settings.dart';

void main() {
  runApp(
    const ProviderScope(
      child: PomodoroApp(),
    ),
  );
}

class PomodoroApp extends StatelessWidget {
  const PomodoroApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pomodoro Genie',
      theme: ThemeData(
        primarySwatch: Colors.red,
        useMaterial3: true,
      ),
      home: const ResponsiveMainLayout(),
      debugShowCheckedModeBanner: false,
      routes: {
        '/focus': (context) => const FocusModeScreen(),
        '/settings': (context) => const SettingsScreen(),
      },
    );
  }
}