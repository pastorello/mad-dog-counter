/// Lo sfondo stagionale: Halloween e Natale, scelti dal pannello.
///
/// Resa decisa nei mockup (design/mockups/DECISIONS.md → 06): una cornice
/// colorata ai bordi (arancio zucca / verde abete) con un alone verso
/// l'interno, e decorazioni DISCRETE ai 4 angoli — pipistrelli e zucche,
/// oppure palline, pacchi regalo e bastoncini di zucchero più la neve.
/// L'angolo in alto a sinistra è del badge OGGI/RECORD: lì le decorazioni
/// non disegnano ([kSeasonRecordClearZone]).
/// Lo sfondo resta quasi nero: il tablet vive in un pub buio.
///
/// Sta all'indice 0 dello Stack, DIETRO al numerone: è atmosfera, non un
/// evento. `kBackground` non diventa dinamico — questo layer ci si appoggia
/// sopra. Tutto è disegnato (CustomPaint deterministico, un solo ticker
/// lento): niente asset, niente numeri casuali.
library;

import 'dart:math' as math;
import 'dart:ui' show ClipOp;

import 'package:material_ui/material_ui.dart';

import '../../config.dart';
import '../../state/season.dart';

class SeasonalBackground extends StatefulWidget {
  const SeasonalBackground({super.key, required this.season});

  final Season season;

  @override
  State<SeasonalBackground> createState() => _SeasonalBackgroundState();
}

class _SeasonalBackgroundState extends State<SeasonalBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _cycle = AnimationController(
    vsync: this,
    duration: kSeasonCycleDuration,
  );

  @override
  void initState() {
    super.initState();
    if (widget.season != Season.none) _cycle.repeat();
  }

  @override
  void didUpdateWidget(SeasonalBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.season == Season.none) {
      _cycle.stop();
    } else if (!_cycle.isAnimating) {
      _cycle.repeat();
    }
  }

  @override
  void dispose() {
    _cycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.season == Season.none) return const SizedBox.shrink();

    return IgnorePointer(
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: _cycle,
          builder: (BuildContext context, Widget? _) {
            final bool halloween = widget.season == Season.halloween;
            // Sotto la cornice, sopra le decorazioni: due pittori separati,
            // perché solo le decorazioni lasciano libero l'angolo del
            // record ([kSeasonRecordClearZone]).
            return CustomPaint(
              size: Size.infinite,
              painter: _FramePainter(
                halloween ? kSeasonHalloweenFrame : kSeasonChristmasFrame,
              ),
              foregroundPainter: halloween
                  ? _HalloweenPainter(_cycle.value)
                  : _ChristmasPainter(_cycle.value),
            );
          },
        ),
      ),
    );
  }
}

/// Cornice comune: bordo pieno + alone sfumato verso l'interno. Ferma: si
/// ridisegna solo se cambia la stagione, non a ogni giro del ciclo.
class _FramePainter extends CustomPainter {
  const _FramePainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) => _paintFrame(canvas, size, color);

  @override
  bool shouldRepaint(_FramePainter oldDelegate) => oldDelegate.color != color;
}

/// Le decorazioni non entrano mai nell'angolo del record.
void _keepRecordCornerClear(Canvas canvas) =>
    canvas.clipRect(kSeasonRecordClearZone, clipOp: ClipOp.difference);

void _paintFrame(Canvas canvas, Size size, Color color) {
  final Paint border = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = kSeasonFrameWidth
    ..color = color.withValues(alpha: kSeasonFrameAlpha);
  canvas.drawRect(
    Rect.fromLTWH(
      kSeasonFrameWidth / 2,
      kSeasonFrameWidth / 2,
      size.width - kSeasonFrameWidth,
      size.height - kSeasonFrameWidth,
    ),
    border,
  );

  final Paint glow = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = kSeasonFrameGlowWidth
    ..color = color.withValues(alpha: kSeasonFrameGlowAlpha)
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 24);
  final double inset = kSeasonFrameWidth + kSeasonFrameGlowWidth / 2;
  canvas.drawRect(
    Rect.fromLTWH(
      inset,
      inset,
      size.width - inset * 2,
      size.height - inset * 2,
    ),
    glow,
  );
}

const Color _inkDark = Color(0xFF1A1026);

class _HalloweenPainter extends CustomPainter {
  _HalloweenPainter(this.t);

  /// Avanzamento del ciclo lento, 0..1.
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    _keepRecordCornerClear(canvas);

    // I pipistrelli aleggiano appena, su e giù col ciclo.
    final double hover = math.sin(t * 2 * math.pi) * 14;

    canvas.saveLayer(
      Offset.zero & size,
      Paint()
        ..color = const Color(0xFFFFFFFF)
            .withValues(alpha: kSeasonDecorOpacity),
    );

    // I due di sinistra volano sotto l'angolo del record, non sopra.
    _bat(canvas, Offset(200, 160 + hover), 110);
    _bat(canvas, Offset(80, 215 + hover * 0.6), 70);
    _bat(canvas, Offset(size.width - 150, 110 - hover), 90);

