/// Il contatore a finestra mobile che decide il tilt.
///
/// Regola d'oro 3 (CLAUDE.md): puro rispetto al tempo — niente timer, niente
/// orologio di sistema. Gli istanti arrivano sempre come argomenti; chi lo
/// usa ([EffectsEngine]) gli passa il suo clock.
library;

import 'dart:collection';

class SlidingWindowCounter {
  SlidingWindowCounter(this.window);

  /// Quanto è lunga la finestra di osservazione.
  final Duration window;

  final Queue<DateTime> _events = Queue<DateTime>();

  /// Registra un evento. Gli eventi devono arrivare in ordine cronologico
  /// (è il caso: ogni tap arriva "adesso").
  void add(DateTime at) {
    _events.addLast(at);
    _prune(at);
  }

  /// Precarica eventi passati (il seed dal log all'avvio), già in ordine
  /// cronologico crescente.
  void seed(Iterable<DateTime> events) => _events.addAll(events);

  /// Quanti eventi cadono nella finestra che finisce a [now].
  int countAt(DateTime now) {
    _prune(now);
    return _events.length;
  }

  /// Dimentica tutto: fine del tilt o kill switch. Senza questo, a tilt
  /// finito la finestra sarebbe ancora piena e il tap successivo lo
  /// riaccenderebbe subito.
  void clear() => _events.clear();

  void _prune(DateTime now) {
    final DateTime cutoff = now.subtract(window);
    while (_events.isNotEmpty && !_events.first.isAfter(cutoff)) {
      _events.removeFirst();
    }
  }
}
