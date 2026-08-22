/// Pioggia di bicchierini durante la combo.
///
/// Atmosfera di sfondo: bicchierini trasparenti cadono dall'alto in loop
/// finché dura. Non è l'evento della combo lunga — quello sono i timbri
/// "Ciommo Approved" — quindi resta dietro a loro e al moltiplicatore
/// (ANIMATIONS_SPEC → Combo).
///
/// **Evento autonomo**: si accende e si spegne col suo flag [active], non è
/// annidato dentro `ComboOverlay`. I due effetti oggi partono insieme, ma
/// hanno soglie separate e possono prendere cadenze diverse senza che uno
/// debba toccare l'altro (regola d'oro 5: un effetto = un modulo).
library;

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../config.dart';
import '../widgets/homd_mark.dart' show ShotGlassPainter;

class ComboRain extends StatefulWidget {
  const ComboRain({super.key, required this.active});

  /// La pioggia deve cadere. A `false` sfuma e poi si smonta da sé.
  final bool active;

  @override
  State<ComboRain> createState() => _ComboRainState();
}

class _ComboRainState extends State<ComboRain>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: kComboRainCycleDuration,
  );

  /// Se c'è ancora qualcosa in scena: resta vero per tutta la dissolvenza,
  /// poi torna falso e l'albero si svuota. Senza, la pioggia resterebbe
  /// montata a opacità zero per il resto della sessione, con il suo ticker
  /// vivo (stessa trappola di P3 nell'audit prestazioni).
  bool _visible = false;

  Timer? _dismissTimer;

  @override
  void initState() {
    super.initState();
    if (widget.active) _start();
  }

  @override
  void didUpdateWidget(ComboRain oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !oldWidget.active) {
      _start();
    } else if (!widget.active && oldWidget.active) {
      _scheduleDismiss();
    }
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _start() {
    _dismissTimer?.cancel();
    _dismissTimer = null;
    _visible = true;
    _controller.repeat();
  }

  void _scheduleDismiss() {
    _dismissTimer?.cancel();
    _dismissTimer = Timer(kComboDismissDelay, () {
      if (!mounted) return;
      _controller.stop();
      setState(() => _visible = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_visible) return const SizedBox.shrink();

    return IgnorePointer(
      child: AnimatedOpacity(
        opacity: widget.active ? kComboRainOpacity : 0,
        duration: kComboFadeDuration,
        curve: Curves.easeOut,
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

    final double width = kComboRainDropSize * 118.94 / 126.15;
    final double x = xFraction * math.max(0, area.width - width);
    final double y =
        -kComboRainDropSize + t * (area.height + kComboRainDropSize * 2);
    final double angle = t * 2 * math.pi * (index.isEven ? 1 : -1);

    return Positioned(
      left: x,
      top: y,
      child: Transform.rotate(
        angle: angle,
        child: SizedBox(
          height: kComboRainDropSize,
          width: width,
          child: CustomPaint(painter: ShotGlassPainter()),
        ),
      ),
    );
  }
}
