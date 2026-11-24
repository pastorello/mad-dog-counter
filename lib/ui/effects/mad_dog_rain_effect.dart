/// Effetto milestone 10.000 — la pioggia di Mad Dog.
///
/// L'idea parcheggiata nel backlog di ANIMATIONS_SPEC, promossa dalla v2 e
/// approvata nei mockup (design/mockups/DECISIONS.md → 03): una pioggia
/// FITTA di bicchierini shot a piena opacità — non l'atmosfera della
/// `ComboRain`, l'evento vero — che sul finale vira tutta in oro, mentre le
/// cifre si indorano col `gildDigit` dei fuochi. La campanella dello strike
/// suona sul finale (followUp del catalogo).
///
/// La `ComboRain` d'atmosfera si ritira da sola quando c'è un effetto in
/// coda in scena (counter_screen la spegne con `effects.current != null`).
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../config.dart';
import '../widgets/homd_mark.dart' show ShotGlassPainter;

Widget buildMadDogRainOverlay(BuildContext context) => const _MadDogRain();

class _MadDogRain extends StatefulWidget {
  const _MadDogRain();

  @override
  State<_MadDogRain> createState() => _MadDogRainState();
}

class _MadDogRainState extends State<_MadDogRain>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: kMadDogRainDuration,
  )..forward();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          return RepaintBoundary(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (BuildContext context, Widget? _) {
                final double t = _controller.value;
                // Sfuma sull'ultimissimo tratto, così il motore che toglie
                // l'overlay non la taglia di netto.
                final double opacity = t > 0.92 ? (1 - t) / 0.08 : 1.0;
                final bool gold = t >= kMadDogRainGoldStart;
                return Opacity(
                  opacity: opacity.clamp(0.0, 1.0),
                  child: Stack(
                    children: <Widget>[
                      for (int i = 0; i < kMadDogRainDropCount; i++)
                        _Drop(
                          index: i,
                          progress: t,
                          gold: gold,
                          area: constraints.biggest,
                        ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _Drop extends StatelessWidget {
  const _Drop({
    required this.index,
    required this.progress,
    required this.gold,
    required this.area,
  });

  final int index;
  final double progress;
  final bool gold;
  final Size area;

  /// Spirale aurea: sparge gli indici senza allinearli né sembrare a
  /// griglia, senza numeri casuali (come la ComboRain).
  static const double _goldenRatioConjugate = 0.61803398875;

  @override
  Widget build(BuildContext context) {
    // Ogni bicchierino ha taglia, colonna e fase sue, deterministiche.
    final double u = (index * _goldenRatioConjugate) % 1.0;
    final double size =
        kMadDogRainDropSizeMin +
        u * (kMadDogRainDropSizeMax - kMadDogRainDropSizeMin);
    final double width = size * 118.94 / 126.15;

    final double cycle =
        kMadDogRainFallDuration.inMilliseconds /
        kMadDogRainDuration.inMilliseconds;
    final double phase = index / kMadDogRainDropCount;
    final double t = (progress / cycle + phase) % 1.0;

    final double x =
        ((index * _goldenRatioConjugate * 1.37) % 1.0) *
        math.max(0, area.width - width);
    final double y = -size + t * (area.height + size * 2);
    final double angle = t * 2 * math.pi * (index.isEven ? 1 : -1) * 0.6;

    return Positioned(
      left: x,
      top: y,
      child: Transform.rotate(
        angle: angle,
        // RepaintBoundary sul singolo bicchierino, come nella ComboRain:
        // la sagoma si rasterizza una volta per colore e poi si ricompone.
        child: RepaintBoundary(
          child: SizedBox(
            height: size,
            width: width,
            child: CustomPaint(
              painter: ShotGlassPainter(
                color: gold ? kCelebrationGold : kPrimaryRed,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
