import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mad_dog_counter/config.dart';
import 'package:mad_dog_counter/data/backup_service.dart';
import 'package:mad_dog_counter/data/tap_log.dart';

/// Log finto con dentro quello che gli si mette.
class _FakeLog implements TapLog {
  _FakeLog([this._records = const <TapRecord>[]]);

  final List<TapRecord> _records;
  bool throwOnDump = false;

  @override
  Future<List<TapRecord>> dumpAll() async {
    if (throwOnDump) throw const FileSystemException('sqflite offeso');
    return _records;
  }

  @override
  Future<void> record(int delta, {TapType type = TapType.tap}) async {}

  @override
  Future<List<TapRecord>> recent({int limit = 100}) async => _records;

  @override
  Future<int> sumOfDeltas() async => 0;

  @override
  Future<void> close() async {}
}

TapRecord tapAt(int id, DateTime when, int delta) =>
    TapRecord(id: id, timestamp: when, delta: delta, type: TapType.tap);

void main() {
  late Directory dir;
  late _FakeLog log;
  late String? lastDay;
  late DateTime now;
  late int total;

  BackupService build() => BackupService(
    directory: dir,
    log: log,
    readTotal: () => total,
    readLastBackupDay: () => lastDay,
    writeLastBackupDay: (String day) async => lastDay = day,
    clock: () => now,
  );

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('maddog_backup_test');
    log = _FakeLog();
    lastDay = null;
    now = DateTime(2026, 8, 19, 23, 30);
    total = 239338;
  });

  tearDown(() async {
    if (dir.existsSync()) await dir.delete(recursive: true);
  });

  group('quando scrive', () {
    test('il primo giro crea il file di oggi', () async {
      await build().backupIfNeeded();

      final File file = File('${dir.path}/backup_20260819.json');
      expect(file.existsSync(), isTrue);
      expect(lastDay, '20260819');
    });

    test('nello stesso giorno non riscrive', () async {
      final BackupService backup = build();
      await backup.backupIfNeeded();

      total = 239400; // il pub va avanti
      now = DateTime(2026, 8, 19, 23, 59);
      await backup.backupIfNeeded();

      final Map<String, Object?> saved = jsonDecode(
        File('${dir.path}/backup_20260819.json').readAsStringSync(),
      ) as Map<String, Object?>;
      expect(saved[kPrefsCounterTotal], 239338, reason: 'e quello di prima');
    });

    test('il giorno dopo riscrive', () async {
      final BackupService backup = build();
      await backup.backupIfNeeded();

      now = DateTime(2026, 8, 20, 0, 30);
      total = 239400;
      await backup.backupIfNeeded();

      expect(File('${dir.path}/backup_20260820.json').existsSync(), isTrue);
      expect(lastDay, '20260820');
    });

    test('crea la cartella se non esiste', () async {
      final Directory nested = Directory('${dir.path}/a/b/c');
      final BackupService backup = BackupService(
        directory: nested,
        log: log,
        readTotal: () => total,
        readLastBackupDay: () => lastDay,
        writeLastBackupDay: (String day) async => lastDay = day,
        clock: () => now,
      );

      await backup.backupIfNeeded();
      expect(nested.existsSync(), isTrue);
    });
  });

  group('cosa contiene', () {
    test('il totale e tutto il log', () async {
      log = _FakeLog(<TapRecord>[
        tapAt(1, DateTime(2026, 8, 19, 21), 1),
        tapAt(2, DateTime(2026, 8, 19, 22), -1),
      ]);

      await build().backupIfNeeded();

      final Map<String, Object?> saved = jsonDecode(
        File('${dir.path}/backup_20260819.json').readAsStringSync(),
      ) as Map<String, Object?>;

      expect(saved[kPrefsCounterTotal], 239338);
      expect(saved['schema'], kTapLogSchemaVersion);
      expect(saved['created_at'], isNotNull);

      final List<Object?> taps = saved['taps']! as List<Object?>;
      expect(taps, hasLength(2));
      expect((taps.first! as Map<String, Object?>)['delta'], 1);
      expect((taps.last! as Map<String, Object?>)['delta'], -1);
    });

    test('e JSON valido anche col log vuoto', () async {
      await build().backupIfNeeded();
      final Map<String, Object?> saved = jsonDecode(
        File('${dir.path}/backup_20260819.json').readAsStringSync(),
      ) as Map<String, Object?>;
      expect(saved['taps'], isEmpty);
    });
  });

  group('rotazione', () {
    Future<void> backupOn(BackupService backup, DateTime day) async {
      now = day;
      await backup.backupIfNeeded();
    }

    test('tiene gli ultimi kBackupRetentionDays file', () async {
      final BackupService backup = build();
      for (int i = 0; i < kBackupRetentionDays + 4; i++) {
        await backupOn(backup, DateTime(2026, 8, 1).add(Duration(days: i)));
      }

      final List<File> rimasti = await backup.listBackups();
      expect(rimasti, hasLength(kBackupRetentionDays));
    });

    test('cancella i piu vecchi, non i piu recenti', () async {
      final BackupService backup = build();
      for (int i = 0; i < kBackupRetentionDays + 2; i++) {
        await backupOn(backup, DateTime(2026, 8, 1).add(Duration(days: i)));
      }

      final List<File> rimasti = await backup.listBackups();
      final List<String> nomi = rimasti
          .map((File f) => f.uri.pathSegments.last)
          .toList();

      expect(nomi.first, 'backup_20260809.json', reason: 'il piu recente');
      expect(nomi, isNot(contains('backup_20260801.json')));
      expect(nomi, isNot(contains('backup_20260802.json')));
    });

    test('non tocca file che non sono backup', () async {
      final File estraneo = File('${dir.path}/non_toccarmi.txt')
        ..writeAsStringSync('ciao');

      final BackupService backup = build();
      for (int i = 0; i < kBackupRetentionDays + 3; i++) {
        await backupOn(backup, DateTime(2026, 8, 1).add(Duration(days: i)));
      }

      expect(estraneo.existsSync(), isTrue);
      expect(await backup.listBackups(), hasLength(kBackupRetentionDays));
    });
  });

  group('robustezza', () {
    test('un errore non risale mai al chiamante', () async {
      log.throwOnDump = true;
      // Se questa sollevasse, un tap potrebbe fallire per colpa del backup.
      await expectLater(build().backupIfNeeded(), completes);
    });

    test('dopo un errore il giorno non e segnato: si riprova', () async {
      log.throwOnDump = true;
      await build().backupIfNeeded();
      expect(lastDay, isNull);

      log.throwOnDump = false;
      await build().backupIfNeeded();
      expect(lastDay, '20260819');
    });

    test('due giri in parallelo non si pestano i piedi', () async {
      final BackupService backup = build();
      // A inizio serata i tap arrivano fitti: il secondo controllo parte
      // prima che il primo abbia finito di scrivere.
      await Future.wait<void>(<Future<void>>[
        backup.backupIfNeeded(),
        backup.backupIfNeeded(),
        backup.backupIfNeeded(),
      ]);

      expect(await backup.listBackups(), hasLength(1));
    });

    test('listBackups non esplode se la cartella non esiste', () async {
      final BackupService backup = BackupService(
        directory: Directory('${dir.path}/mai_creata'),
        log: log,
        readTotal: () => total,
        readLastBackupDay: () => lastDay,
        writeLastBackupDay: (String day) async => lastDay = day,
        clock: () => now,
      );
      expect(await backup.listBackups(), isEmpty);
    });
  });

  test('dayKey usa il formato dei nomi file', () {
    expect(BackupService.dayKey(DateTime(2026, 1, 5)), '20260105');
    expect(BackupService.fileNameFor('20260105'), 'backup_20260105.json');
  });
}
