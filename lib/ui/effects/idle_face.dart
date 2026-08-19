/// Effetto 7 — la faccina annoiata.
///
/// Compare dopo N minuti senza tap, guarda il contatore e sospira. Muta di
/// proposito: nei momenti calmi non deve disturbare il pub. Al primo tap
/// esplode di gioia e sparisce.
///
/// Ridisegnata a partire da `design/raw/idle_faccina_riferimento.jpg`: tondo
/// ambra col contorno spesso, occhioni enormi coi riflessi, una lacrima e le
/// manine sotto il mento. I vettoriali di brand non arriveranno, quindi è
/// tutto disegnato qui.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../config.dart';

class IdleFace extends StatefulWidget {
  const IdleFace({super.key, this.waking = false});

  /// La faccina sta uscendo di scena esplodendo di gioia.
  final bool waking;

  @override
  State<IdleFace> createState() => _IdleFaceState();
}

class _IdleFaceState extends State<IdleFace> with TickerProviderStateMixin {
  /// Il respiro: un ciclo lento e continuo finché la faccina è in scena.
  late final AnimationController _breath = AnimationController(
    vsync: this,
    duration: kIdleBreathDuration,
  )..repeat();

  /// L'uscita di scena.
  late final AnimationController _wake = AnimationController(
    vsync: this,
    duration: kIdleWakeDuration,
  );

  @override
  void initState() {
    super.initState();
    if (widget.waking) _wake.forward();
  }

