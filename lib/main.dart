import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import 'bootstrap.dart';
import 'config.dart';
import 'state/counter_provider.dart';
import 'ui/counter_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Landscape bloccato e schermo sempre acceso: è un tablet a muro.
  await SystemChrome.setPreferredOrientations(<DeviceOrientation>[
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  unawaited(WakelockPlus.enable());

  final AppDependencies deps = await buildAppDependencies();

  runApp(
    ProviderScope(
      overrides: [
        tapLogProvider.overrideWithValue(deps.log),
        counterRepositoryProvider.overrideWithValue(deps.repository),
        soundManagerProvider.overrideWithValue(deps.sounds),
        settingsRepositoryProvider.overrideWithValue(deps.settings),
        backupServiceProvider.overrideWithValue(deps.backup),
      ],
      child: const MadDogCounterApp(),
    ),
  );
}

class MadDogCounterApp extends StatelessWidget {
  const MadDogCounterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mad Dog Counter',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: kBackground,
        colorScheme: const ColorScheme.dark(
          primary: kPrimaryRed,
          secondary: kAccentBlue,
          surface: kSurfaceNavy,
          onSurface: kTextColor,
        ),
      ),
      home: const CounterScreen(),
    );
  }
}
