/// NUOVO RECORD! — la celebrazione del record giornaliero.
///
/// Un modulo autonomo del catalogo (regola 5): overlay a tutto schermo con la
/// scritta in oro nella fascia alta e un alone caldo; le cifre si indorano
/// col [gildDigit] dei fuochi, riusato dal catalogo. Visual approvato nei
/// mockup (design/mockups/DECISIONS.md → 03).
library;

import 'package:flutter/widgets.dart';

import '../../config.dart';

Widget buildRecordCelebrationOverlay(BuildContext context) =>
    const _RecordCelebration();

class _RecordCelebration extends StatelessWidget {
  const _RecordCelebration();

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: kRecordCelebrationDuration,
      builder: (BuildContext context, double t, Widget? child) {
        // Entra di schianto, resta piena, sfuma sul finale.
        final double appear = Curves.elasticOut.transform(
          (t * 4).clamp(0.0, 1.0),
        );
        final double fade = t < 0.85 ? 1.0 : 1 - (t - 0.85) / 0.15;
        return Opacity(
          opacity: fade.clamp(0.0, 1.0),
          child: Stack(
            children: <Widget>[
              // L'alone caldo attorno al numerone, come il glow della combo
              // ma in oro: è festa, non combo.
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    radius: kComboGlowRadius,
                    colors: <Color>[
                      kCelebrationGold.withValues(alpha: 0.25 * appear),
                      kPrimaryRed.withValues(alpha: 0.10 * appear),
                      const Color(0x00000000),
                    ],
                    stops: const <double>[0.0, 0.45, 1.0],
                  ),
                ),
                child: const SizedBox.expand(),
              ),
              Positioned(
                top: kTopOverlayTop,
                left: 0,
                right: 0,
                child: Transform.scale(
                  scale: appear,
                  child: const Text(
                    kRecordText,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: kDisplayFont,
                      fontSize: kRecordTextSize,
                      height: 1,
                      color: kCelebrationGold,
                      shadows: <Shadow>[
                        Shadow(color: kPrimaryRed, blurRadius: 24),
                        Shadow(color: kCelebrationGold, blurRadius: 48),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
