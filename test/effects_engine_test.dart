import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mad_dog_counter/audio/sound_manager.dart';
import 'package:mad_dog_counter/config.dart';
import 'package:mad_dog_counter/data/counter_repository.dart';
import 'package:mad_dog_counter/data/tap_log.dart';
import 'package:mad_dog_counter/state/combo_machine.dart';
import 'package:mad_dog_counter/state/effect_triggers.dart';
import 'package:mad_dog_counter/state/effects_provider.dart';

/// Registra cosa gli viene chiesto di suonare, senza suonare niente.
class _SpySounds implements SoundManager {
  final List<String> played = <String>[];
  final List<({String asset, double rate})> rates =
      <({String asset, double rate})>[];
  int stopAllCalls = 0;

  @override
  bool enabled = true;

  @override
  Future<void> preload() async {}

  @override
  void play(String asset, {double rate = 1.0}) {
    played.add(asset);
    rates.add((asset: asset, rate: rate));
  }

  @override
  void stopAll() => stopAllCalls++;

  @override
  Future<void> dispose() async {}
}

/// Scheduler finto: raccoglie i timer e li fa scattare a comando, così i test
/// non aspettano davvero cinque secondi e mezzo per uno strike.
class _FakeClock {
  final List<({Duration delay, void Function() action, bool cancelled})>
  _pending = <({Duration delay, void Function() action, bool cancelled})>[];

  Timer schedule(Duration delay, void Function() action) {
    final int index = _pending.length;
    _pending.add((delay: delay, action: action, cancelled: false));
    return _FakeTimer(() {
      _pending[index] = (
        delay: _pending[index].delay,
        action: _pending[index].action,
        cancelled: true,
      );
    });
  }

  /// Fa scattare tutti i timer non cancellati programmati finora, in ordine.
  void fireAll() {
    final List<void Function()> due = <void Function()>[];
    for (int i = 0; i < _pending.length; i++) {
      if (!_pending[i].cancelled) {
        due.add(_pending[i].action);
        _pending[i] = (
          delay: _pending[i].delay,
          action: _pending[i].action,
          cancelled: true,
        );
      }
    }
    for (final void Function() action in due) {
      action();
    }
  }

  /// Fa scattare solo i timer programmati con questo ritardo. Serve a far
  /// scadere la finestra della combo senza toccare i timer degli effetti.
  void fire(Duration delay) {
    final List<void Function()> due = <void Function()>[];
    for (int i = 0; i < _pending.length; i++) {
      if (!_pending[i].cancelled && _pending[i].delay == delay) {
        due.add(_pending[i].action);
        _pending[i] = (
          delay: _pending[i].delay,
          action: _pending[i].action,
          cancelled: true,
        );
      }
    }
    for (final void Function() action in due) {
      action();
    }
  }

  int get pendingCount => _pending.where((r) => !r.cancelled).length;

  /// Quanti timer vivi con questo ritardo. Contare per ritardo invece che sul
  /// totale evita che aggiungere un effetto con un timer suo faccia fallire
  /// test che non lo riguardano.
  int pendingFor(Duration delay) =>
      _pending.where((r) => !r.cancelled && r.delay == delay).length;
}

class _FakeTimer implements Timer {
  _FakeTimer(this._onCancel);
  final void Function() _onCancel;

  @override
  void cancel() => _onCancel();

  @override
  bool get isActive => true;

  @override
  int get tick => 0;
}

CounterChange tap(int total, int delta) =>
    CounterChange(total: total, delta: delta, type: TapType.tap);

CounterChange adjust(int total, int delta) =>
    CounterChange(total: total, delta: delta, type: TapType.adjust);

({EffectsEngine engine, _SpySounds sounds, _FakeClock clock}) build() {
  final _SpySounds sounds = _SpySounds();
  final _FakeClock clock = _FakeClock();
  return (
    engine: EffectsEngine(sounds, scheduler: clock.schedule),
    sounds: sounds,
    clock: clock,
  );
}

