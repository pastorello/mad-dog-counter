/// Il catalogo degli effetti.
///
/// Regola 5 di ANIMATIONS_SPEC: un effetto = un modulo. Aggiungerne uno nuovo
/// vuol dire aggiungere una voce qui e il suo widget, senza toccare gli altri
/// né il motore.
///
/// Il catalogo tiene i **metadati** (durata, suono); il widget che disegna
/// l'effetto lo si registra in [effectBuilders].
library;

import 'package:flutter/widgets.dart';

import '../../config.dart';
import '../../state/effect_triggers.dart';

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

/// I widget che disegnano gli effetti.
///
/// Vuoto di proposito: il motore, la coda e l'audio funzionano già: quando un
/// effetto non ha ancora un widget, si sente il suono e scorre la sua durata.
/// Registrare qui il builder è l'unico passo per dargli una faccia.
const Map<EffectKind, WidgetBuilder>
effectBuilders = <EffectKind, WidgetBuilder>{
  // EffectKind.fireworks: (BuildContext context) => const FireworksEffect(),
  // EffectKind.strike: (BuildContext context) => const StrikeEffect(),
  // EffectKind.shake67: (BuildContext context) => const Shake67Effect(),
};

/// La durata di un effetto secondo il catalogo.
Duration durationOf(EffectKind kind) => effectCatalog[kind]!.duration;
