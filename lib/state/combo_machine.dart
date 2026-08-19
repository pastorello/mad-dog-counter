/// La macchina a stati della combo, in forma pura.
///
/// Regola d'oro 3 (CLAUDE.md): niente storage, niente widget, niente timer.
/// Il tempo lo gestisce chi la usa ([ComboController]); qui c'è solo la
/// domanda «con N tap consecutivi, cosa si vede e cosa si sente?».
library;

import 'dart:math' as math;

import '../config.dart';

/// Lo stato della combo, derivato interamente dal numero di tap consecutivi.
///
/// Immutabile e senza logica temporale: due stati con lo stesso [count] sono
/// indistinguibili, il che rende i test banali da scrivere.
class ComboState {
  const ComboState(this.count);

  /// Nessuna combo in corso.
  static const ComboState idle = ComboState(0);

  /// Tap di incremento consecutivi entro la finestra di [kComboWindow].
  final int count;

  /// La combo è visibile a schermo.
  bool get isActive => count >= kComboMinCount;

  /// Il moltiplicatore mostrato: è il conteggio stesso.
  ///
  /// La spec cita «x2, x3, x5...» come esempio di scala che sale; qui la
  /// scala è il conteggio, senza salti inventati. Se i baristi vorranno una
  /// progressione diversa, si cambia questo getter e basta.
  int get multiplier => count;

  /// Quante soglie di [kComboThresholds] sono state superate.
  /// 0 = nessun testo celebrativo ancora.
  int get level {
    int reached = 0;
    for (final int threshold in kComboThresholds) {
      if (count >= threshold) reached++;
    }
    return reached;
  }

  /// Il testo celebrativo del livello corrente, se c'è.
  String? get text => level == 0 ? null : kComboTexts[level - 1];

  /// Il pitch del pop a questo punto della combo: sale a ogni tap,
  /// col tetto di [kComboPitchMax] perché non diventi un fischio.
  double get pitch =>
      math.min(kComboPitchMax, 1.0 + math.max(0, count - 1) * kComboPitchStep);

  /// La combo è abbastanza lunga da far comparire Ciommo.
  ///
  /// PROVVISORIO: soglia da confermare col committente, esiste una variante
  /// basata sui cicchetti di sessione (CLAUDE.md → Domande aperte).
  bool get showsCiommo => count >= kComboCiommoThreshold;

  /// Quanti timbri di Ciommo a schermo: più la combo cresce, più ne spuntano.
  int get ciommoStamps {
    if (!showsCiommo) return 0;
    return math.min(kComboCiommoMaxStamps, count - kComboCiommoThreshold + 1);
  }

  /// Il tap successivo, dentro la finestra.
  ComboState next() => ComboState(count + 1);

  @override
  bool operator ==(Object other) => other is ComboState && other.count == count;

  @override
  int get hashCode => count.hashCode;

  @override
  String toString() => 'ComboState($count)';
}

/// Se passando da [before] a [after] si è superata una nuova soglia.
/// È il momento in cui suona il "ta-daa" e cambia il testo celebrativo.
bool crossedThreshold(ComboState before, ComboState after) =>
    after.level > before.level;
