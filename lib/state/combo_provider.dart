/// Il controller della combo: la macchina a stati pura più il tempo.
///
/// Tiene una sola cosa che [ComboState] non può tenere: il timer della
/// finestra di [kComboWindow]. Ogni incremento lo fa ripartire; se scade, la
/// combo finisce.
///
/// Non si iscrive da solo agli eventi del contatore: lo pilota
/// [EffectsEngine], che è l'unico punto in cui arrivano le variazioni. Due
/// iscritti indipendenti agli stessi eventi vorrebbe dire due ordini di
/// esecuzione possibili sullo stesso tap.
library;

import 'dart:async';

import '../config.dart';
import 'combo_machine.dart';

/// Cosa è successo alla combo dopo un evento, per chi deve reagire.
class ComboOutcome {
  const ComboOutcome({required this.state, required this.crossedThreshold});

  final ComboState state;

  /// È stata superata una nuova soglia: va suonato il "ta-daa" e il testo
  /// celebrativo cambia.
  final bool crossedThreshold;
}

class ComboController {
  ComboController(
    this._onExpired, {
    required Timer Function(Duration, void Function()) scheduler,
  }) : _schedule = scheduler;

  /// Chiamata quando la finestra scade da sola, per far riemettere lo stato
  /// a chi ci sta sopra.
  final void Function() _onExpired;

  final Timer Function(Duration, void Function()) _schedule;

  Timer? _window;
  ComboState _state = ComboState.idle;

  ComboState get state => _state;

  /// Un tap di incremento: la combo avanza e la finestra riparte.
  ComboOutcome onIncrement() {
    final ComboState before = _state;
    _state = _state.next();

    _window?.cancel();
    _window = _schedule(kComboWindow, () {
      _window = null;
      _state = ComboState.idle;
      _onExpired();
    });

    return ComboOutcome(
      state: _state,
      crossedThreshold: crossedThreshold(before, _state),
    );
  }

  /// Un decremento interrompe la combo all'istante, senza celebrazioni
  /// (ANIMATIONS_SPEC → Combo: «la combo si azzera [...] se arriva un
  /// decremento»).
  void reset() {
    _window?.cancel();
    _window = null;
    _state = ComboState.idle;
  }

  void dispose() {
    _window?.cancel();
    _window = null;
  }
}
