/// Il controller del record del giorno: la logica pura più il tempo e la
/// persistenza.
///
/// Come [ComboController] e [IdleController], non si iscrive da solo agli
/// eventi del contatore: lo pilota [EffectsEngine], unico punto in cui
/// arrivano le variazioni (due iscritti indipendenti agli stessi eventi
/// vorrebbe dire due ordini di esecuzione possibili sullo stesso tap).
///
/// Tutto qui dentro è fire-and-forget rispetto al conteggio (regola d'oro 2):
/// prefs e log possono fallire, il tap è già contato.
library;

// Parametri nominati assegnati a campi privati: come in backup_service.dart,
// Dart non ammette un parametro nominato che inizi con l'underscore.
// ignore_for_file: prefer_initializing_formals

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config.dart';
import '../data/settings_repository.dart';
import '../data/tap_log.dart';
import 'daily_stats.dart';
import 'daily_window.dart';

/// Cosa è successo al record dopo un tap, per chi deve reagire (il motore
/// effetti accoda la celebrazione).
class DailyTapOutcome {
  const DailyTapOutcome({required this.stats, required this.recordSurpassed});

  final DailyStats stats;

  /// Con questo tap il record è stato superato per la prima volta nella
  /// finestra: parte NUOVO RECORD!.
  final bool recordSurpassed;
}

class DailyStatsController {
  DailyStatsController({
    required SettingsRepository settings,
    required TapLog log,
    DateTime Function() clock = DateTime.now,
    Timer Function(Duration, void Function()) scheduler = _realScheduler,
  }) : _settings = settings,
       _log = log,
       _clock = clock,
       _schedule = scheduler,
       _state = DailyStats(windowKey: dailyWindowKey(clock()));

  static Timer _realScheduler(Duration delay, void Function() action) =>
      Timer(delay, action);

  final SettingsRepository _settings;
  final TapLog _log;
  final DateTime Function() _clock;
  final Timer Function(Duration, void Function()) _schedule;

  final StreamController<DailyStats> _states =
      StreamController<DailyStats>.broadcast();

  final Completer<List<DateTime>> _tiltSeed = Completer<List<DateTime>>();

  DailyStats _state;
  Timer? _noonTimer;
  bool _rolling = false;

  DailyStats get state => _state;

  /// Gli incrementi delle ultime [kTiltWindow] ore letti dal log all'avvio:
  /// il motore effetti li usa per non far ripartire da zero la finestra del
  /// tilt dopo un riavvio. Completa sempre (vuoto se il log non c'è).
  Future<List<DateTime>> get tiltSeed => _tiltSeed.future;

  /// Carica lo stato e arma il timer di mezzogiorno.
  ///
  /// Parte dalla cache prefs (sincrona: il badge è a video dal primo frame),
  /// poi — se il log sqflite è vero — **il log vince**: il conteggio della
  /// finestra si ricalcola con una SUM sull'intervallo. Prefs e log sono
  /// entrambi fire-and-forget, ma il log è append-only: più affidabile della
  /// cache quando divergono. Con [NoopTapLog] resta la cache.
  Future<void> init() async {
    final DateTime now = _clock();
    final String key = dailyWindowKey(now);
    _state = DailyStats(
      windowKey: key,
      todayCount: _settings.dailyWindowKey == key ? _settings.dailyCount : 0,
      bestCount: _settings.bestDayCount,
      bestDayKey: _settings.bestDayKey,
      celebratedThisWindow: _settings.recordCelebratedWindow == key,
    );
    _emit();
    _armNoonTimer();

    if (_log is NoopTapLog) {
      _completeSeed(const <DateTime>[]);
      return;
    }

    try {
      final int fromLog = await _log.sumOfTapDeltasBetween(
        windowStartFor(now),
        // Non "now": tra la lettura dell'orologio e la query possono essere
        // arrivati tap. Un orizzonte largo prende anche quelli.
        now.add(const Duration(days: 1)),
      );
      // Il mondo può essere cambiato durante l'await: si aggiorna solo se la
      // finestra è ancora quella, e si riapplica il ratchet del record.
      if (_state.windowKey == key && _state.todayCount != fromLog) {
        DailyStats next = _state.copyWith(todayCount: fromLog);
        if (next.todayCount > next.bestCount) {
          next = next.copyWith(
            bestCount: next.todayCount,
            bestDayKey: next.windowKey,
          );
        }
        _state = next;
        _persistCounts();
        _emit();
      }
    } catch (_) {
      // La cache prefs resta in carica.
    }

    try {
      _completeSeed(
        await _log.incrementTimestampsSince(_clock().subtract(kTiltWindow)),
      );
    } catch (_) {
      _completeSeed(const <DateTime>[]);
    }
  }

  void _completeSeed(List<DateTime> seed) {
    if (!_tiltSeed.isCompleted) _tiltSeed.complete(seed);
  }

