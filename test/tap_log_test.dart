import 'package:flutter_test/flutter_test.dart';
import 'package:mad_dog_counter/data/tap_log.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// [SqfliteTapLog] testato con un database sqflite vero (via `ffi`), non solo
/// attraverso il [NoopTapLog]: schema, insert, somma e ordinamento sono
/// comportamento del driver, non delle interfacce.
void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  // Ogni test apre un DB in memoria a se': `inMemoryDatabasePath` con la
  // factory ffi crea una connessione anonima nuova a ogni open, quindi i
  // test restano isolati senza toccare il filesystem.
  Future<SqfliteTapLog> openTestLog() =>
      SqfliteTapLog.open(path: inMemoryDatabasePath);

  group('schema e stato iniziale', () {
    test('un log appena creato e vuoto', () async {
      final SqfliteTapLog log = await openTestLog();
      addTearDown(log.close);

      expect(await log.sumOfDeltas(), 0);
      expect(await log.recent(), isEmpty);
      expect(await log.dumpAll(), isEmpty);
    });
  });

  group('insert e lettura', () {
    test('record scrive un tap leggibile con tutti i suoi campi', () async {
      final SqfliteTapLog log = await openTestLog();
      addTearDown(log.close);

      await log.record(1);
      final List<TapRecord> rows = await log.recent();

      expect(rows, hasLength(1));
      expect(rows.single.delta, 1);
      expect(rows.single.type, TapType.tap);
      expect(rows.single.id, isNotNull);
      expect(rows.single.timestamp, isNotNull);
    });

    test('record scrive un adjust col suo tipo', () async {
      final SqfliteTapLog log = await openTestLog();
      addTearDown(log.close);

      await log.record(239338, type: TapType.adjust);
      final List<TapRecord> rows = await log.recent();

      expect(rows.single.delta, 239338);
      expect(rows.single.type, TapType.adjust);
    });
  });

  group('sumOfDeltas', () {
    test('somma i delta positivi e negativi, compresi gli adjust', () async {
      final SqfliteTapLog log = await openTestLog();
      addTearDown(log.close);

      await log.record(1);
      await log.record(1);
      await log.record(-1);
      await log.record(-50, type: TapType.adjust);

      expect(await log.sumOfDeltas(), -49);
    });
  });

  group('recent', () {
    test('rispetta l\'ordine: il piu recente per primo', () async {
      final SqfliteTapLog log = await openTestLog();
      addTearDown(log.close);

      await log.record(1);
      await log.record(1);
      await log.record(1);

      final List<TapRecord> rows = await log.recent();
      // Gli id crescono con l'ordine di inserimento: e' il tiebreak che
      // garantisce l'ordine anche quando due insert cadono nello stesso
      // millisecondo (`ts DESC, id DESC`).
      expect(rows.map((TapRecord r) => r.id).toList(), <int>[3, 2, 1]);
    });

    test('rispetta il limit', () async {
      final SqfliteTapLog log = await openTestLog();
      addTearDown(log.close);

      for (int i = 0; i < 5; i++) {
        await log.record(1);
      }

      final List<TapRecord> rows = await log.recent(limit: 2);
      expect(rows.map((TapRecord r) => r.id).toList(), <int>[5, 4]);
    });
  });

  group('dumpAll', () {
    test('restituisce tutto dal piu vecchio', () async {
      final SqfliteTapLog log = await openTestLog();
      addTearDown(log.close);

      await log.record(1);
      await log.record(-1);
      await log.record(100, type: TapType.adjust);

      final List<TapRecord> rows = await log.dumpAll();
      expect(rows.map((TapRecord r) => r.id).toList(), <int>[1, 2, 3]);
      expect(rows.map((TapRecord r) => r.delta).toList(), <int>[1, -1, 100]);
    });
  });

  group('robustezza (regola d\'oro 2)', () {
    test('record non solleva anche se il DB e gia chiuso', () async {
      final SqfliteTapLog log = await openTestLog();
      await log.close();

      // L'insert sul DB chiuso fallisce: record() deve inghiottirlo, non
      // farlo risalire fino al chiamante (un tap non deve mai fallire).
      await expectLater(log.record(1), completes);
    });
  });

  group('query a intervallo (col clock iniettato)', () {
    test(
      'sumOfTapDeltasBetween somma i soli tap dentro l\'intervallo',
      () async {
        DateTime now = DateTime(2026, 11, 24, 13);
        final SqfliteTapLog log = await SqfliteTapLog.open(
          path: inMemoryDatabasePath,
          clock: () => now,
        );
        addTearDown(log.close);

        await log.record(1); // dentro
        now = DateTime(2026, 11, 24, 18);
        await log.record(1); // dentro
        await log.record(-1); // dentro: la somma e' netta
        await log.record(10, type: TapType.adjust); // dentro ma adjust: escluso
        now = DateTime(2026, 11, 25, 13);
        await log.record(1); // fuori: dopo la fine

        final int sum = await log.sumOfTapDeltasBetween(
          DateTime(2026, 11, 24, 12),
          DateTime(2026, 11, 25, 12),
        );
        expect(sum, 1);
      },
    );

    test('incrementTimestampsSince: solo gli incrementi, in ordine', () async {
      DateTime now = DateTime(2026, 11, 24, 13);
      final SqfliteTapLog log = await SqfliteTapLog.open(
        path: inMemoryDatabasePath,
        clock: () => now,
      );
      addTearDown(log.close);

      await log.record(1);
      now = DateTime(2026, 11, 24, 14);
      await log.record(-1); // escluso: non e' un incremento
      now = DateTime(2026, 11, 24, 15);
      await log.record(1);
      now = DateTime(2026, 11, 24, 16);
      await log.record(3, type: TapType.adjust); // escluso: adjust

      final List<DateTime> stamps = await log.incrementTimestampsSince(
        DateTime(2026, 11, 24, 12, 30),
      );
      expect(stamps, <DateTime>[
        DateTime(2026, 11, 24, 13),
        DateTime(2026, 11, 24, 15),
      ]);
    });
  });
}
