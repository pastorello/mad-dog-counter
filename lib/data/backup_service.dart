/// Backup giornaliero su file.
///
/// È la mitigazione del rischio accettato in ARCHITECTURE.md → Rischio noto:
/// se il tablet muore o l'app viene disinstallata, il conteggio locale va
/// perso. Non è un backup vero — quello è la fase 2 — ma salva dal 90% dei
/// disastri, e costa un file al giorno.
///
/// Tutto qui dentro è fire-and-forget: un backup che fallisce non deve mai
/// diventare un'eccezione che risale fino a un tap (regola d'oro 2).
library;

// I campi restano privati e i parametri sono tutti nominati: Dart non ammette
// un parametro nominato che inizi con l'underscore, quindi initializing formal
// qui non e' una scelta disponibile.
// ignore_for_file: prefer_initializing_formals

import 'dart:convert';
import 'dart:io';

import '../config.dart';
import 'tap_log.dart';

/// Dove finiscono i backup e chi tiene il conto dell'ultimo fatto.
///
/// La directory arriva da fuori invece di essere risolta qui: così i test
/// scrivono in una cartella temporanea vera, senza mock del filesystem.
class BackupService {
  BackupService({
    required Directory directory,
    required TapLog log,
    required int Function() readTotal,
    required String? Function() readLastBackupDay,
    required Future<void> Function(String day) writeLastBackupDay,
    DateTime Function() clock = DateTime.now,
  }) : _directory = directory,
       _log = log,
       _readTotal = readTotal,
       _readLastBackupDay = readLastBackupDay,
       _writeLastBackupDay = writeLastBackupDay,
       _clock = clock;

  final Directory _directory;
  final TapLog _log;
  final int Function() _readTotal;
  final String? Function() _readLastBackupDay;
  final Future<void> Function(String day) _writeLastBackupDay;
  final DateTime Function() _clock;

  bool _running = false;

  /// Il giorno di oggi come `YYYYMMDD`.
  static String dayKey(DateTime when) =>
      '${when.year.toString().padLeft(4, '0')}'
      '${when.month.toString().padLeft(2, '0')}'
      '${when.day.toString().padLeft(2, '0')}';

  static String fileNameFor(String day) => 'backup_$day.json';

  /// Fa il backup se oggi non è ancora stato fatto.
  ///
  /// Va chiamata all'avvio E a ogni scrittura: il tablet sta acceso a muro per
  /// settimane, quindi contare solo sull'avvio vorrebbe dire un backup al mese.
  Future<void> backupIfNeeded() async {
    // Un giro alla volta: a inizio serata i tap arrivano fitti e il primo
    // controllo non ha ancora finito di scrivere quando arriva il secondo.
    if (_running) return;

    final String today = dayKey(_clock());
    if (_readLastBackupDay() == today) return;

    _running = true;
    try {
      await _write(today);
      await _writeLastBackupDay(today);
      await _prune();
    } catch (_) {
      // Silenzio voluto: si riprova al prossimo tap. Il giorno non viene
      // segnato, quindi non si perde il backup, si rimanda.
    } finally {
      _running = false;
    }
  }

  Future<File> _write(String day) async {
    final List<TapRecord> taps = await _log.dumpAll();
    final Map<String, Object?> payload = <String, Object?>{
      'created_at': _clock().toIso8601String(),
      'schema': kTapLogSchemaVersion,
      kPrefsCounterTotal: _readTotal(),
      // Il dump è integrale: per ricostruire la storia servono tutti i tap.
      // Cresce col tempo (qualche decina di byte a tap), ed è accettabile:
      // sette file al giorno di ritenzione, su un tablet da 32 GB.
      'taps': taps.map((TapRecord t) => t.toJson()).toList(),
    };

    if (!await _directory.exists()) {
      await _directory.create(recursive: true);
    }
    final File file = File('${_directory.path}/${fileNameFor(day)}');
    return file.writeAsString(jsonEncode(payload), flush: true);
  }

  /// Tiene solo gli ultimi [kBackupRetentionDays] file.
  Future<void> _prune() async {
    final List<File> backups = await listBackups();
    if (backups.length <= kBackupRetentionDays) return;
    for (final File old in backups.sublist(kBackupRetentionDays)) {
      try {
        await old.delete();
      } catch (_) {
        // Un file che non si cancella non è un problema: al massimo occupa.
      }
    }
  }

  /// I backup presenti, dal più recente.
  Future<List<File>> listBackups() async {
    if (!await _directory.exists()) return <File>[];
    final List<File> files = await _directory
        .list()
        .where((FileSystemEntity e) => e is File)
        .cast<File>()
        .where((File f) => _backupName.hasMatch(_baseName(f)))
        .toList();
    // I nomi sono YYYYMMDD: l'ordine alfabetico è già l'ordine cronologico.
    files.sort((File a, File b) => _baseName(b).compareTo(_baseName(a)));
    return files;
  }

  static final RegExp _backupName = RegExp(r'^backup_\d{8}\.json$');

  static String _baseName(File file) => file.uri.pathSegments.last;
}
