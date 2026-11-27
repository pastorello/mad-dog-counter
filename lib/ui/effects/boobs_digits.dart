/// Effetto 6 — otto adiacenti: la coppia di 8 diventa due tette.
///
/// Dalla v3 non è più uno stato persistente a video: la coppia si trasforma
/// col morph, resta un attimo in posa, poi il disegno SI ESPANDE verso il
/// centro dello schermo fino a toccare i bordi e sfuma. A scena finita le
/// cifre sono tornate normali anche se il totale resta sugli 8 adiacenti
/// (es. fermo su 88): niente tette parcheggiate a video. La sequenza la
/// guida `BigNumber`, che possiede i controller.
///
/// Dalla v4 il disegno non vive più dentro il numerone ma nell'[Overlay]
/// dell'app (via [OverlayPortal]): passa davanti a TUTTO — combo, timbri,
/// marchio, scene a tutto schermo — come chiesto dal committente. Al posto
/// della coppia, nel numerone, restano solo le due cifre di ripiego.
///
/// Stile buffo da cartoon, rosa carne su fondo scuro: in rosso di brand la
/// battuta non si leggeva. Resta un pub, non un sito porno.
library;

import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../../config.dart';

// Le proporzioni del disegno, in frazione dell'altezza del suo riquadro.
// Le usano sia il pittore sia [boobsPaintedBounds]: il contorno su cui si
// calcola l'espansione è per costruzione quello che si vede.
const double _radius = 0.26;
const double _centerY = 0.56;
const double _gap = 1.06; // distanza centro-mezzeria, in raggi
const double _squash = 0.92; // schiacciamento verticale delle due forme
const double _stroke = 0.022;

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

/// Il contorno di ciò che il pittore disegna davvero dentro un riquadro
/// [box]: le due forme col loro tratto. Occupa circa metà dell'altezza del
/// riquadro, ed è un po' più in basso del centro — per questo l'espansione
/// non si può calcolare sul riquadro (fino alla v3 le tette si fermavano a
/// metà schermo).
Rect boobsPaintedBounds(Size box) {
  final double r = box.height * _radius;
  final double halfStroke = box.height * _stroke / 2;
  final double reachX = r * _gap + r + halfStroke;
  final double reachY = (r + halfStroke) * _squash;
  final double cy = box.height * _centerY;
  return Rect.fromLTRB(
    box.width / 2 - reachX,
    cy - reachY,
    box.width / 2 + reachX,
    cy + reachY,
  );
}

/// La trasformazione dell'espansione, nelle coordinate dello schermo.
///
/// [rest] è il contorno disegnato a riposo (al posto della coppia), [screen]
/// lo schermo, [progress] l'avanzamento già addolcito (0..1). A 0 è
/// l'identità; a 1 il disegno è centrato nello schermo e alto quanto lui:
/// tocca il bordo alto e quello basso. Comanda sempre l'altezza (chiesta
/// dal committente): in landscape i lati escono dallo schermo, ed è voluto
/// — le tette riempiono il monitor.
Matrix4 boobsBlowUpTransform({
  required Size screen,
  required Rect rest,
  required double progress,
}) {
  if (rest.height <= 0) return Matrix4.identity();
  final double fullScale = screen.height / rest.height;
  final double scale = 1 + (fullScale - 1) * progress;
  final Offset center = Offset.lerp(
    rest.center,
    screen.center(Offset.zero),
    progress,
  )!;
  return Matrix4.identity()
    ..translateByDouble(center.dx, center.dy, 0, 1)
    ..scaleByDouble(scale, scale, 1, 1)
    ..translateByDouble(-rest.center.dx, -rest.center.dy, 0, 1);
}

/// Chiave del disegno, per i test: vive nell'Overlay, non nel numerone.
const Key kBoobsDrawingKey = ValueKey<String>('boobs-drawing');

