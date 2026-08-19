/// Effetto 4 — multiplo di 1000: Strike!
///
/// Una palla da bowling entra da sinistra, colpisce il numerone e spacca le
/// cifre per aria come birilli; poi il contatore si ricompone tremolando.
///
/// L'effetto vive su due piani: la palla è un overlay
/// ([buildStrikeOverlay]), il volo delle cifre è una trasformazione del
/// numerone ([scatterDigit]). I due sono sincronizzati sulla stessa fase di
/// impatto, [_impactAt].
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../config.dart';
import 'effect_catalog.dart';

/// Istante dell'impatto, come frazione della durata dell'effetto.
/// Coincide con [kStrikeImpactDelay], che è anche quando parte il suono
/// dell'impatto: palla, cifre e audio colpiscono insieme.
final double _impactAt =
    kStrikeImpactDelay.inMilliseconds / kStrikeDuration.inMilliseconds;

Widget buildStrikeOverlay(BuildContext context) => const _StrikeOverlay();

/// I due pezzi dell'overlay: la palla che attraversa e la parola che sbatte
/// in alto al centro, nella stessa fascia dei testi della combo.
class _StrikeOverlay extends StatelessWidget {
  const _StrikeOverlay();

  @override
  Widget build(BuildContext context) {
    return const Stack(
      children: <Widget>[
        Positioned.fill(child: _BowlingBall()),
        Positioned(
          top: kTopOverlayTop,
          left: 0,
          right: 0,
          child: _StrikeWord(),
        ),
      ],
    );
  }
}

/// «STRIKE!»: compare all'impatto, non prima — la palla deve arrivarci.
class _StrikeWord extends StatelessWidget {
  const _StrikeWord();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: 1),
        duration: kStrikeDuration,
        builder: (BuildContext context, double t, Widget? child) {
          // Prima dell'impatto non c'è niente da vedere.
          if (t < _impactAt) return const SizedBox.shrink();

          // Tempo della parola: 0 all'impatto, 1 a fine effetto.
          final double u = (t - _impactAt) / (1 - _impactAt);
          // Entra di schianto e rimbalza appena, poi sfuma sul finale.
          final double punch = u < 0.18 ? 1.6 - 0.6 * (u / 0.18) : 1;
          final double opacity = u > 0.72 ? math.max(0, (1 - u) / 0.28) : 1;

          return Opacity(
            opacity: opacity,
            child: Transform.scale(scale: punch, child: child),
          );
        },
        child: const Text(
          kStrikeText,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: kDisplayFont,
            fontSize: kStrikeTextSize,
            color: kCelebrationGold,
            shadows: <Shadow>[
              Shadow(color: kPrimaryRed, blurRadius: 24),
              Shadow(color: kBackground, blurRadius: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _BowlingBall extends StatelessWidget {
  const _BowlingBall();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final double diameter = constraints.maxHeight * 0.28;
          return TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: 1),
            duration: kStrikeDuration,
            builder: (BuildContext context, double t, Widget? child) {
              // Prima dell'impatto la palla rotola da fuori schermo fino al
              // centro; dopo prosegue e esce a destra, più veloce.
              final double travel;
              if (t <= _impactAt) {
                travel = (t / _impactAt) * 0.5;
              } else {
                travel = 0.5 + ((t - _impactAt) / (1 - _impactAt)) * 0.9;
              }
              final double x =
                  -diameter + travel * (constraints.maxWidth + diameter);

              return Transform.translate(
                offset: Offset(x, constraints.maxHeight / 2 - diameter / 2),
                // Rotola davvero: l'angolo segue la distanza percorsa.
                child: Transform.rotate(
                  angle: travel * 4 * math.pi,
                  child: child,
                ),
              );
            },
            child: _BallGraphic(diameter: diameter),
          );
        },
      ),
    );
  }
}

/// La palla: sfera scura con i tre fori, disegnata invece che importata —
/// non c'è un asset di brand per questo.
class _BallGraphic extends StatelessWidget {
  const _BallGraphic({required this.diameter});

  final double diameter;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const RadialGradient(
          center: Alignment(-0.35, -0.35),
          colors: <Color>[kSurfaceNavy, kBackground],
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: kAccentBlue.withValues(alpha: 0.45),
            blurRadius: diameter * 0.25,
          ),
        ],
      ),
      child: CustomPaint(painter: _FingerHolesPainter()),
    );
  }
}

class _FingerHolesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()..color = kBackground;
    final double r = size.width * 0.055;
    final Offset centre = Offset(size.width * 0.42, size.height * 0.38);
    canvas.drawCircle(centre, r, paint);
    canvas.drawCircle(centre + Offset(size.width * 0.16, 0), r, paint);
    canvas.drawCircle(
      centre + Offset(size.width * 0.08, size.height * 0.15),
      r,
      paint,
    );
  }

  @override
  bool shouldRepaint(_FingerHolesPainter oldDelegate) => false;
}

/// Le cifre volano come birilli, poi si ricompongono tremolando.
Widget scatterDigit(DigitContext context, Widget digit) {
  final double t = context.progress;

  // Prima dell'impatto il numero sta fermo: la palla deve ancora arrivare.
  if (t < _impactAt) return digit;

  // Fase di volo e ritorno, da 0 a 1 dopo l'impatto.
  final double f = ((t - _impactAt) / (1 - _impactAt)).clamp(0.0, 1.0);

  // Le cifre schizzano e rientrano: la campana sale in fretta e rientra
  // piano, come un birillo che vola e ricade.
  final double flight = math.sin(f * math.pi) * (1 - f * 0.35);

  // Ogni cifra parte per la sua strada: quelle di bordo più lontano, con una
  // rotazione di verso opposto. Deterministico sull'indice, non casuale:
  // due build dello stesso istante devono dare lo stesso fotogramma.
  final double side = context.offsetFromCenter;
  final int index = context.index;
  final double dx = side * 260 * flight;
  final double dy = -(90 + (index % 3) * 55) * flight;
  final double angle = (index.isEven ? 1 : -1) * 2.2 * flight;

  // Il tremolio finale della ricomposizione.
  final double wobble = f > 0.8
      ? math.sin((f - 0.8) / 0.2 * 6 * math.pi) * 5 * (1 - (f - 0.8) / 0.2)
      : 0;

  return Transform.translate(
    offset: Offset(dx + wobble, dy),
    child: Transform.rotate(angle: angle, child: digit),
  );
}
