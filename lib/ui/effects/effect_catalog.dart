/// Il catalogo degli effetti.
///
/// Regola 5 di ANIMATIONS_SPEC: un effetto = un modulo. Aggiungerne uno nuovo
/// vuol dire aggiungere il suo file in `effects/` e una riga qui, senza
/// toccare il motore, il numerone o gli altri effetti.
///
/// Un effetto può agire su due piani, e il catalogo li tiene separati:
/// - [effectOverlays]: un widget a tutto schermo sopra la scena (i fuochi, la
///   palla da bowling);
/// - [digitTransforms]: una trasformazione applicata a ogni cifra del numerone
///   (il tremolio del 67, le cifre che volano come birilli).
library;

import 'package:flutter/widgets.dart';

import '../../config.dart';
import '../../state/effect_triggers.dart';
import 'fireworks_effect.dart';
import 'shake_effect.dart';
import 'strike_effect.dart';

/// Come si comporta un effetto in coda.
class EffectSpec {
  const EffectSpec({
    required this.duration,
    required this.sound,
    this.followUpSound,
    this.followUpDelay,
  });

  /// Quanto resta in scena. Il motore usa questa per la durata e per
  /// l'ordinamento della coda.
  final Duration duration;

  /// Suono riprodotto all'inizio dell'effetto.
  final String sound;

  /// Secondo suono, per gli effetti in due tempi (lo strike: prima il
  /// rotolamento, poi l'impatto).
  final String? followUpSound;

  /// Quando parte [followUpSound], dall'inizio dell'effetto.
  final Duration? followUpDelay;
}

/// I metadati di ogni effetto del catalogo.
const Map<EffectKind, EffectSpec> effectCatalog = <EffectKind, EffectSpec>{
  EffectKind.shake67: EffectSpec(
    duration: kShake67Duration,
    sound: kSfxWobble67,
  ),
  EffectKind.fireworks: EffectSpec(
    duration: kFireworksDuration,
    sound: kSfxFireworks,
  ),
  EffectKind.strike: EffectSpec(
    duration: kStrikeDuration,
    sound: kSfxBowlingRoll,
    followUpSound: kSfxBowlingStrike,
    followUpDelay: kStrikeImpactDelay,
  ),
};

/// Dove si trova una cifra e a che punto è l'effetto.
class DigitContext {
  const DigitContext({
    required this.index,
    required this.digitCount,
    required this.progress,
  });

  /// Posizione della cifra, da sinistra.
  final int index;

  /// Quante cifre ha il numero in tutto.
  final int digitCount;

  /// Avanzamento dell'effetto, da 0 a 1.
  final double progress;

  /// Posizione della cifra rispetto al centro, da −1 (sinistra) a 1 (destra).
  /// Serve agli effetti che devono spingere le cifre verso l'esterno.
  double get offsetFromCenter {
    if (digitCount <= 1) return 0;
    return (index / (digitCount - 1)) * 2 - 1;
  }
}

/// Trasforma una cifra del numerone.
typedef DigitTransform = Widget Function(DigitContext context, Widget digit);

/// I widget a tutto schermo, uno per effetto che ne ha bisogno.
const Map<EffectKind, WidgetBuilder> effectOverlays =
    <EffectKind, WidgetBuilder>{
      EffectKind.fireworks: buildFireworksOverlay,
      EffectKind.strike: buildStrikeOverlay,
    };

/// Le trasformazioni delle cifre, una per effetto che ne ha bisogno.
const Map<EffectKind, DigitTransform> digitTransforms =
    <EffectKind, DigitTransform>{
      EffectKind.shake67: shakeDigit,
      EffectKind.fireworks: gildDigit,
      EffectKind.strike: scatterDigit,
    };

/// La durata di un effetto secondo il catalogo.
Duration durationOf(EffectKind kind) => effectCatalog[kind]!.duration;
