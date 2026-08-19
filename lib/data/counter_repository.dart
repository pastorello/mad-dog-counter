/// La porta verso la fase 2.
///
/// UI e motore effetti dipendono SOLO da [CounterRepository]. Quando arriverà
/// il backend online si aggiunge una `SyncedCounterRepository` senza toccare
/// nulla sopra. Nessun import di storage fuori da `data/`.
library;

import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';

import '../config.dart';
import 'tap_log.dart';

/// Una variazione del totale: quanto vale adesso e come ci è arrivato.
///
/// Il motore effetti ha bisogno del **segno** della variazione, non solo del
/// nuovo totale: la regola madre dice che gli effetti scattano solo in salita
/// (ANIMATIONS_SPEC → regola 0), e dal solo totale non si capisce da che parte
/// ci si è arrivati.
class CounterChange {
  const CounterChange({
    required this.total,
    required this.delta,
    required this.type,
  });

  /// Il totale dopo la variazione.
  final int total;

  /// Di quanto è cambiato. Positivo in salita, negativo in discesa.
  final int delta;

  /// Se è un tap o una scrittura manuale dal pannello impostazioni.
  final TapType type;

  bool get isIncrement => delta > 0;
  bool get isTap => type == TapType.tap;
}

/// Contratto del contatore.
abstract class CounterRepository {
  /// Il totale corrente, che emette a ogni variazione.
  Stream<int> watchTotal();

  /// Il totale corrente, letto in modo sincrono.
  int get total;

  /// Le variazioni del totale, una per una.
  ///
  /// Diverso da [watchTotal]: quello è lo stato da mostrare, questo sono gli
  /// eventi a cui reagire. Non rigioca lo storico: chi si iscrive dopo vede
  /// solo quello che succede da lì in avanti.
  Stream<CounterChange> watchChanges();

  /// +1. Restituisce il nuovo totale.
  Future<int> increment();

  /// −1, con clamp a [kMinCount]. Restituisce il nuovo totale.
  Future<int> decrement();

  /// Scrive il totale a mano (pannello impostazioni → "Imposta contatore").
  /// Registra un record `adjust` col delta risultante, così lo storico resta
  /// sommabile. Restituisce il nuovo totale.
  Future<int> setTotal(int value);

  Future<void> dispose();
}

/// Implementazione locale dell'MVP: shared_preferences per il totale,
/// sqflite per il log.
///
/// Il totale vive **anche in memoria**: è quello mostrato a schermo, e resta
/// corretto anche se una scrittura su storage fallisce (regola d'oro 1).
class LocalCounterRepository implements CounterRepository {
  LocalCounterRepository._(this._prefs, this._log, this._total);

  final SharedPreferences _prefs;
  final TapLog _log;
  final StreamController<int> _controller = StreamController<int>.broadcast();
  final StreamController<CounterChange> _changes =
      StreamController<CounterChange>.broadcast();

  int _total;

  /// Apre il repository leggendo il totale da storage.
  /// Al primissimo avvio inizializza a [kInitialCount].
  static Future<LocalCounterRepository> open({
    SharedPreferences? prefs,
    TapLog? log,
  }) async {
    final SharedPreferences p = prefs ?? await SharedPreferences.getInstance();
    final int stored = p.getInt(kPrefsCounterTotal) ?? kInitialCount;
    return LocalCounterRepository._(p, log ?? const NoopTapLog(), stored);
  }

  @override
  int get total => _total;

  @override
  Stream<int> watchTotal() {
    // Non e' un `async*` di proposito: con un generatore la sottoscrizione al
    // controller avviene solo *dopo* che il primo valore e' stato consumato, e
    // gli aggiornamenti che cadono in quella finestra vanno persi (il
    // controller e' broadcast, non li rigioca). Qui la sottoscrizione e'
    // stabilita dentro onListen, sincrona con il listen del chiamante.
    late final StreamController<int> out;
    StreamSubscription<int>? subscription;
    out = StreamController<int>(
      onListen: () {
        out.add(_total);
        subscription = _controller.stream.listen(out.add);
      },
      onCancel: () async {
        await subscription?.cancel();
      },
    );
    return out.stream;
  }

  @override
  Future<int> increment() => _applyDelta(1);

  @override
  Future<int> decrement() => _applyDelta(-1);

  Future<int> _applyDelta(int delta) async {
    final int next = _clamp(_total + delta);
    // Se il clamp ha mangiato il delta (siamo già a zero e si decrementa),
    // non si scrive nulla e non si logga nulla.
    if (next == _total) return _total;

    final int applied = next - _total;
    _total = next;
    _controller.add(_total); // la UI si aggiorna subito, prima dello storage

    _changes.add(
      CounterChange(total: _total, delta: applied, type: TapType.tap),
    );

    await _persist(_total);
    unawaited(_log.record(applied));
    return _total;
  }

  @override
  Future<int> setTotal(int value) async {
    final int next = _clamp(value);
    final int delta = next - _total;
    if (delta == 0) return _total;

    _total = next;
    _controller.add(_total);

    _changes.add(
      CounterChange(total: _total, delta: delta, type: TapType.adjust),
    );

    await _persist(_total);
    unawaited(_log.record(delta, type: TapType.adjust));
    return _total;
  }

  @override
  Stream<CounterChange> watchChanges() => _changes.stream;

  int _clamp(int value) => value < kMinCount ? kMinCount : value;

  /// Scrive il totale, ritentando una volta. Non solleva mai: il valore in
  /// memoria resta la verità mostrata a schermo anche se lo storage fa i
  /// capricci (FUNCTIONAL_SPEC → Stati speciali).
  Future<void> _persist(int value) async {
    try {
      await _prefs.setInt(kPrefsCounterTotal, value);
    } catch (_) {
      try {
        await _prefs.setInt(kPrefsCounterTotal, value);
      } catch (_) {
        // TODO(logging): registrare la discrepanza quando ci sarà un logger.
      }
    }
  }

  @override
  Future<void> dispose() async {
    await _controller.close();
    await _changes.close();
    await _log.close();
  }
}
