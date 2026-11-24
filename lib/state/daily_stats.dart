/// Il conteggio del giorno e il record da battere, in forma pura.
///
/// Regola d'oro 3 (CLAUDE.md): niente storage, niente widget, niente tempo.
/// La finestra corrente arriva da fuori ([dailyWindowKey]); qui c'è solo la
/// domanda «con questo tap, che giornata è e il record com'è messo?».
library;

import 'dart:math' as math;

/// Lo stato del record del giorno. Immutabile.
class DailyStats {
  const DailyStats({
    required this.windowKey,
    this.todayCount = 0,
    this.bestCount = 0,
    this.bestDayKey,
    this.celebratedThisWindow = false,
  });

  /// La finestra corrente (`YYYYMMDD` del mezzogiorno di apertura).
  final String windowKey;

  /// Mad dog della finestra corrente, netto delle correzioni −1.
  /// Può andare sotto zero se si corregge più di quanto si è contato:
  /// a video si mostra [displayCount].
  final int todayCount;

  /// Il record: la miglior finestra di sempre.
  final int bestCount;

  /// In che finestra è stato fatto il record. Null finché non ne esiste uno.
  final String? bestDayKey;

  /// In questa finestra la festa del record è già partita: una sola per
  /// finestra, anche se il totale continua a salire.
  final bool celebratedThisWindow;

  /// Il giornaliero da mostrare: pavimento a zero (decisione del committente,
  /// design/mockups/DECISIONS.md → 01).
  int get displayCount => math.max(0, todayCount);

  DailyStats copyWith({
    String? windowKey,
    int? todayCount,
    int? bestCount,
    String? bestDayKey,
    bool? celebratedThisWindow,
  }) => DailyStats(
    windowKey: windowKey ?? this.windowKey,
    todayCount: todayCount ?? this.todayCount,
    bestCount: bestCount ?? this.bestCount,
    bestDayKey: bestDayKey ?? this.bestDayKey,
    celebratedThisWindow: celebratedThisWindow ?? this.celebratedThisWindow,
  );

  @override
  bool operator ==(Object other) =>
      other is DailyStats &&
      other.windowKey == windowKey &&
      other.todayCount == todayCount &&
      other.bestCount == bestCount &&
      other.bestDayKey == bestDayKey &&
      other.celebratedThisWindow == celebratedThisWindow;

  @override
  int get hashCode => Object.hash(
    windowKey,
    todayCount,
    bestCount,
    bestDayKey,
    celebratedThisWindow,
  );

  @override
  String toString() =>
      'DailyStats($windowKey: $todayCount, best $bestCount @ $bestDayKey'
      '${celebratedThisWindow ? ', celebrato' : ''})';
}

/// Applica un tap (±1) alla finestra corrente.
///
/// Il record fa **ratchet in linea**: appena il giornaliero lo supera, il
/// best si aggiorna subito e non ridiscende mai. Così la chiusura di
/// mezzogiorno non deve "consolidare" niente e non esiste una doppia
/// scrittura del record da tenere d'accordo.
DailyStats applyTapDelta(DailyStats stats, int delta) {
  final int today = stats.todayCount + delta;
  if (today > stats.bestCount) {
    return stats.copyWith(
      todayCount: today,
      bestCount: today,
      bestDayKey: stats.windowKey,
    );
  }
  return stats.copyWith(todayCount: today);
}

/// La festa del record parte con questo tap?
///
/// Vero quando il giornaliero ha appena superato il best precedente e in
/// questa finestra non si è ancora festeggiato. Il record parte da 0, quindi
/// **il primissimo mad dog del primissimo giorno è già un record** (decisione
/// del committente, design/mockups/DECISIONS.md → 01).
bool shouldCelebrateRecord(DailyStats before, DailyStats after) =>
    !before.celebratedThisWindow && after.todayCount > before.bestCount;
