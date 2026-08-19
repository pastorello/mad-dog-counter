import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import 'audio/sound_manager.dart';
import 'config.dart';
import 'data/backup_service.dart';
import 'data/counter_repository.dart';
import 'data/settings_repository.dart';
import 'data/tap_log.dart';
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

  // Il log è fire-and-forget: se sqflite non si apre, si conta lo stesso.
  TapLog log;
  try {
    log = await SqfliteTapLog.open();
  } catch (_) {
    log = const NoopTapLog();
  }

  final LocalCounterRepository repository = await LocalCounterRepository.open(
    log: log,
  );

  // Anche l'audio e' fire-and-forget: se non si inizializza, si conta muti.
  SoundManager sounds;
  try {
    final AudioPlayersSoundManager player = AudioPlayersSoundManager();
    unawaited(player.preload());
    sounds = player;
  } catch (_) {
    sounds = SilentSoundManager();
  }
  final SettingsRepository settings = await SettingsRepository.open();
  sounds.enabled = settings.soundEnabled;

  // Il backup e' l'unica rete sotto al conteggio finche' non arriva la fase 2.
  // Se la storage esterna non c'e', l'app conta lo stesso: senza rete, ma
  // conta (regola d'oro 2).
  BackupService? backup;
  try {
    final Directory? external = await getExternalStorageDirectory();
    if (external != null) {
      backup = BackupService(
        directory: Directory('${external.path}/$kBackupDirName'),
        log: log,
        readTotal: () => repository.total,
        readLastBackupDay: () => settings.lastBackupDay,
        writeLastBackupDay: settings.setLastBackupDay,
      );
    }
  } catch (_) {
    backup = null;
  }

  runApp(
    ProviderScope(
      overrides: [
        tapLogProvider.overrideWithValue(log),
        counterRepositoryProvider.overrideWithValue(repository),
        soundManagerProvider.overrideWithValue(sounds),
        settingsRepositoryProvider.overrideWithValue(settings),
        backupServiceProvider.overrideWithValue(backup),
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
