/// Effetto 6 — otto adiacenti: la coppia di 8 diventa due tette.
///
/// Dalla v3 non è più uno stato persistente a video: la coppia si trasforma
/// col morph, resta un attimo in posa, poi il disegno SI ESPANDE verso il
/// centro dello schermo fino a toccare i bordi e sfuma. A scena finita le
/// cifre sono tornate normali anche se il totale resta sugli 8 adiacenti
/// (es. fermo su 88): niente tette parcheggiate a video. La sequenza la
/// guida `BigNumber`, che possiede i controller.
///
/// Stile buffo da cartoon, rosa carne su fondo scuro: in rosso di brand la
/// battuta non si leggeva. Resta un pub, non un sito porno.
library;

import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../../config.dart';

/// Avanzamento dell'espansione (0..1) dentro la timeline [blowUp] (0..1):
/// la prima [kBoobsBlowUpHoldFraction] è posa ferma, il resto è la corsa.
double boobsExpandProgress(double blowUp) =>
    ((blowUp - kBoobsBlowUpHoldFraction) / (1 - kBoobsBlowUpHoldFraction))
        .clamp(0.0, 1.0);

/// Avanzamento della dissolvenza finale (0..1) rispetto all'espansione
/// [expand] (0..1): il disegno sfuma da [kBoobsBlowUpFadeStart] in poi.
double boobsFadeProgress(double expand) =>
    ((expand - kBoobsBlowUpFadeStart) / (1 - kBoobsBlowUpFadeStart)).clamp(
      0.0,
      1.0,
    );

/// La scala che porta il disegno a toccare i bordi dello schermo: vince il
/// vincolo più stretto (in landscape di solito l'altezza), così il disegno
/// tocca i bordi senza uscirne.
double boobsBlowUpScale(Size screen, Size drawing) {
  if (drawing.width <= 0 || drawing.height <= 0) return 1;
  return math.min(screen.width / drawing.width, screen.height / drawing.height);
}

/// Disegno che sostituisce una coppia di `88`.
///
/// [morph] va da 0 (le due cifre normali) a 1 (disegno pieno); [blowUp] da 0
/// (disegno al suo posto tra le cifre) a 1 (espansione finita e disegno
/// sfumato): le transizioni le guida chi lo usa.
class BoobsDigits extends StatelessWidget {
  const BoobsDigits({
    super.key,
    required this.size,
    required this.morph,
    required this.fallback,
    this.blowUp = 0,
    this.blowUpScale = 1,
    this.blowUpShift = Offset.zero,
  });

  /// Dimensione tipografica delle cifre che sostituisce.
  final double size;

  /// Avanzamento della trasformazione, da 0 a 1.
  final double morph;

  /// Le due cifre `88` normali, mostrate mentre il morph è agli inizi e di
  /// nuovo mentre il disegno vola via.
  final Widget fallback;

  /// Timeline di posa + espansione, da 0 a 1.
  final double blowUp;

  /// La scala a fine espansione, quella che tocca i bordi dello schermo.
  final double blowUpScale;

  /// Di quanto trasla il disegno a fine espansione: dal posto della coppia
  /// al centro dello schermo, così tocca i bordi su entrambi i lati.
  final Offset blowUpShift;

  @override
  Widget build(BuildContext context) {
    final double expand = boobsExpandProgress(blowUp);
    final double eased = Curves.easeInOutCubic.transform(expand);
    final double fade = boobsFadeProgress(expand);

    // Le cifre svaniscono mentre il disegno entra e TORNANO mentre il
    // disegno vola verso i bordi: in nessun momento uno stacco secco.
    final double digitsOpacity = math.max((1 - morph).clamp(0.0, 1.0), expand);
    final double drawingOpacity = (morph * (1 - fade)).clamp(0.0, 1.0);

    return Stack(
      alignment: Alignment.center,
      // Durante l'espansione il disegno esce dallo slot delle due cifre e
      // attraversa lo schermo: senza questo lo Stack lo taglierebbe.
      clipBehavior: Clip.none,
      children: <Widget>[
        Opacity(opacity: digitsOpacity, child: fallback),
        Opacity(
          opacity: drawingOpacity,
          child: Transform.translate(
            offset: blowUpShift * eased,
            child: Transform.scale(
              scale: 1 + (blowUpScale - 1) * eased,
              child: CustomPaint(
                size: Size(size * kDigitSlotRatio * 2, size),
                painter: _BoobsPainter(morph: morph),
              ),
            ),
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
