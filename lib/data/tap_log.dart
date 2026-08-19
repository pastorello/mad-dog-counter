/// Log append-only dei tap su sqflite.
///
/// Alimenta le statistiche di fase 2 e dà uno storico retroattivo al giorno in
/// cui arriverà il backend. È scritto **fire-and-forget**: se una insert
/// fallisce il conteggio non ne risente mai (regola d'oro 2).
library;

import 'package:sqflite/sqflite.dart';

import '../config.dart';

/// Tipo di record nel log.
enum TapType {
  /// Tap normale sul contatore: delta ±1.
  tap,

  /// Impostazione manuale del totale dal pannello: delta arbitrario.
  adjust;

  String get dbValue => name;
}

/// Una riga del log.
class TapRecord {
  const TapRecord({
    required this.id,
    required this.timestamp,
    required this.delta,
    required this.type,
  });

  final int id;
  final DateTime timestamp;
  final int delta;
  final TapType type;

  Map<String, Object?> toJson() => <String, Object?>{
    'id': id,
    'ts': timestamp.millisecondsSinceEpoch,
    'delta': delta,
    'type': type.dbValue,
  };

  factory TapRecord.fromRow(Map<String, Object?> row) => TapRecord(
    id: row['id']! as int,
    timestamp: DateTime.fromMillisecondsSinceEpoch(row['ts']! as int),
    delta: row['delta']! as int,
    type: TapType.values.firstWhere(
      (TapType t) => t.dbValue == row['type'],
      orElse: () => TapType.tap,
    ),
  );
}

/// Accesso al log dei tap.
abstract class TapLog {
  /// Registra un movimento. Non deve mai propagare eccezioni al chiamante.
  Future<void> record(int delta, {TapType type = TapType.tap});

  /// Legge gli ultimi record, dal più recente.
  Future<List<TapRecord>> recent({int limit = 100});

  /// Somma di tutti i delta registrati. Serve al sanity check di avvio.
  Future<int> sumOfDeltas();

  /// Tutto il log, dal più vecchio. È il dump che finisce nel backup: per
  /// ricostruire la storia servono tutti i tap, non gli ultimi cento.
  Future<List<TapRecord>> dumpAll();

  Future<void> close();
}

/// Implementazione sqflite.
class SqfliteTapLog implements TapLog {
  SqfliteTapLog._(this._db);

  final Database _db;

  /// Apre (e se serve crea) il database del log.
  static Future<SqfliteTapLog> open({String? path}) async {
    final String dbPath = path ?? kTapLogDatabase;
    final Database db = await openDatabase(
      dbPath,
      version: kTapLogSchemaVersion,
      onCreate: (Database db, int version) async {
        await db.execute('''
          CREATE TABLE taps (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            ts INTEGER NOT NULL,
            delta INTEGER NOT NULL,
            type TEXT NOT NULL DEFAULT 'tap'
          )
        ''');
        await db.execute('CREATE INDEX idx_taps_ts ON taps (ts)');
      },
    );
    return SqfliteTapLog._(db);
  }

  @override
  Future<void> record(int delta, {TapType type = TapType.tap}) async {
    // Fire-and-forget: il log non deve MAI far fallire un tap.
    try {
      await _db.insert('taps', <String, Object?>{
        'ts': DateTime.now().millisecondsSinceEpoch,
        'delta': delta,
        'type': type.dbValue,
      });
    } catch (_) {
      // Silenzio voluto: perdere una riga di log è accettabile,
      // perdere un tap no.
    }
  }

  @override
  Future<List<TapRecord>> recent({int limit = 100}) async {
    final List<Map<String, Object?>> rows = await _db.query(
      'taps',
      orderBy: 'ts DESC, id DESC',
      limit: limit,
    );
    return rows.map(TapRecord.fromRow).toList();
  }

  @override
  Future<int> sumOfDeltas() async {
    final List<Map<String, Object?>> rows = await _db.rawQuery(
      'SELECT COALESCE(SUM(delta), 0) AS total FROM taps',
    );
    return (rows.first['total'] as int?) ?? 0;
  }

  @override
  Future<List<TapRecord>> dumpAll() async {
    final List<Map<String, Object?>> rows = await _db.query(
      'taps',
      orderBy: 'ts ASC, id ASC',
    );
    return rows.map(TapRecord.fromRow).toList();
  }

  @override
  Future<void> close() => _db.close();
}

/// Log che non scrive nulla. Usato quando sqflite non è disponibile e nei test
/// che non riguardano il log: il contatore deve funzionare comunque.
class NoopTapLog implements TapLog {
  const NoopTapLog();

  @override
  Future<void> record(int delta, {TapType type = TapType.tap}) async {}

  @override
  Future<List<TapRecord>> recent({int limit = 100}) async =>
      const <TapRecord>[];

  @override
  Future<int> sumOfDeltas() async => 0;

  @override
  Future<List<TapRecord>> dumpAll() async => const <TapRecord>[];

  @override
  Future<void> close() async {}
}
