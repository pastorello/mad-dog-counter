/// La scena TILT: troppi mad dog troppo in fretta.
///
/// È SOLO scenografia (regola d'oro 2): la radice è un [IgnorePointer],
/// i tap la attraversano e contano normalmente. Il tabellone "sembra"
/// bloccato — velo scuro, sfocatura, insegna TILT che vibra, barra del tempo
/// che si svuota — ma panico e ingranaggio restano sopra la scena (le vie
/// d'uscita) e il conteggio sotto non si ferma mai.
///
/// Look deciso nei mockup (design/mockups/DECISIONS.md → 07).
library;

import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

import '../../config.dart';

class TiltOverlay extends StatefulWidget {
  const TiltOverlay({super.key, required this.message, required this.duration});

  /// Il messaggio sotto all'insegna (personalizzabile dal pannello).
  final String message;

  /// Quanto dura la scena: la barra si svuota in questo tempo.
  final Duration duration;

  @override
  State<TiltOverlay> createState() => _TiltOverlayState();
}

class _TiltOverlayState extends State<TiltOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shake;

  @override
  void initState() {
    super.initState();
    _shake = AnimationController(vsync: this, duration: kTiltShakePeriod)
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _shake.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: ClipRect(
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(
            sigmaX: kTiltBlurSigma,
            sigmaY: kTiltBlurSigma,
          ),
          child: ColoredBox(
            color: kBackground.withValues(alpha: kTiltVeilAlpha),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  // L'insegna. FittedBox: su uno schermo più basso del
                  // tablet di produzione si rimpicciolisce invece di
                  // traboccare.
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: AnimatedBuilder(
                        animation: _shake,
                        builder: (BuildContext context, Widget? child) {
                          final double t = _shake.value * 2 - 1;
                          return Transform.translate(
                            offset: Offset(
                              t * kTiltShakeOffset,
                              -t * kTiltShakeOffset,
                            ),
                            child: Transform.rotate(
                              angle: t * 0.004,
                              child: child,
                            ),
                          );
                        },
                        child: const Text(
                          kTiltTitle,
                          style: TextStyle(
                            fontFamily: kDisplayFont,
                            fontSize: kTiltTitleSize,
                            height: 1,
                            letterSpacing: kTiltTitleTracking,
                            color: kPrimaryRed,
                            shadows: <Shadow>[
                              Shadow(color: kPrimaryRed, blurRadius: 28),
                              Shadow(color: kPrimaryRed, blurRadius: 90),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    widget.message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: kBrandFont,
                      fontWeight: FontWeight.w700,
                      fontSize: kTiltMessageSize,
                      letterSpacing: kTiltMessageTracking,
                      color: kTextColor,
                    ),
                  ),
                  const SizedBox(height: 32),
                  _TimeLeftBar(duration: widget.duration),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// La barra rossa che si svuota: quanto manca alla fine del tilt.
class _TimeLeftBar extends StatelessWidget {
  const _TimeLeftBar({required this.duration});

  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: kTiltBarWidth,
      height: kTiltBarHeight,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0x33F0F0F0), width: 2),
        ),
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 1, end: 0),
          duration: duration,
          builder: (BuildContext context, double left, Widget? child) {
            return Align(
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: left,
                heightFactor: 1,
                child: const DecoratedBox(
                  decoration: BoxDecoration(
                    color: kPrimaryRed,
                    boxShadow: <BoxShadow>[
                      BoxShadow(color: kPrimaryRed, blurRadius: 14),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