/// Disegno che sostituisce una coppia di `88`.
///
/// [morph] va da 0 (le due cifre normali) a 1 (disegno pieno); [blowUp] da 0
/// (disegno al suo posto tra le cifre) a 1 (espansione finita e disegno
/// sfumato): le transizioni le guida chi lo usa.
class BoobsDigits extends StatefulWidget {
  const BoobsDigits({
    super.key,
    required this.size,
    required this.morph,
    required this.fallback,
    this.blowUp = 0,
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

  @override
  State<BoobsDigits> createState() => _BoobsDigitsState();
}

class _BoobsDigitsState extends State<BoobsDigits> {
  /// Il disegno è nell'Overlay finché la coppia esiste: lo si mostra subito,
  /// prima che il portale si agganci (show() lo consente), e sparisce da
  /// solo quando `BigNumber` smette di costruire la coppia.
  final OverlayPortalController _portal = OverlayPortalController()..show();

  @override
  Widget build(BuildContext context) {
    final double expand = boobsExpandProgress(widget.blowUp);
    final double eased = Curves.easeInOutCubic.transform(expand);
    final double fade = boobsFadeProgress(expand);

    // Le cifre svaniscono mentre il disegno entra e TORNANO mentre il
    // disegno vola verso i bordi: in nessun momento uno stacco secco.
    final double digitsOpacity = math.max(
      (1 - widget.morph).clamp(0.0, 1.0),
      expand,
    );
    final double drawingOpacity = (widget.morph * (1 - fade)).clamp(0.0, 1.0);
    final Size box = Size(widget.size * kDigitSlotRatio * 2, widget.size);

    return Stack(
      alignment: Alignment.center,
      children: <Widget>[
        Opacity(opacity: digitsOpacity, child: widget.fallback),
        // Nel numerone la coppia occupa solo il suo posto: il disegno lo
        // costruisce il portale nell'Overlay, partendo da dove sta questo
        // riquadro (trasformazioni degli effetti comprese).
        OverlayPortal.overlayChildLayoutBuilder(
          controller: _portal,
          overlayChildBuilder:
              (BuildContext context, OverlayChildLayoutInfo info) {
                // Una copia: la misura del figlio è sua, il layout
                // dell'Overlay non la può adottare così com'è.
                final Size childSize = Size.copy(info.childSize);
                final Rect rest = MatrixUtils.transformRect(
                  info.childPaintTransform,
                  boobsPaintedBounds(childSize),
                );
                final Matrix4 blowUp = boobsBlowUpTransform(
                  screen: info.overlaySize,
                  rest: rest,
                  progress: eased,
                );
                // IgnorePointer: sta sopra a tutto, zone di tap comprese, e
                // non deve rubare un solo tap (regola d'oro 2).
                return IgnorePointer(
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: Opacity(
                      opacity: drawingOpacity,
                      child: Transform(
                        transform: blowUp.multiplied(info.childPaintTransform),
                        child: CustomPaint(
                          key: kBoobsDrawingKey,
                          size: childSize,
                          painter: _BoobsPainter(morph: widget.morph),
                        ),
                      ),
                    ),
                  ),
                );
              },
          child: SizedBox.fromSize(size: box),
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
    final double r = size.height * _radius;
    final double cy = size.height * _centerY;
    final double gap = r * _gap;
    final Offset left = Offset(size.width / 2 - gap, cy);
    final Offset right = Offset(size.width / 2 + gap, cy);

    final Paint fill = Paint()
      ..color = kFleshPink
      ..style = PaintingStyle.fill;
    final Paint stroke = Paint()
      ..color = kTextColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.height * _stroke
      ..strokeCap = StrokeCap.round;

    // Le due forme, appena schiacciate: due cerchi puri sembrerebbero occhi.
    for (final Offset c in <Offset>[left, right]) {
      canvas.save();
      canvas.translate(c.dx, c.dy);
      canvas.scale(1, _squash);
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
