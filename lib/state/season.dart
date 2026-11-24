/// Le "stagioni" del tabellone: temi scelti A MANO dal pannello.
///
/// Ridefinite dal committente nella Fase 0 (design/mockups/DECISIONS.md →
/// 06): niente automatismo per data — la voce «Stagione» del pannello parte
/// con Nessuna / Halloween / Natale, e l'elenco è pensato per crescere.
///
/// Regola d'oro 3: enum puro, niente storage né widget. La persistenza
/// passa da [SettingsRepository], la resa da `SeasonalBackground`.
library;

enum Season {
  /// Il tabellone com'è sempre stato. Il default.
  none,

  /// Cornice arancio zucca, pipistrelli e zucche ai 4 angoli.
  halloween,

  /// Cornice verde abete, palline, pacchi e bastoncini di zucchero, neve.
  christmas;

  /// Il valore scritto in prefs. Il nome dell'enum È il contratto: non
  /// rinominare i case senza una migrazione.
  String get dbValue => name;

  /// Dal valore in prefs; qualunque cosa non riconosciuta è [none], così
  /// una pref corrotta non rompe mai il tabellone.
  static Season fromDbValue(String? value) => Season.values.firstWhere(
    (Season s) => s.dbValue == value,
    orElse: () => Season.none,
  );
}
