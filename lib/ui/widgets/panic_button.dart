/// Il pulsante panico: kill switch degli effetti.
///
/// Piccolo e discreto, con padding generoso che lo isola dalla zona +1: i suoi
/// tap NON devono contare come incrementi (FUNCTIONAL_SPEC → Pulsante panico).
/// Sta sopra le zone di tap nello Stack, quindi intercetta il tocco prima che
/// arrivi al contatore.
library;

import 'package:flutter/material.dart';

import '../../config.dart';

class PanicButton extends StatelessWidget {
  const PanicButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Ferma tutti gli effetti',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onPressed,
        // Il padding e' area di tocco morta attorno all'icona: separa il
        // pulsante dalla zona +1 senza renderlo grande e vistoso.
        child: const Padding(
          padding: EdgeInsets.all(28),
          child: Icon(
            Icons.highlight_off,
            size: 30,
            color: Color(0x59F0F0F0), // bianco sporco molto attenuato
          ),
        ),
      ),
    );
  }
}

/// L'esplosione a tutto schermo che maschera il kill switch.
///
/// Non è decorazione: sotto questa maschera il motore svuota la coda e ferma
/// tutto, e quando svanisce resta la schermata pulita col numerone.
class PanicBlast extends StatelessWidget {
  const PanicBlast({super.key});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: 1),
        duration: kPanicBlastDuration,
        curve: Curves.easeOut,
        builder: (BuildContext context, double t, Widget? child) {
          // Lampo che si apre e sbianca, poi svanisce.
          final double opacity = t < 0.25 ? 1.0 : (1 - (t - 0.25) / 0.75);
          return Opacity(
            opacity: opacity.clamp(0.0, 1.0),
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  radius: 0.2 + t * 1.6,
                  colors: const <Color>[
                    kCelebrationGold,
                    kPrimaryRed,
                    kBackground,
                  ],
                  stops: const <double>[0.0, 0.45, 1.0],
                ),
              ),
              child: const SizedBox.expand(),
            ),
          );
        },
      ),
    );
  }
}