    _pumpkin(canvas, Offset(120, size.height - kDutchFlagHeight - 90), 1.0);
    _pumpkin(
      canvas,
      Offset(size.width - 140, size.height - kDutchFlagHeight - 80),
      0.75,
    );

    canvas.restore();
  }

  /// Un pipistrello stilizzato, centrato su [center].
  void _bat(Canvas canvas, Offset center, double width) {
    final double u = width / 100;
    final Path body = Path()
      ..moveTo(center.dx, center.dy - 8 * u)
      ..lineTo(center.dx - 8 * u, center.dy - 16 * u)
      ..lineTo(center.dx - 6 * u, center.dy - 6 * u)
      // ala sinistra
      ..cubicTo(
        center.dx - 20 * u,
        center.dy - 18 * u,
        center.dx - 38 * u,
        center.dy - 16 * u,
        center.dx - 48 * u,
        center.dy - 4 * u,
      )
      ..cubicTo(
        center.dx - 38 * u,
        center.dy - 6 * u,
        center.dx - 30 * u,
        center.dy - 2 * u,
        center.dx - 26 * u,
        center.dy + 6 * u,
      )
      ..cubicTo(
        center.dx - 20 * u,
        center.dy,
        center.dx - 12 * u,
        center.dy,
        center.dx - 8 * u,
        center.dy + 8 * u,
      )
      ..lineTo(center.dx, center.dy)
      // ala destra, specchiata
      ..lineTo(center.dx + 8 * u, center.dy + 8 * u)
      ..cubicTo(
        center.dx + 12 * u,
        center.dy,
        center.dx + 20 * u,
        center.dy,
        center.dx + 26 * u,
        center.dy + 6 * u,
      )
      ..cubicTo(
        center.dx + 30 * u,
        center.dy - 2 * u,
        center.dx + 38 * u,
        center.dy - 6 * u,
        center.dx + 48 * u,
        center.dy - 4 * u,
      )
      ..cubicTo(
        center.dx + 38 * u,
        center.dy - 16 * u,
        center.dx + 20 * u,
        center.dy - 18 * u,
        center.dx + 6 * u,
        center.dy - 6 * u,
      )
      ..lineTo(center.dx + 8 * u, center.dy - 16 * u)
      ..close();

    canvas.drawPath(body, Paint()..color = _inkDark);
    canvas.drawPath(
      body,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = kSeasonHalloweenFrame.withValues(alpha: 0.55),
    );
  }

  /// Una zucca intagliata, col picciolo, centrata su [center].
  void _pumpkin(Canvas canvas, Offset center, double scale) {
    final double w = 100 * scale;
    final double h = 64 * scale;

    // Picciolo.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: center.translate(0, -h / 2 - 8 * scale),
          width: 12 * scale,
          height: 18 * scale,
        ),
        Radius.circular(3 * scale),
      ),
      Paint()..color = const Color(0xFF5A7A2E),
    );

    // Corpo e spicchi.
    final Paint body = Paint()..color = kSeasonHalloweenFrame;
    canvas.drawOval(Rect.fromCenter(center: center, width: w, height: h), body);
    final Paint ridge = Paint()..color = kBackground.withValues(alpha: 0.18);
    canvas.drawOval(
      Rect.fromCenter(center: center, width: w * 0.55, height: h),
      ridge,
    );

    // Occhi e bocca.
    final Paint cut = Paint()..color = _inkDark;
    final double e = 10 * scale;
    for (final double side in <double>[-1, 1]) {
      final Path eye = Path()
        ..moveTo(center.dx + side * 20 * scale, center.dy - 6 * scale)
        ..lineTo(center.dx + side * (20 * scale - e), center.dy + 4 * scale)
        ..lineTo(center.dx + side * (20 * scale + e), center.dy + 4 * scale)
        ..close();
      canvas.drawPath(eye, cut);
    }
    final Path mouth = Path()
      ..moveTo(center.dx - 26 * scale, center.dy + 14 * scale)
      ..lineTo(center.dx - 14 * scale, center.dy + 8 * scale)
      ..lineTo(center.dx - 6 * scale, center.dy + 14 * scale)
      ..lineTo(center.dx + 2 * scale, center.dy + 8 * scale)
      ..lineTo(center.dx + 10 * scale, center.dy + 14 * scale)
      ..lineTo(center.dx + 22 * scale, center.dy + 8 * scale)
      ..lineTo(center.dx + 26 * scale, center.dy + 16 * scale)
      ..lineTo(center.dx, center.dy + 22 * scale)
      ..close();
    canvas.drawPath(mouth, cut);
  }

  @override
  bool shouldRepaint(_HalloweenPainter oldDelegate) => oldDelegate.t != t;
}

class _ChristmasPainter extends CustomPainter {
  _ChristmasPainter(this.t);

