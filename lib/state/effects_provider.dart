/// Il motore effetti: coda, stati persistenti e kill switch.
///
/// Regole di riferimento in ANIMATIONS_SPEC.md:
/// - regola 0: gli effetti scattano SOLO su incremento;
/// - regola 1: eventi indipendenti sullo stesso tap si accodano per durata
///   crescente, i corti prima, l'epico a chiudere;
/// - regola 2: il feedback base del tap non entra in coda, è istantaneo;
/// - regola 3: gli stati persistenti non entrano in coda;
/// - regola 4: i tap continuano a contare durante un effetto;
/// - regola 6: [killAll] ha priorità assoluta.
library;

import 'dart:async';

import '../audio/sound_manager.dart';
import '../config.dart';
import '../data/counter_repository.dart';
import '../ui/effects/effect_catalog.dart';
import 'effect_triggers.dart';

/// Come programmare un'azione differita. Iniettabile: i test passano un
/// finto scheduler e fanno scorrere il tempo a mano, senza attese vere.
typedef EffectScheduler = Timer Function(
  Duration delay,
  void Function() action,
);

Timer _realScheduler(Duration delay, void Function() action) =>
    Timer(delay, action);

/// Lo stato del layer effetti.
class EffectsState {
  const EffectsState({
    this.current,
    this.queue = const <EffectKind>[],
    this.boobsActive = false,
    this.panicking = false,
    this.killCount = 0,
  });

  /// L'effetto in scena adesso, se c'è.
  final EffectKind? current;

  /// Gli effetti in attesa, già ordinati per durata crescente.
  final List<EffectKind> queue;

  /// Stato persistente: il totale contiene una coppia di 8 adiacenti.
  /// Non è in coda, è una proprietà del display (regola 3).
  final bool boobsActive;

  /// L'esplosione del pulsante panico è in corso.
  final bool panicking;

  /// Quante volte è stato premuto il kill switch. È il seme a cui gli altri
  /// moduli (a partire dalla combo) si agganciano per azzerarsi.
  final int killCount;

  bool get isIdle => current == null && queue.isEmpty && !panicking;

  EffectsState copyWith({
    EffectKind? current,
    bool clearCurrent = false,
    List<EffectKind>? queue,
    bool? boobsActive,
    bool? panicking,
    int? killCount,
  }) {
    return EffectsState(
      current: clearCurrent ? null : (current ?? this.current),
      queue: queue ?? this.queue,
      boobsActive: boobsActive ?? this.boobsActive,
      panicking: panicking ?? this.panicking,
      killCount: killCount ?? this.killCount,
    );
  }
}

/// Il motore.
class EffectsEngine {
  EffectsEngine(this._sounds, {EffectScheduler scheduler = _realScheduler})
    : _schedule = scheduler;

  final SoundManager _sounds;
  final EffectScheduler _schedule;

  final StreamController<EffectsState> _states =
      StreamController<EffectsState>.broadcast();

  EffectsState _state = const EffectsState();

  Timer? _currentTimer;
  Timer? _followUpTimer;
  Timer? _panicTimer;

  EffectsState get state => _state;

  Stream<EffectsState> watch() {
    late final StreamController<EffectsState> out;
    StreamSubscription<EffectsState>? subscription;
    out = StreamController<EffectsState>(
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

  void _emit(EffectsState next) {
    _state = next;
    if (!_states.isClosed) _states.add(next);
  }

  /// Reagisce a una variazione del contatore.
  void onChange(CounterChange change) {
    // Le scritture manuali dal pannello non festeggiano: sono correzioni,
    // non cicchetti.
    if (!change.isTap) return;

    if (change.isIncrement) {
      _onIncrement(change.total);
    } else {
      _onDecrement(change.total);
    }
  }

  void _onIncrement(int total) {
    // Regola 2: il feedback base è istantaneo e non entra in coda.
    _sounds.play(kSfxTapPop);

    // Regola 3: lo stato persistente si ricalcola, fuori dalla coda.
    final bool boobs = hasAdjacentEights(total);
    if (boobs != _state.boobsActive) {
      if (boobs) _sounds.play(kSfxBoing);
      _emit(_state.copyWith(boobsActive: boobs));
    }

    // Regola 1: gli effetti dell'evento entrano in coda già ordinati.
    final List<EffectKind> triggered = triggersFor(total);
    if (triggered.isEmpty) return;

    _emit(_state.copyWith(queue: <EffectKind>[..._state.queue, ...triggered]));
    _advanceIfIdle();
  }

  void _onDecrement(int total) {
    _sounds.play(kSfxTapDown);

    // Regola 0: un decremento può ROMPERE lo stato persistente, mai crearlo.
    // Non si ricalcola da zero: scendendo si può inciampare in una coppia di 8
    // che prima non c'era (890 → 889), e attivarla sarebbe una celebrazione
    // in discesa.
    if (_state.boobsActive && !hasAdjacentEights(total)) {
      _emit(_state.copyWith(boobsActive: false));
    }
    // Nessun effetto accodato, per definizione.
  }

  /// Se non c'è niente in scena, tira su il prossimo dalla coda.
  void _advanceIfIdle() {
    if (_state.current != null || _state.panicking) return;
    _advance();
  }

  void _advance() {
    if (_state.queue.isEmpty) {
      _emit(_state.copyWith(clearCurrent: true));
      return;
    }

    final EffectKind next = _state.queue.first;
    final List<EffectKind> rest = _state.queue.sublist(1);
    _emit(_state.copyWith(current: next, queue: rest));

    final EffectSpec spec = effectCatalog[next]!;
    _sounds.play(spec.sound);

    // Effetti in due tempi: lo strike suona il rotolamento e poi l'impatto.
    final String? followUp = spec.followUpSound;
    final Duration? followUpDelay = spec.followUpDelay;
    if (followUp != null && followUpDelay != null) {
      _followUpTimer = _schedule(followUpDelay, () => _sounds.play(followUp));
    }

    _currentTimer = _schedule(spec.duration, () {
      _currentTimer = null;
      _advance();
    });
  }

  /// Kill switch. Priorità assoluta, chiamabile in qualsiasi istante
  /// (ANIMATIONS_SPEC → regola 6, FUNCTIONAL_SPEC → pulsante panico).
  ///
  /// Con [silent] non parte l'esplosione: è la variante usata quando si apre
  /// il pannello impostazioni.
  void killAll({bool silent = false}) {
    _cancelTimers();
    _sounds.stopAll();

    _emit(
      EffectsState(
        queue: const <EffectKind>[],
        boobsActive: false,
        panicking: !silent,
        killCount: _state.killCount + 1,
      ),
    );

    if (silent) return;

    _sounds.play(kSfxPanicExplosion);
    _panicTimer = _schedule(kPanicBlastDuration, () {
      _panicTimer = null;
      _emit(_state.copyWith(panicking: false));
      // La coda era stata svuotata, ma il pub non si ferma per un secondo:
      // i tap arrivati DURANTE l'esplosione hanno gia' accodato i loro
      // effetti, e vanno ripresi. Senza questo restano fermi in coda finche'
      // non arriva un altro trigger.
      _advanceIfIdle();
    });
  }

  void _cancelTimers() {
    _currentTimer?.cancel();
    _followUpTimer?.cancel();
    _panicTimer?.cancel();
    _currentTimer = null;
    _followUpTimer = null;
    _panicTimer = null;
  }

  Future<void> dispose() async {
    _cancelTimers();
    await _states.close();
  }
}
