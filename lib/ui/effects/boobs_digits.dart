/// Effetto 6 — otto adiacenti: la coppia di 8 diventa due tette.
///
/// È uno stato persistente, non un effetto in coda (ANIMATIONS_SPEC → regola
/// 3): resta finché gli 8 restano adiacenti nel numero. Quando la coppia si
/// rompe le cifre tornano normali, con un morph e non uno stacco secco.
///
/// Stile buffo da cartoon, rosa carne su fondo scuro: in rosso di brand la
/// battuta non si leggeva. Resta un pub, non un sito porno.
library;

import 'package:flutter/material.dart';

import '../../config.dart';

/// Disegno che sostituisce una coppia di `88`.
///
/// [morph] va da 0 (le due cifre normali) a 1 (disegno pieno): la
/// transizione la guida chi lo usa.
class BoobsDigits extends StatelessWidget {
  const BoobsDigits({
    super.key,
    required this.size,
    required this.morph,
    required this.fallback,
  });

  /// Dimensione tipografica delle cifre che sostituisce.
  final double size;

  /// Avanzamento della trasformazione, da 0 a 1.
  final double morph;

  /// Le due cifre `88` normali, mostrate mentre il morph è agli inizi.
  final Widget fallback;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: <Widget>[
        // Le cifre svaniscono mentre il disegno entra: nessuno stacco secco.
        Opacity(opacity: (1 - morph).clamp(0.0, 1.0), child: fallback),
        Opacity(
          opacity: morph.clamp(0.0, 1.0),
          child: CustomPaint(
            size: Size(size * kDigitSlotRatio * 2, size),
            painter: _BoobsPainter(morph: morph),
          ),
        ),
      ],
    );
  }
}

class _BoobsPainter extends CustomPainter {
  const _BoobsPainter({required this.morph});

  final double morph;

  @override
  void paint(Canvas canvas, Size size) {
    final double r = size.height * 0.26;
    final double cy = size.height * 0.56;
    final double gap = r * 1.06;
    final Offset left = Offset(size.width / 2 - gap, cy);
    final Offset right = Offset(size.width / 2 + gap, cy);

    final Paint fill = Paint()
      ..color = kFleshPink
      ..style = PaintingStyle.fill;
    final Paint stroke = Paint()
      ..color = kTextColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.height * 0.022
      ..strokeCap = StrokeCap.round;

    // Le due forme, appena schiacciate: due cerchi puri sembrerebbero occhi.
    for (final Offset c in <Offset>[left, right]) {
      canvas.save();
      canvas.translate(c.dx, c.dy);
      canvas.scale(1, 0.92);
      canvas.drawCircle(Offset.zero, r, fill);
      canvas.drawCircle(Offset.zero, r, stroke);
      canvas.restore();
    }

    // Il capezzolo, un puntino rosa scuro. Piccolo: il registro è da fumetto.
    final Paint dot = Paint()..color = kHeartPink;
    canvas.drawCircle(left, r * 0.17, dot);
    canvas.drawCircle(right, r * 0.17, dot);

    // Lo scollo che unisce le due forme in alto, così si leggono come una
    // cosa sola e non come due palline staccate.
    final Path cleavage = Path()
      ..moveTo(left.dx + r * 0.75, cy - r * 0.62)
      ..quadraticBezierTo(
        size.width / 2,
        cy + r * 0.28,
        right.dx - r * 0.75,
        cy - r * 0.62,
      );
    canvas.drawPath(cleavage, stroke);
  }

  @override
  bool shouldRepaint(_BoobsPainter oldDelegate) => oldDelegate.morph != morph;
}
