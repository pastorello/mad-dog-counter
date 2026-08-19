/// Il controller dell'inattività.
///
/// Tiene un timer solo: quanto manca alla faccina annoiata. Ogni tap lo fa
/// ripartire; se scade, la faccina entra in scena e ci resta finché non arriva
/// un tap.
///
/// Come [ComboController], non si iscrive da solo agli eventi del contatore:
/// lo pilota [EffectsEngine], unico punto in cui arrivano le variazioni.
library;

import 'dart:async';

class IdleController {
  IdleController(
    this._onIdle, {
    required Timer Function(Duration, void Function()) scheduler,
    required Duration delay,
  }) : _schedule = scheduler,
       _waitFor = delay {
    _arm();
  }

  /// Chiamata quando scatta l'inattività.
  final void Function() _onIdle;

  final Timer Function(Duration, void Function()) _schedule;

  Duration _waitFor;
  Timer? _timer;
  bool _isIdle = false;

  /// La faccina è in scena.
  bool get isIdle => _isIdle;

  Duration get delay => _waitFor;

  /// Cambia i minuti di attesa (pannello impostazioni).
  /// Il conto riparte da adesso: cambiare l'impostazione non deve far
  /// comparire la faccina all'istante perché il vecchio conto era già oltre.
  set delay(Duration value) {
    if (value == _waitFor) return;
    _waitFor = value;
    if (!_isIdle) _arm();
  }

  /// C'è stata attività. Restituisce true se la faccina stava dormendo e va
  /// svegliata: sta al chiamante fare la festa e il suono.
  bool poke() {
    final bool wasIdle = _isIdle;
    _isIdle = false;
    _arm();
    return wasIdle;
  }

  /// Azzera senza svegliare nessuno (kill switch, apertura impostazioni).
  void reset() {
    _isIdle = false;
    _arm();
  }

  void _arm() {
    _timer?.cancel();
    _timer = _schedule(_waitFor, () {
      _timer = null;
      _isIdle = true;
      _onIdle();
    });
  }

  void dispose() {
    _timer?.cancel();
    _timer = null;
  }
}