  final double t;

  static const double _golden = 0.61803398875;

  @override
  void paint(Canvas canvas, Size size) {
    _keepRecordCornerClear(canvas);

    // La neve: colonne e velocità deterministiche, in loop col ciclo.
    final Paint flake = Paint()
      ..color = kTextColor.withValues(alpha: kSnowOpacity);
    for (int i = 0; i < kSnowflakeCount; i++) {
      final double x = ((i * _golden) % 1.0) * size.width;
      final double speed = 2 + (i % 5);
      final double phase = (i * _golden * 1.37) % 1.0;
      final double y = ((t * speed + phase) % 1.0) * (size.height + 20) - 10;
      canvas.drawCircle(Offset(x, y), kSnowflakeSize / 2, flake);
    }

    canvas.saveLayer(
      Offset.zero & size,
      Paint()
        ..color = const Color(0xFFFFFFFF)
            .withValues(alpha: kSeasonDecorOpacity),
    );

    // Le due palline di sinistra stanno sotto l'angolo del record.
    _bauble(canvas, const Offset(90, 165), 22, kPrimaryRed);
    _bauble(canvas, const Offset(190, 148), 16, kSeasonChristmasFrame);
    _bauble(canvas, Offset(size.width - 110, 72), 20, kPrimaryRed);
    _candyCane(canvas, Offset(size.width - 190, 120), 0.9);

    _gift(
      canvas,
      Offset(110, size.height - kDutchFlagHeight - 70),
      1.0,
      kPrimaryRed,
      kCelebrationGold,
    );
    _gift(
      canvas,
      Offset(230, size.height - kDutchFlagHeight - 58),
      0.7,
      kSeasonChristmasFrame,
      kTextColor,
    );
    _gift(
      canvas,
      Offset(size.width - 150, size.height - kDutchFlagHeight - 66),
      0.9,
      kSeasonChristmasFrame,
      kCelebrationGold,
    );
    _candyCane(
      canvas,
      Offset(size.width - 260, size.height - kDutchFlagHeight - 110),
      0.8,
    );

    canvas.restore();
  }

  /// Una pallina appesa: sfera, gancio dorato, riflesso ad arco.
  void _bauble(Canvas canvas, Offset center, double radius, Color color) {
    canvas.drawRect(
      Rect.fromCenter(
        center: center.translate(0, -radius - 5),
        width: radius * 0.4,
        height: 10,
      ),
      Paint()..color = kCelebrationGold,
    );
    canvas.drawCircle(center, radius, Paint()..color = color);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius * 0.65),
      math.pi * 0.15,
      math.pi * 0.5,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = kCelebrationGold,
    );
  }

  /// Un bastoncino di zucchero: gancio bianco sporco a strisce rosse.
  void _candyCane(Canvas canvas, Offset top, double scale) {
    canvas.save();
    canvas.translate(top.dx, top.dy);
    canvas.rotate(0.25);
    canvas.scale(scale);

    final Paint stick = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round
      ..color = kTextColor;
    final Path cane = Path()
      ..moveTo(0, 90)
      ..lineTo(0, 10)
      ..arcToPoint(const Offset(34, 10), radius: const Radius.circular(17));
    canvas.drawPath(cane, stick);

    // Le strisce: trattini rossi lungo il gambo.
    final Paint stripe = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..color = kPrimaryRed;
    for (double y = 18; y < 90; y += 22) {
      canvas.drawLine(Offset(-7, y), Offset(7, y + 10), stripe);
    }
    canvas.restore();
  }

  /// Un pacco regalo col nastro e il fiocco.
  void _gift(
    Canvas canvas,
    Offset center,
    double scale,
    Color box,
    Color ribbon,
  ) {
    final double w = 90 * scale;
    final double h = 56 * scale;
    final Rect body = Rect.fromCenter(
      center: center.translate(0, 8 * scale),
      width: w,
      height: h,
    );
    canvas.drawRect(body, Paint()..color = box);

    // Coperchio appena più scuro.
    canvas.drawRect(
      Rect.fromCenter(
        center: center.translate(0, -h / 2 + 2 * scale),
        width: w * 1.1,
        height: 14 * scale,
      ),
      Paint()..color = Color.lerp(box, kBackground, 0.25)!,
    );

    // Nastro verticale e fiocco.
    final Paint tie = Paint()..color = ribbon;
    canvas.drawRect(
      Rect.fromCenter(
        center: center.translate(0, 8 * scale),
        width: 12 * scale,
        height: h,
      ),
      tie,
    );
    canvas.drawCircle(
      center.translate(-8 * scale, -h / 2 - 6 * scale),
      7 * scale,
      tie,
    );
    canvas.drawCircle(
      center.translate(8 * scale, -h / 2 - 6 * scale),
      7 * scale,
      tie,
    );
  }

  @override
  bool shouldRepaint(_ChristmasPainter oldDelegate) => oldDelegate.t != t;
}
