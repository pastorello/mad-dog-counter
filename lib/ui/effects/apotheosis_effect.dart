/// Effetto milestone 100.000 — l'apoteosi.
///
/// Il momento più raro e più epico di tutti, approvato nei mockup
/// (design/mockups/DECISIONS.md → 03): mega-salve tricolori (i colori della
/// bandierina: rosso, ink, blu, più l'oro), bagliore dorato che cresce, la
/// scritta APOTEOSI in oro, e sul finale il lampo del botto (l'esplosione
/// del panico, riusata come suono di apice). Le cifre volano con lo
/// `scatterDigit` dello strike, riusato dal catalogo.
library;

import 'dart:math' as math;

import 'package:confetti/confetti.dart';
import 'package:material_ui/material_ui.dart';

import '../../config.dart';

Widget buildApotheosisOverlay(BuildContext context) => const _Apotheosis();

/// I colori della bandierina più l'oro: niente bianco puro, niente rosa.
const List<Color> _apotheosisColors = <Color>[
  kPrimaryRed,
  kTextColor,
  kAccentBlue,
  kCelebrationGold,
];

class _Apotheosis extends StatefulWidget {
  const _Apotheosis();

  @override
  State<_Apotheosis> createState() => _ApotheosisState();
}

class _ApotheosisState extends State<_Apotheosis>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: kApotheosisDuration,
  )..forward();

  late final ConfettiController _left;
  late final ConfettiController _right;
  late final ConfettiController _center;

  @override
  void initState() {
    super.initState();
    _left = ConfettiController(duration: kApotheosisDuration)..play();
    _right = ConfettiController(duration: kApotheosisDuration)..play();
    _center = ConfettiController(duration: kApotheosisDuration)..play();
  }

  @override
  void dispose() {
    _left.dispose();
    _right.dispose();
    _center.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (BuildContext context, Widget? _) {
          final double t = _controller.value;

          // Il bagliore dorato cresce per tutta la durata e si spegne in coda.
          final double glow = t > 0.92
              ? math.max(0, (1 - t) / 0.08)
              : math.min(1, t / 0.3);

          // La scritta entra di schianto a kApotheosisTextStart.
          final double textT = ((t - kApotheosisTextStart) / 0.1).clamp(
            0.0,
            1.0,
          );
          final double textScale = Curves.elasticOut.transform(textT);

          // Il lampo del botto: picco secco a kApotheosisBlastStart, poi
          // decade. In oro/ink, mai bianco puro.
          final double sinceBlast = t - kApotheosisBlastStart;
          final double flash = sinceBlast < 0
              ? 0
              : math.max(0, 1 - sinceBlast / 0.18);

          return Stack(
            children: <Widget>[
              // Bagliore dorato di fondo, dal centro.
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      radius: kComboGlowRadius,
                      colors: <Color>[
                        kCelebrationGold.withValues(alpha: 0.30 * glow),
                        kPrimaryRed.withValues(alpha: 0.14 * glow),
                        Colors.transparent,
                      ],
                      stops: const <double>[0.0, 0.45, 1.0],
                    ),
                  ),
                ),
              ),

              // Le tre salve: angoli bassi verso il centro, più una dritta
              // in alto dal bordo basso. Taratura dei fuochi, ma più fitta.
              Align(
                alignment: Alignment.bottomLeft,
                child: _Blast(
                  controller: _left,
                  direction: -kFireworksBlastAngle,
                ),
              ),
              Align(
                alignment: Alignment.bottomRight,
                child: _Blast(
                  controller: _right,
                  direction: -(math.pi - kFireworksBlastAngle),
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: _Blast(controller: _center, direction: -math.pi / 2),
              ),

              // APOTEOSI, in oro, nella fascia alta.
              if (textT > 0)
                Positioned(
                  top: kTopOverlayTop,
                  left: 0,
                  right: 0,
                  child: Transform.scale(
                    scale: textScale,
                    child: const Text(
                      kApotheosisText,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: kDisplayFont,
                        fontSize: kApotheosisTextSize,
                        height: 1,
                        color: kCelebrationGold,
                        shadows: <Shadow>[
                          Shadow(color: kPrimaryRed, blurRadius: 28),
                          Shadow(color: kCelebrationGold, blurRadius: 60),
                        ],
                      ),
                    ),
                  ),
                ),

              // Il lampo finale.
              if (flash > 0)
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        radius: 1.4,
                        colors: <Color>[
                          kTextColor.withValues(alpha: 0.55 * flash),
                          kCelebrationGold.withValues(alpha: 0.35 * flash),
                          Colors.transparent,
                        ],
                        stops: const <double>[0.0, 0.4, 1.0],
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

/// Una salva dell'apoteosi: la taratura dei fuochi con più coriandoli.
class _Blast extends StatelessWidget {
  const _Blast({required this.controller, required this.direction});

  final ConfettiController controller;
  final double direction;

  @override
  Widget build(BuildContext context) {
    return ConfettiWidget(
      confettiController: controller,
      blastDirection: direction,
      emissionFrequency: kFireworksEmissionFrequency,
      numberOfParticles: kApotheosisParticles,
      maxBlastForce: kFireworksBlastForceMax,
      minBlastForce: kFireworksBlastForceMin,
      particleDrag: kFireworksDrag,
      gravity: kFireworksGravity,
      colors: _apotheosisColors,
    );
  }
}