  @override
  void didUpdateWidget(IdleFace oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.waking && !oldWidget.waking) _wake.forward(from: 0);
  }

  @override
  void dispose() {
    _breath.dispose();
    _wake.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Align(
        // In cima al centro, nella fascia dei contatori della combo.
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.only(top: kIdleFaceTop),
          child: AnimatedBuilder(
            animation: Listenable.merge(<Listenable>[_breath, _wake]),
            builder: (BuildContext context, Widget? _) {
              final double breath = _breath.value;
              final double wake = _wake.value;

              // Uscita: un guizzo in su, poi si rimpicciolisce svanendo.
              final double wakeScale = widget.waking ? 1 + wake * 0.6 : 1;
              final double wakeOpacity = widget.waking ? 1 - wake : 1;

              // Respiro: sale e scende piano, e si gonfia appena. È il sospiro.
              final double bob = math.sin(breath * 2 * math.pi) * 10;
              final double breathScale =
                  1 + math.sin(breath * 2 * math.pi) * 0.025;

              return Opacity(
                opacity: wakeOpacity.clamp(0.0, 1.0),
                child: Transform.translate(
                  offset: Offset(0, bob),
                  child: Transform.scale(
                    scale: breathScale * wakeScale,
                    child: SizedBox(
                      width: kIdleFaceSize,
                      height: kIdleFaceSize,
                      child: CustomPaint(
                        painter: _FacePainter(
                          // La lacrima gonfia e cade una volta per respiro.
                          tear: breath,
                          joy: widget.waking ? wake : 0,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _FacePainter extends CustomPainter {
  const _FacePainter({required this.tear, required this.joy});

  /// Avanzamento del ciclo di respiro, da 0 a 1. Guida anche la lacrima.
  final double tear;

  /// Avanzamento della gioia finale, da 0 a 1.
  final double joy;

  /// Il contorno spesso e scuro del riferimento. Non nero puro: tinto come
  /// il fondo dell'app.
  static const Color _ink = Color(0xFF14141C);

  @override
  void paint(Canvas canvas, Size size) {
    final Offset centre = Offset(size.width / 2, size.height * 0.42);
    final double r = size.width * 0.36;

    final Paint face = Paint()..color = kIdleFaceColor;
    final Paint ink = Paint()
      ..color = _ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.035
      ..strokeCap = StrokeCap.round;

    _paintHands(canvas, size, centre, r, face, ink);

    canvas.drawCircle(centre, r, face);
    canvas.drawCircle(centre, r, ink);

    // Occhioni enormi, quasi attaccati al centro: è tutto lì lo sguardo.
    final double eyeR = r * 0.42;
    final double eyeDx = r * 0.44;
    final Offset leftEye = Offset(centre.dx - eyeDx, centre.dy + r * 0.06);
    final Offset rightEye = Offset(centre.dx + eyeDx, centre.dy + r * 0.06);

    for (final Offset eye in <Offset>[leftEye, rightEye]) {
      _paintEye(canvas, eye, eyeR, ink, mirrored: eye == rightEye);
    }

    // Nella gioia la lacrima sparisce: non si piange mentre si esulta.
    if (joy < 0.3) _paintTear(canvas, rightEye, eyeR, r);
  }

  void _paintEye(
    Canvas canvas,
    Offset centre,
    double r,
    Paint ink, {
    required bool mirrored,
  }) {
    canvas.drawCircle(centre, r, Paint()..color = _ink);
    canvas.drawCircle(centre, r, ink);

    // Il riflesso pallido in basso verso l'interno, come nel riferimento:
    // è quello che rende l'occhio lucido invece che spento.
    final double side = mirrored ? 1 : -1;
    final Paint sheen = Paint()..color = kIdleEyeSheen;
    canvas.save();
    canvas.translate(centre.dx + side * r * 0.34, centre.dy + r * 0.42);
    canvas.scale(1, 0.62);
    canvas.drawCircle(Offset.zero, r * 0.42, sheen);
    canvas.restore();

    // Il piccolo guizzo di luce, blu di brand invece del ciano
    // del riferimento (UX_UI_SPEC → palette).
    final Paint glint = Paint()
      ..color = kAccentBlue
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.13
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(centre.dx - r * 0.30, centre.dy - r * 0.02),
      Offset(centre.dx + r * 0.02, centre.dy - r * 0.10),
      glint,
    );
  }

  /// Una lacrima che gonfia sotto l'occhio e scivola giù, una per respiro.
  void _paintTear(Canvas canvas, Offset eye, double eyeR, double faceR) {
    // Sta ferma per metà ciclo, poi cade: una goccia continua sarebbe un
    // rubinetto, non un dispiacere.
    if (tear < 0.5) return;
    final double fall = (tear - 0.5) / 0.5;

    final double dy = eyeR * 0.9 + fall * faceR * 1.05;
    final double opacity = fall < 0.75 ? 1 : (1 - fall) / 0.25;
    final Offset drop = Offset(eye.dx + eyeR * 0.30, eye.dy + dy);
    final double r = eyeR * kIdleTearRadiusFactor * (1 - fall * 0.25);
    final double alpha = opacity.clamp(0.0, 1.0);

    final Paint water = Paint()..color = kIdleTearBlue.withValues(alpha: alpha);

    // Goccia vera: punta in alto, pancia tonda in basso. I due fianchi sono
    // cubiche simmetriche che si chiudono sulla punta, non archi accostati:
    // è quello che prima faceva un profilo storto.
    final double tipY = drop.dy - r * 2.2;
    final Path path = Path()
      ..moveTo(drop.dx, tipY)
      ..cubicTo(
        drop.dx + r * 0.32,
        tipY + r * 0.7,
        drop.dx + r * 1.06,
        drop.dy - r * 0.9,
        drop.dx + r,
        drop.dy,
      )
      ..arcToPoint(
        Offset(drop.dx - r, drop.dy),
        radius: Radius.circular(r),
        clockwise: false,
      )
      ..cubicTo(
        drop.dx - r * 1.06,
        drop.dy - r * 0.9,
        drop.dx - r * 0.32,
        tipY + r * 0.7,
        drop.dx,
        tipY,
      )
      ..close();
    canvas.drawPath(path, water);

    // Bordo chiaro e riflesso: sul fondo scuro una goccia piatta sparisce,
    // con un filo di luce sembra acqua.
    canvas.drawPath(
      path,
      Paint()
        ..color = kIdleEyeSheen.withValues(alpha: alpha * 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.12,
    );
    canvas.drawCircle(
      Offset(drop.dx - r * 0.32, drop.dy - r * 0.34),
      r * 0.30,
      Paint()..color = kIdleEyeSheen.withValues(alpha: alpha * 0.95),
    );
  }

  /// Le due manine sotto il mento.
  void _paintHands(
    Canvas canvas,
    Size size,
    Offset centre,
    double r,
    Paint face,
    Paint ink,
  ) {
    // Nella gioia le mani si allargano invece di stare raccolte.
    final double spread = 1 + joy * 0.9;
    final double handR = r * 0.30;
    final double y = centre.dy + r * 0.92;

    for (final double side in <double>[-1, 1]) {
      final Offset c = Offset(centre.dx + side * r * 0.44 * spread, y);
      canvas.save();
      canvas.translate(c.dx, c.dy);
      canvas.rotate(side * (0.35 + joy * 0.5));
      final Rect paw = Rect.fromCenter(
        center: Offset.zero,
        width: handR * 2.2,
        height: handR * 1.5,
      );
      final RRect rounded = RRect.fromRectAndRadius(
        paw,
        Radius.circular(handR),
      );
      canvas.drawRRect(rounded, face);
      canvas.drawRRect(rounded, ink);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_FacePainter oldDelegate) =>
      oldDelegate.tear != tear || oldDelegate.joy != joy;
}