void main() {
  group('regola 0 — solo su incremento', () {
    test('un decremento non accoda mai effetti', () {
      final b = build();
      // 239400 e' multiplo di 100: in salita farebbe fuochi.
      b.engine.onChange(tap(239400, -1));
      expect(b.engine.state.queue, isEmpty);
      expect(b.engine.state.current, isNull);
    });

    test('un decremento non puo CREARE gli 8 adiacenti', () {
      final b = build();
      // 890 -> 889: scendendo si inciampa in una coppia di 8.
      b.engine.onChange(tap(889, -1));
      expect(
        b.engine.state.boobsActive,
        isFalse,
        reason: 'la coppia si attiva solo salendo',
      );
    });

    test('un decremento puo ROMPERE gli 8 adiacenti', () {
      final b = build();
      b.engine.onChange(tap(889, 1));
      expect(b.engine.state.boobsActive, isTrue);
      b.engine.onChange(tap(890, -1)); // la coppia sparisce
      expect(b.engine.state.boobsActive, isFalse);
    });

    test('un decremento che lascia la coppia intatta la mantiene', () {
      final b = build();
      b.engine.onChange(tap(889, 1));
      expect(b.engine.state.boobsActive, isTrue);
      b.engine.onChange(tap(888, -1)); // gli 88 ci sono ancora
      expect(b.engine.state.boobsActive, isTrue);
    });

    test('le scritture manuali dal pannello non festeggiano', () {
      final b = build();
      b.engine.onChange(adjust(239400, 239400));
      expect(b.engine.state.queue, isEmpty);
      expect(b.engine.state.current, isNull);
      expect(b.sounds.played, isEmpty);
    });
  });

  group('regola 1 — coda ordinata per durata crescente', () {
    test('il primo effetto va in scena subito', () {
      final b = build();
      b.engine.onChange(tap(239400, 1));
      expect(b.engine.state.current, EffectKind.fireworks);
      expect(b.engine.state.queue, isEmpty);
    });

    // NOTA: oggi nessun singolo totale puo' far scattare due effetti insieme
    // (un multiplo di 100 finisce per 00, mai per 67). Il caso "due eventi
    // sullo stesso tap" della regola 1 diventera' reale con la combo, il cui
    // evento di fine si somma agli altri. Fino ad allora la coda si riempie
    // con tap ravvicinati, che e' il caso testato qui.
    test('un effetto arrivato durante un altro aspetta il suo turno', () {
      final b = build();
      b.engine.onChange(tap(239367, 1)); // shake67 -> in scena
      b.engine.onChange(tap(240000, 1)); // strike -> in coda
      expect(b.engine.state.current, EffectKind.shake67);
      expect(b.engine.state.queue, <EffectKind>[EffectKind.strike]);
    });

    test('finito il primo, parte il secondo', () {
      final b = build();
      b.engine.onChange(tap(239367, 1));
      b.engine.onChange(tap(240000, 1));
      b.clock.fireAll();
      expect(b.engine.state.current, EffectKind.strike);
    });

    test('svuotata la coda, il motore torna a riposo', () {
      final b = build();
      b.engine.onChange(tap(239400, 1));
      b.clock.fireAll(); // fine fuochi
      expect(b.engine.state.current, isNull);
      expect(b.engine.state.isIdle, isTrue);
    });
  });

  group('regola di assorbimento', () {
    test('sul multiplo di 1000 scatta lo strike, non i fuochi', () {
      final b = build();
      b.engine.onChange(tap(240000, 1));
      expect(b.engine.state.current, EffectKind.strike);
      expect(b.engine.state.queue, isEmpty);
      expect(b.sounds.played, contains(kSfxBowlingRoll));
      expect(b.sounds.played, isNot(contains(kSfxFireworks)));
    });
  });

  group('regola 2 — il feedback base non entra in coda', () {
    test('ogni incremento suona il pop, anche senza effetti', () {
      final b = build();
      b.engine.onChange(tap(239339, 1));
      expect(b.sounds.played, <String>[kSfxTapPop]);
      expect(b.engine.state.queue, isEmpty);
    });

    test('il decremento ha un suono suo', () {
      final b = build();
      b.engine.onChange(tap(239337, -1));
      expect(b.sounds.played, <String>[kSfxTapDown]);
    });
  });

  group('suoni degli effetti', () {
    test('il boing suona solo quando la coppia si forma, non a ogni tap', () {
      final b = build();
      b.engine.onChange(tap(889, 1));
      expect(b.sounds.played.where((String s) => s == kSfxBoing).length, 1);

      b.sounds.played.clear();
      b.engine.onChange(tap(8890, 1)); // la coppia c'e' ancora
      expect(b.sounds.played, isNot(contains(kSfxBoing)));
    });

    test('lo strike suona in due tempi: rotolamento poi impatto', () {
      final b = build();
      b.engine.onChange(tap(240000, 1));
      expect(b.sounds.played, contains(kSfxBowlingRoll));
      expect(b.sounds.played, isNot(contains(kSfxBowlingStrike)));

      b.clock.fireAll();
      expect(b.sounds.played, contains(kSfxBowlingStrike));
    });
  });

  group('regola 6 — kill switch', () {
    test('svuota la coda, ferma i suoni e azzera gli stati persistenti', () {
      final b = build();
      b.engine.onChange(tap(889, 1)); // stato persistente attivo
      b.engine.onChange(tap(239400, 1)); // fuochi in scena
      b.engine.onChange(tap(240000, 1)); // strike in coda

      b.engine.killAll();

      expect(b.engine.state.current, isNull);
      expect(b.engine.state.queue, isEmpty);
      expect(b.engine.state.boobsActive, isFalse);
      expect(b.sounds.stopAllCalls, 1);
    });

    test('maschera con l esplosione, poi torna pulito', () {
      final b = build();
      b.engine.onChange(tap(239400, 1));
      b.engine.killAll();

      expect(b.engine.state.panicking, isTrue);
      expect(b.sounds.played, contains(kSfxPanicExplosion));

      b.clock.fireAll();
      expect(b.engine.state.panicking, isFalse);
      expect(b.engine.state.isIdle, isTrue);
    });

    test('la variante silenziosa non esplode', () {
      final b = build();
      b.engine.onChange(tap(239400, 1));
      b.sounds.played.clear();

      b.engine.killAll(silent: true);

      expect(b.engine.state.panicking, isFalse);
      expect(b.sounds.played, isNot(contains(kSfxPanicExplosion)));
      expect(b.engine.state.queue, isEmpty);
    });

    test('cancella i timer in volo: niente effetti zombie', () {
      final b = build();
      b.engine.onChange(tap(240000, 1));
      expect(b.clock.pendingFor(kStrikeDuration), 1, reason: 'effetto');
      expect(b.clock.pendingFor(kStrikeImpactDelay), 1, reason: 'impatto');

      b.engine.killAll(silent: true);
      expect(b.clock.pendingFor(kStrikeDuration), 0);
      expect(b.clock.pendingFor(kStrikeImpactDelay), 0);
      expect(b.clock.pendingFor(kComboWindow), 0);

      b.clock.fireAll();
      expect(b.engine.state.current, isNull);
    });

    test('gli effetti accodati durante l esplosione riprendono dopo', () {
      final b = build();
      b.engine.killAll(); // esplosione in corso
      expect(b.engine.state.panicking, isTrue);

      // Il pub non si ferma per un secondo: arriva un tap da 100.
      b.engine.onChange(tap(239400, 1));
      expect(
        b.engine.state.current,
        isNull,
        reason: 'niente va in scena sotto la maschera',
      );
      expect(b.engine.state.queue, <EffectKind>[EffectKind.fireworks]);

      b.clock.fireAll(); // fine esplosione
      expect(b.engine.state.panicking, isFalse);
      expect(
        b.engine.state.current,
        EffectKind.fireworks,
        reason: 'l effetto in attesa riprende, non resta bloccato in coda',
      );
    });

    test('incrementa killCount, il seme a cui si aggancia la combo', () {
      final b = build();
      expect(b.engine.state.killCount, 0);
      b.engine.killAll(silent: true);
      b.engine.killAll(silent: true);
      expect(b.engine.state.killCount, 2);
    });
  });

  group('regola 4 — il conteggio non si ferma mai', () {
    test('i tap durante un effetto continuano a essere elaborati', () {
      final b = build();
      b.engine.onChange(tap(240000, 1)); // strike lungo in scena
      b.sounds.played.clear();

      b.engine.onChange(tap(240001, 1));
      b.engine.onChange(tap(240002, 1));

      // Il pop si sente a ogni tap anche mentre lo strike e' in corso.
      // (Questi tap fanno anche salire la combo, che ha suoni suoi: qui
      // interessa solo che il feedback base non venga saltato.)
      expect(b.sounds.played.where((String s) => s == kSfxTapPop).length, 2);
      expect(b.engine.state.current, EffectKind.strike);
    });
  });

  test('watch() emette subito lo stato corrente', () async {
    final b = build();
    expect((await b.engine.watch().first).isIdle, isTrue);
  });

  group('combo', () {
    test('sale a ogni incremento consecutivo', () {
      final b = build();
      b.engine.onChange(tap(1, 1));
      b.engine.onChange(tap(2, 1));
      b.engine.onChange(tap(3, 1));
      expect(b.engine.state.combo, const ComboState(3));
      expect(b.engine.state.combo.multiplier, 3);
    });

    test('il pop sale di pitch a ogni tap della combo', () {
      final _SpySounds sounds = _SpySounds();
      final _FakeClock clock = _FakeClock();
      final EffectsEngine engine = EffectsEngine(
        sounds,
        scheduler: clock.schedule,
      );

      engine.onChange(tap(1, 1));
      engine.onChange(tap(2, 1));
      engine.onChange(tap(3, 1));

      final List<double> rates = sounds.rates
          .where((({String asset, double rate}) r) => r.asset == kSfxTapPop)
          .map((({String asset, double rate}) r) => r.rate)
          .toList();
      expect(rates.length, 3);
      expect(rates[0], 1.0);
      expect(rates[1], greaterThan(rates[0]));
      expect(rates[2], greaterThan(rates[1]));
    });

    test('la soglia suona il ta-daa, i tap in mezzo no', () {
      final b = build();
      final int soglia = kComboThresholds[0];

      for (int i = 1; i < soglia; i++) {
        b.engine.onChange(tap(i, 1));
      }
      expect(b.sounds.played, isNot(contains(kSfxComboMilestone)));

      b.engine.onChange(tap(soglia, 1)); // supera la soglia
      expect(
        b.sounds.played.where((String s) => s == kSfxComboMilestone).length,
        1,
      );

      b.engine.onChange(tap(soglia + 1, 1)); // dentro lo stesso livello
      expect(
        b.sounds.played.where((String s) => s == kSfxComboMilestone).length,
        1,
      );
    });

    test('scaduta la finestra di 2 s la combo finisce', () {
      final b = build();
      b.engine.onChange(tap(1, 1));
      b.engine.onChange(tap(2, 1));
      expect(b.engine.state.combo.isActive, isTrue);

      b.clock.fire(kComboWindow);
      expect(b.engine.state.combo, ComboState.idle);
    });

    test('ogni tap fa ripartire la finestra, non ne accumula', () {
      final b = build();
      b.engine.onChange(tap(1, 1));
      b.engine.onChange(tap(2, 1));
      b.engine.onChange(tap(3, 1));

      // Se le finestre dei tap precedenti non venissero cancellate, la prima
      // a scadere ucciderebbe una combo ancora viva: due secondi dopo il
      // PRIMO tap invece che dopo l'ultimo.
      expect(b.clock.pendingFor(kComboWindow), 1);
      expect(b.engine.state.combo, const ComboState(3));
    });

    test('un decremento interrompe la combo all istante', () {
      final b = build();
      b.engine.onChange(tap(5, 1));
      b.engine.onChange(tap(6, 1));
      expect(b.engine.state.combo.isActive, isTrue);

      b.engine.onChange(tap(5, -1));
      expect(b.engine.state.combo, ComboState.idle);
      expect(
        b.sounds.played,
        isNot(contains(kSfxComboMilestone)),
        reason: 'il -1 non celebra niente',
      );
    });

    test('il kill switch azzera anche la combo', () {
      final b = build();
      for (int i = 1; i <= kComboCiommoThreshold; i++) {
        b.engine.onChange(tap(i, 1));
      }
      expect(b.engine.state.combo.showsCiommo, isTrue);

      b.engine.killAll(silent: true);
      expect(b.engine.state.combo, ComboState.idle);
    });

    test('una combo viva tiene il motore non-idle', () {
      final b = build();
      b.engine.onChange(tap(1, 1));
      b.engine.onChange(tap(2, 1));
      expect(b.engine.state.isIdle, isFalse);

      b.clock.fire(kComboWindow);
      expect(b.engine.state.isIdle, isTrue);
    });

    test('le scritture manuali non fanno combo', () {
      final b = build();
      b.engine.onChange(adjust(239338, 239338));
      expect(b.engine.state.combo, ComboState.idle);
    });
  });

  group('idle', () {
    ({EffectsEngine engine, _SpySounds sounds, _FakeClock clock}) buildIdle(
      Duration delay,
    ) {
      final _SpySounds sounds = _SpySounds();
      final _FakeClock clock = _FakeClock();
      return (
        engine: EffectsEngine(
          sounds,
          scheduler: clock.schedule,
          idleDelay: delay,
        ),
        sounds: sounds,
        clock: clock,
      );
    }

    const Duration delay = Duration(minutes: 10);

    test('dopo i minuti di attesa compare la faccina', () {
      final b = buildIdle(delay);
      expect(b.engine.state.idleFaceVisible, isFalse);

      b.clock.fire(delay);
      expect(b.engine.state.idleFaceVisible, isTrue);
    });

    test('l idle e muto: non deve disturbare il pub', () {
      final b = buildIdle(delay);
      b.clock.fire(delay);
      expect(b.sounds.played, isEmpty);
    });

    test('un tap la sveglia e fa il giubilo', () {
      final b = buildIdle(delay);
      b.clock.fire(delay);

      b.engine.onChange(tap(1, 1));

      expect(b.engine.state.idleFaceVisible, isFalse);
      expect(b.engine.state.idleWaking, isTrue);
      expect(b.sounds.played, contains(kSfxWakeJubilation));
    });

    test('anche un decremento conta come attivita', () {
      final b = buildIdle(delay);
      b.clock.fire(delay);

      // Il barista sta correggendo un errore: il pub non e addormentato.
      b.engine.onChange(tap(5, -1));
      expect(b.engine.state.idleFaceVisible, isFalse);
      expect(b.sounds.played, contains(kSfxWakeJubilation));
    });

    test('un tap normale non fa il giubilo', () {
      final b = buildIdle(delay);
      b.engine.onChange(tap(1, 1));
      expect(b.sounds.played, isNot(contains(kSfxWakeJubilation)));
      expect(b.engine.state.idleWaking, isFalse);
    });

    test('finita la festa la faccina e fuori scena', () {
      final b = buildIdle(delay);
      b.clock.fire(delay);
      b.engine.onChange(tap(1, 1));

      b.clock.fire(kIdleWakeDuration);
      expect(b.engine.state.idleWaking, isFalse);
      expect(b.engine.state.idleFaceVisible, isFalse);
    });

    test('ogni tap fa ripartire il conto, non ne accumula', () {
      final b = buildIdle(delay);
      b.engine.onChange(tap(1, 1));
      b.engine.onChange(tap(2, 1));
      expect(b.clock.pendingFor(delay), 1);
    });

    test('il kill switch rimanda la faccina a dormire, senza giubilo', () {
      final b = buildIdle(delay);
      b.clock.fire(delay);
      expect(b.engine.state.idleFaceVisible, isTrue);

      b.engine.killAll(silent: true);

      expect(b.engine.state.idleFaceVisible, isFalse);
      expect(b.sounds.played, isNot(contains(kSfxWakeJubilation)));
      expect(
        b.clock.pendingFor(delay),
        1,
        reason: 'il conto riparte: dopo il panico il pub resta comunque calmo',
      );
    });

    test('cambiare i minuti fa ripartire il conto da adesso', () {
      final b = buildIdle(delay);
      const Duration nuovo = Duration(minutes: 3);

      b.engine.idleDelay = nuovo;

      expect(b.clock.pendingFor(delay), 0);
      expect(b.clock.pendingFor(nuovo), 1);
      expect(
        b.engine.state.idleFaceVisible,
        isFalse,
        reason: 'abbassare la soglia non deve far apparire la faccina subito',
      );
    });

    test('le scritture manuali dal pannello non svegliano nessuno', () {
      final b = buildIdle(delay);
      b.clock.fire(delay);

      b.engine.onChange(adjust(239338, 239338));
      expect(b.engine.state.idleFaceVisible, isTrue);
    });
  });
}
