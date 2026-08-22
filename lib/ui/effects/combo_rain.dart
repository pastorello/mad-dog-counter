/// Pioggia di bicchierini durante la combo.
///
/// Puro sfondo: bicchierini piccoli e trasparenti cadono dall'alto in loop
/// finché la combo resta viva. Non è l'evento — quelli sono il moltiplicatore,
/// il testo celebrativo e i timbri "Ciommo Approved" — quindi resta dietro a
/// tutto e non compete con loro per l'attenzione (ANIMATIONS_SPEC → Combo).
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../config.dart';
import '../widgets/homd_mark.dart' show ShotGlassPainter;

class ComboRain extends StatefulWidget {
  const ComboRain({super.key});

  @override
  State<ComboRain> createState() => _ComboRainState();
}

class _ComboRainState extends State<ComboRain>
    with SingleTickerProviderStateMixin {
  // Il montaggio/smontaggio di ComboRain segue già quello di ComboOverlay
  // (che la mostra solo mentre la combo è attiva o in dissolvenza): qui
  // basta girare finché il widget esiste.
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: kComboRainCycleDuration,
  )..repeat();

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
                return Stack(
                  children: <Widget>[
                    for (int i = 0; i < kComboRainDropCount; i++)
                      _RainDrop(
                        index: i,
                        progress: _controller.value,
                        area: constraints.biggest,
                      ),
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _RainDrop extends StatelessWidget {
  const _RainDrop({
    required this.index,
    required this.progress,
    required this.area,
  });

  final int index;
  final double progress;
  final Size area;

  /// Spirale aurea: sparge gli indici sulla larghezza senza allinearli né
  /// farli sembrare a griglia, senza bisogno di numeri casuali.
  static const double _goldenRatioConjugate = 0.61803398875;

  @override
  Widget build(BuildContext context) {
    // Ogni bicchierino parte a un punto diverso del ciclo, cosi' non cadono
    // tutti insieme: due build dello stesso stato danno lo stesso risultato,
    // come i timbri Ciommo.
    final double phase = index / kComboRainDropCount;
    final double t = (progress + phase) % 1.0;
    final double xFraction = (index * _goldenRatioConjugate) % 1.0;

    final double x = xFraction * math.max(0, area.width - kComboRainDropSize);
    final double y =
        -kComboRainDropSize + t * (area.height + kComboRainDropSize * 2);
    final double angle = t * 2 * math.pi * (index.isEven ? 1 : -1);

    return Positioned(
      left: x,
      top: y,
      child: Opacity(
        opacity: kComboRainOpacity,
        child: Transform.rotate(
          angle: angle,
          child: SizedBox(
            height: kComboRainDropSize,
            width: kComboRainDropSize * 400 / 460,
            child: CustomPaint(painter: ShotGlassPainter()),
          ),
        ),
      ),
    );
  }
}
