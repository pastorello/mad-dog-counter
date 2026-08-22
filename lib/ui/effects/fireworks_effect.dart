/// Effetto 3 — multiplo di 100: fuochi d'artificio.
///
/// Due piani: i coriandoli a tutto schermo ([buildFireworksOverlay]) e il
/// numero che brilla dorato ([gildDigit]).
library;

import 'dart:math' as math;

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';

import '../../config.dart';
import 'effect_catalog.dart';

Widget buildFireworksOverlay(BuildContext context) => const _Fireworks();

/// Colori dei coriandoli: oro dei momenti epici, rosso e blu di brand.
/// Niente bianco puro, niente rosa (UX_UI_SPEC → palette).
const List<Color> _confettiColors = <Color>[
  kCelebrationGold,
  kPrimaryRed,
  kTextColor,
  kAccentBlue,
];

class _Fireworks extends StatefulWidget {
  const _Fireworks();

  @override
  State<_Fireworks> createState() => _FireworksState();
}

class _FireworksState extends State<_Fireworks> {
  late final ConfettiController _left;
  late final ConfettiController _right;

  @override
  void initState() {
    super.initState();
    // I due controller emettono per la durata dell'effetto; il motore toglie
    // l'overlay dall'albero quando l'effetto finisce.
    _left = ConfettiController(duration: kFireworksDuration)..play();
    _right = ConfettiController(duration: kFireworksDuration)..play();
  }

  @override
  void dispose() {
    _left.dispose();
    _right.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: <Widget>[
          // Le due salve partono dagli angoli bassi e sparano verso il
          // centro alto: quella di sinistra copre la metà sinistra dello
          // schermo, quella di destra la metà destra, e si incontrano in
          // mezzo attraversando il numerone.
          Align(
            alignment: Alignment.bottomLeft,
            child: _Blast(controller: _left, direction: -kFireworksBlastAngle),
          ),
          Align(
            alignment: Alignment.bottomRight,
            child: _Blast(
              controller: _right,
              direction: -(math.pi - kFireworksBlastAngle),
            ),
          ),
        ],
      ),
    );
  }
}

/// Una delle due salve. Le due differiscono solo per angolo di tiro: tutto
/// il resto della taratura è identico e vive in `config.dart`.
class _Blast extends StatelessWidget {
  const _Blast({required this.controller, required this.direction});

  final ConfettiController controller;

  /// Verso cui spara, in radianti.
  final double direction;

  @override
  Widget build(BuildContext context) {
    return ConfettiWidget(
      confettiController: controller,
      blastDirection: direction,
      emissionFrequency: kFireworksEmissionFrequency,
      numberOfParticles: kFireworksParticles,
      maxBlastForce: kFireworksBlastForceMax,
      minBlastForce: kFireworksBlastForceMin,
      particleDrag: kFireworksDrag,
      gravity: kFireworksGravity,
      colors: _confettiColors,
    );
  }
}

/// Il numero brilla dorato per qualche secondo.
///
/// Il bagliore entra e si spegne dolcemente: sbattere sull'oro e tornare
/// bianco di scatto stonerebbe con i coriandoli che continuano a scendere.
Widget gildDigit(DigitContext context, Widget digit) {
  final double t = context.progress;
  // Rampa: sale nel primo 15%, tiene, cala nell'ultimo 35%.
  final double intensity = t < 0.15
      ? t / 0.15
      : (t > 0.65 ? math.max(0, (1 - t) / 0.35) : 1);

  return ShaderMask(
    blendMode: BlendMode.srcATop,
    shaderCallback: (Rect bounds) => LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: <Color>[
        Color.lerp(kTextColor, kCelebrationGold, intensity)!,
        Color.lerp(kTextColor, kPrimaryRed, intensity * 0.6)!,
      ],
    ).createShader(bounds),
    child: digit,
  );
}
