/// Costruzione delle dipendenze di avvio, separata da `runApp()`.
///
/// Ogni passo ha una rete di sicurezza (regola d'oro 2): se sqflite, l'audio
/// o la storage esterna non si inizializzano, l'app deve contare comunque.
/// Isolare la costruzione qui, con ogni apertura iniettabile, rende quei
/// percorsi di fallback testabili senza toccare `runApp()`.
library;

import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import 'audio/sound_manager.dart';
import 'config.dart';
import 'data/backup_service.dart';
import 'data/counter_repository.dart';
import 'data/settings_repository.dart';
import 'data/tap_log.dart';
import 'state/daily_stats_provider.dart';

/// Le dipendenze pronte, da passare come override dei provider Riverpod.
class AppDependencies {
  const AppDependencies({
    required this.log,
    required this.repository,
    required this.sounds,
    required this.settings,
    required this.backup,
    required this.dailyStats,
  });

  final TapLog log;
  final LocalCounterRepository repository;
  final SoundManager sounds;
  final SettingsRepository settings;
  final BackupService? backup;
  final DailyStatsController dailyStats;
}

SoundManager _createDefaultSounds() => AudioPlayersSoundManager();

/// Il sanity check d'avvio: la somma del log quando DIVERGE dal totale,
/// null quando torna, quando il log è un Noop (lì la divergenza è ovvia e
/// non dice niente) o quando la lettura fallisce. Mai un'eccezione: in ogni
/// caso fa fede il totale (regola d'oro 1).
Future<int?> startupLogDiscrepancy(TapLog log, int total) async {
  if (log is NoopTapLog) return null;
  try {
    final int logged = await log.sumOfDeltas();
    return logged == total ? null : logged;
  } catch (_) {
    return null;
  }
}

/// Apre log, repository, audio, impostazioni e backup con i loro fallback.
///
/// I parametri iniettano il singolo passo di apertura: nei test si passano
/// funzioni che falliscono apposta, per verificare che il fallback (log
/// muto, audio muto, backup assente) sia quello scelto e che l'app resti
/// comunque pronta a contare.
Future<AppDependencies> buildAppDependencies({
  Future<TapLog> Function() openLog = SqfliteTapLog.open,
  Future<LocalCounterRepository> Function({required TapLog log})
      openRepository =
      LocalCounterRepository.open,
  SoundManager Function() createSounds = _createDefaultSounds,
  Future<SettingsRepository> Function() openSettings = SettingsRepository.open,
  Future<Directory?> Function() resolveBackupDirectory =
      getExternalStorageDirectory,
}) async {
  // Il log e' fire-and-forget: se sqflite non si apre, si conta lo stesso.
  TapLog log;
  try {
    log = await openLog();
  } catch (_) {
    log = const NoopTapLog();
  }

  final LocalCounterRepository repository = await openRepository(log: log);

  // Sanity check d'avvio (ARCHITECTURE -> Modello dati): se il log racconta
  // un'altra storia, fa fede il totale — ma la discrepanza si deve VEDERE.
  // Fire-and-forget: nessuna attesa sul percorso d'avvio.
  unawaited(
    startupLogDiscrepancy(log, repository.total).then((int? logged) {
      if (logged != null) {
        debugPrint(
          'Mad Dog Counter: il totale (${repository.total}) e la somma del '
          'log ($logged) divergono — fa fede il totale.',
        );
      }
    }),
  );

  // Anche l'audio e' fire-and-forget: se non si inizializza, si conta muti.
  SoundManager sounds;
  try {
    sounds = createSounds();
    unawaited(sounds.preload());
  } catch (_) {
    sounds = SilentSoundManager();
  }
  final SettingsRepository settings = await openSettings();
  sounds.enabled = settings.soundEnabled;

  // Il backup e' l'unica rete sotto al conteggio finche' non arriva la
  // fase 2. Se la storage esterna non c'e', l'app conta lo stesso: senza
  // rete, ma conta (regola d'oro 2).
  BackupService? backup;
  try {
    final Directory? external = await resolveBackupDirectory();
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

  // Il record del giorno: parte dalla cache prefs e si allinea al log in
  // background. L'init e' fire-and-forget come tutto il resto: se fallisce,
  // il badge mostra la cache e l'app conta comunque.
  final DailyStatsController dailyStats = DailyStatsController(
    settings: settings,
    log: log,
  );
  unawaited(dailyStats.init());

  return AppDependencies(
    log: log,
    repository: repository,
    sounds: sounds,
    settings: settings,
    backup: backup,
    dailyStats: dailyStats,
  );
}