  void _armNoonTimer() {
    _noonTimer?.cancel();
    final DateTime now = _clock();
    _noonTimer = _schedule(nextNoonAfter(now).difference(now), () {
      unawaited(rolloverIfNeeded());
      _armNoonTimer();
    });
  }

  /// Chiude la finestra se mezzogiorno è passato. Idempotente per chiave:
  /// timer, controllo d'avvio e tap possono sovrapporsi senza doppia
  /// chiusura, perché la chiave confrontata è l'unico lucchetto.
  ///
  /// Il best non si tocca: col ratchet in linea è già aggiornato.
  Future<void> rolloverIfNeeded() async {
    if (_rolling) return;
    final String key = dailyWindowKey(_clock());
    if (key == _state.windowKey) return;

    _rolling = true;
    try {
      int today = 0;
      if (_log is! NoopTapLog) {
        // I tap caduti tra mezzogiorno e questa chiusura ritardata finiscono
        // nella finestra giusta.
        try {
          final DateTime now = _clock();
          today = await _log.sumOfTapDeltasBetween(
            windowStartFor(now),
            now.add(const Duration(days: 1)),
          );
        } catch (_) {
          today = 0;
        }
      }
      // Qualcuno (il ramo sincrono di [onTapDelta]) può aver già chiuso
      // durante l'await: in quel caso lo stato è più fresco di noi.
      if (dailyWindowKey(_clock()) != _state.windowKey) {
        _state = DailyStats(
          windowKey: key,
          todayCount: today,
          bestCount: _state.bestCount,
          bestDayKey: _state.bestDayKey,
        );
        _persistCounts();
        _persistWindow();
        _emit();
      }
    } finally {
      _rolling = false;
    }
  }

  /// Un tap (±1). Sincrono: il chiamante è nel percorso degli effetti e non
  /// deve aspettare nessuno.
  ///
  /// Se nel frattempo è passato mezzogiorno, la finestra nuova si apre QUI,
  /// in modo sincrono e senza log: è corretta per costruzione, perché ogni
  /// tap dopo mezzogiorno passa di qua — non possono esserci tap "persi"
  /// nella finestra appena aperta.
  DailyTapOutcome onTapDelta(int delta) {
    final String key = dailyWindowKey(_clock());
    if (key != _state.windowKey) {
      _state = DailyStats(
        windowKey: key,
        bestCount: _state.bestCount,
        bestDayKey: _state.bestDayKey,
      );
      _persistWindow();
    }

    final DailyStats before = _state;
    DailyStats after = applyTapDelta(before, delta);
    final bool surpassed = delta > 0 && shouldCelebrateRecord(before, after);
    if (surpassed) {
      after = after.copyWith(celebratedThisWindow: true);
      unawaited(_settings.setRecordCelebratedWindow(after.windowKey));
    }
    _state = after;
    _persistCounts();
    _emit();
    return DailyTapOutcome(stats: after, recordSurpassed: surpassed);
  }

  void _persistCounts() {
    unawaited(_settings.setDailyCount(_state.todayCount));
    unawaited(_settings.setBestDayCount(_state.bestCount));
    if (_state.bestDayKey case final String bestKey) {
      unawaited(_settings.setBestDayKey(bestKey));
    }
  }

  /// La chiave si scrive per ultima: se l'app muore a metà, al riavvio la
  /// chiave vecchia fa semplicemente ripartire il rollover.
  void _persistWindow() {
    unawaited(_settings.setDailyWindowKey(_state.windowKey));
  }

  void _emit() {
    if (!_states.isClosed) _states.add(_state);
  }

  Stream<DailyStats> watch() {
    late final StreamController<DailyStats> out;
    StreamSubscription<DailyStats>? subscription;
    out = StreamController<DailyStats>(
      onListen: () {
        out.add(_state);
        subscription = _states.stream.listen(out.add);
      },
      onCancel: () async {
        await subscription?.cancel();
      },
    );
    return out.stream;
  }

  Future<void> dispose() async {
    _noonTimer?.cancel();
    _noonTimer = null;
    _completeSeed(const <DateTime>[]);
    await _states.close();
  }
}

/// Il controller, sovrascritto in `main()`. Senza override non esiste e
/// l'app conta lo stesso: badge e record semplicemente non compaiono.
final Provider<DailyStatsController?> dailyStatsControllerProvider =
    Provider<DailyStatsController?>((Ref ref) => null);

/// Lo stato del record del giorno, per la UI (il badge di PR C).
final StreamProvider<DailyStats> dailyStatsProvider =
    StreamProvider<DailyStats>((Ref ref) {
      final DailyStatsController? controller = ref.watch(
        dailyStatsControllerProvider,
      );
      if (controller == null) return const Stream<DailyStats>.empty();
      return controller.watch();
    });
