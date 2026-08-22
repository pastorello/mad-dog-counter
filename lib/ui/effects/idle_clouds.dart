/// Le nuvole che attraversano lo schermo durante l'idle.
///
/// Puro sfondo dietro alla faccina annoiata: attraversano lo schermo in loop,
/// lente come il suo respiro. Non hanno un trigger proprio — vivono e
/// muoiono con `effects.idleFaceVisible`, esattamente come lei
/// (ANIMATIONS_SPEC → Idle).
library;

import 'package:flutter/material.dart';

import '../../config.dart';

class IdleClouds extends StatefulWidget {
  const IdleClouds({super.key});

  @override
  State<IdleClouds> createState() => _IdleCloudsState();
}

class _IdleCloudsState extends State<IdleClouds>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: kIdleCloudsCrossDuration,
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
                    for (int i = 0; i < kIdleCloudsCount; i++)
                      _Cloud(
                        index: i,
                        progress: _controller.value,
                        areaWidth: constraints.biggest.width,
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

class _Cloud extends StatelessWidget {
  const _Cloud({
    required this.index,
    required this.progress,
    required this.areaWidth,
  });

  final int index;
  final double progress;
  final double areaWidth;

  @override
  Widget build(BuildContext context) {
    // Ogni nuvola parte a un punto diverso dell'attraversamento e ha una sua
    // dimensione fissa: due build dello stesso stato danno lo stesso
    // risultato, come i timbri Ciommo e la pioggia della combo.
    final double phase = index / kIdleCloudsCount;
    final double t = (progress + phase) % 1.0;
    final double width = kIdleCloudsSize * (1 - index * 0.15);
    final double height = width * 0.5;
    final double x = -width + t * (areaWidth + width * 2);
    final double top = kIdleCloudsTop + index * (kIdleCloudsSize * 0.5);

    return Positioned(
      left: x,
      top: top,
      child: Opacity(
        opacity: kIdleCloudsOpacity,
        child: CustomPaint(
          size: Size(width, height),
          painter: const _CloudPainter(),
        ),
      ),
    );
  }
}

/// Tre gobbe sovrapposte: la sagoma classica della nuvola, senza asset.
class _CloudPainter extends CustomPainter {
  const _CloudPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final Paint fill = Paint()..color = kTextColor;
    canvas.drawOval(
      Rect.fromLTWH(
        0,
        size.height * 0.35,
        size.width * 0.62,
        size.height * 0.65,
      ),
      fill,
    );
    canvas.drawOval(
      Rect.fromLTWH(
        size.width * 0.18,
        0,
        size.width * 0.55,
        size.height * 0.85,
      ),
      fill,
    );
    canvas.drawOval(
      Rect.fromLTWH(
        size.width * 0.42,
        size.height * 0.25,
        size.width * 0.58,
        size.height * 0.75,
      ),
      fill,
    );
  }

  @override
  bool shouldRepaint(_CloudPainter oldDelegate) => false;
}
