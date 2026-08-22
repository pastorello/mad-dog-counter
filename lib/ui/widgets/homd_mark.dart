/// Il bicchiere shot di House of Mad Dogs.
///
/// Trascritto punto per punto dal vettoriale ufficiale del committente
/// (`Sottobicchiere HoMD 93x93.pdf`, consegnato il 2026-08-22), non dal
/// vecchio `design/processed/homd_shot_glass.svg`: quello era
/// un'approssimazione, questo è il logo vero. Trascritto e non caricato: il
/// disegno sono due path, e importare un motore SVG per due path sarebbe una
/// dipendenza in più da mantenere per niente.
///
/// Le coordinate sono quelle del bounding box originale del bicchiere nel
/// PDF (118,94×126,15 pt), riscalate. Il contorno e il liquido sono ciascuno
/// un path composto da due sottopercorsi (bordo esterno + bordo interno)
/// riempiti con la regola non-zero, esattamente come nel file sorgente:
/// è quello che disegna il "vuoto" del bicchiere e la cornice sopra al
/// liquido senza bisogno di uno stroke o di un ritaglio col colore di
/// sfondo.
library;

import 'package:flutter/material.dart';

import '../../config.dart';

class HomdMark extends StatelessWidget {
  const HomdMark({super.key, required this.size});

  /// Altezza del marchio. La larghezza segue le proporzioni del viewBox.
  final double size;

  static const Size _viewBox = Size(118.94, 126.15);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size * _viewBox.width / _viewBox.height,
      height: size,
      child: CustomPaint(painter: ShotGlassPainter()),
    );
  }
}

/// Pubblico perché lo riusa anche la pioggia di bicchierini della combo
/// (`combo_rain.dart`): stesso disegno, niente da ridisegnare due volte.
class ShotGlassPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Tutto il disegno è nelle coordinate del viewBox: si scala una volta e
    // i numeri restano identici a quelli del PDF sorgente, così confrontarli
    // è facile.
    canvas.scale(size.width / 118.94, size.height / 126.15);

    final Paint fill = Paint()..color = kPrimaryRed;
    canvas.drawPath(_glass, fill);
    canvas.drawPath(_liquid, fill);
  }

  @override
  bool shouldRepaint(ShotGlassPainter oldDelegate) => false;

  /// Il contorno del bicchiere: bordo esterno (sottopercorso 1) e bordo
  /// interno (sottopercorso 2, avvolgimento opposto) che insieme, con la
  /// regola non-zero, disegnano l'anello — il bicchiere "vuoto" senza
  /// stroke.
  static final Path _glass = Path()
    ..moveTo(8.63, 8.5)
    ..cubicTo(8.69, 9.15, 8.72, 9.55, 8.77, 9.96)
    ..cubicTo(9.28, 13.95, 9.8, 17.97, 10.28, 21.97)
    ..cubicTo(11.06, 28.33, 11.82, 34.7, 12.6, 41.07)
    ..cubicTo(13.44, 48.06, 14.3, 55.05, 15.14, 62.06)
    ..cubicTo(15.89, 68.38, 16.65, 74.72, 17.4, 81.03)
    ..cubicTo(18.19, 87.48, 18.94, 93.96, 19.73, 100.41)
    ..cubicTo(20.32, 105.34, 20.94, 110.28, 21.59, 115.22)
    ..cubicTo(21.83, 116.97, 22.94, 117.92, 24.69, 117.95)
    ..cubicTo(26.04, 117.97, 27.39, 117.92, 28.74, 117.89)
    ..cubicTo(50.19, 117.86, 71.64, 117.81, 93.07, 117.78)
    ..cubicTo(96.2, 117.78, 97.17, 116.79, 97.49, 113.65)
    ..cubicTo(98.09, 108.04, 98.76, 102.43, 99.44, 96.82)
    ..cubicTo(100.38, 88.88, 101.35, 80.95, 102.32, 73.02)
    ..cubicTo(103.02, 67.35, 103.73, 61.71, 104.4, 56.05)
    ..cubicTo(105.07, 50.38, 105.72, 44.71, 106.37, 39.07)
    ..cubicTo(106.94, 34.22, 107.56, 29.36, 108.12, 24.5)
    ..cubicTo(108.77, 19.16, 109.42, 13.82, 110.07, 8.47)
    ..cubicTo(76.31, 8.5, 42.55, 8.5, 8.63, 8.5)
    ..close()
    ..moveTo(59.5, 0.0)
    ..lineTo(111.71, 0.0)
    ..cubicTo(116.03, 0.0, 118.94, 3.51, 118.4, 7.77)
    ..cubicTo(117.57, 14.46, 116.84, 21.15, 116.03, 27.82)
    ..cubicTo(115.38, 33.3, 114.71, 38.78, 114.03, 44.25)
    ..cubicTo(113.33, 50.0, 112.68, 55.75, 111.98, 61.49)
    ..cubicTo(111.23, 67.81, 110.42, 74.15, 109.66, 80.46)
    ..cubicTo(108.99, 86.0, 108.34, 91.53, 107.66, 97.03)
    ..cubicTo(106.99, 102.73, 106.32, 108.45, 105.64, 114.14)
    ..cubicTo(105.48, 115.52, 105.34, 116.92, 105.05, 118.27)
    ..cubicTo(104.05, 122.64, 100.11, 125.93, 95.66, 125.93)
    ..cubicTo(71.72, 126.04, 47.82, 126.12, 23.88, 126.15)
    ..cubicTo(17.76, 126.15, 13.92, 122.02, 13.28, 115.38)
    ..cubicTo(12.65, 109.04, 11.79, 102.73, 11.04, 96.41)
    ..cubicTo(10.28, 90.04, 9.5, 83.68, 8.72, 77.31)
    ..cubicTo(7.93, 70.89, 7.15, 64.49, 6.37, 58.07)
    ..cubicTo(5.61, 51.73, 4.88, 45.41, 4.13, 39.07)
    ..cubicTo(3.37, 32.7, 2.59, 26.34, 1.83, 19.94)
    ..cubicTo(1.32, 15.71, 0.78, 11.47, 0.38, 7.23)
    ..cubicTo(0.0, 3.32, 3.0, 0.27, 7.15, 0.24)
    ..cubicTo(16.41, 0.19, 25.69, 0.19, 34.94, 0.16)
    ..lineTo(59.5, 0.16)
    ..lineTo(59.5, 0.0)
    ..close();

  /// Il liquido: cornice vuota (sottopercorso 1, si ferma alla linea
  /// dell'onda) e sagoma piena fino al fondo (sottopercorso 2). Insieme
  /// danno la cornice sopra e il liquido pieno sotto, con la superficie
  /// mossa in mezzo — nessun ritaglio col colore di sfondo, quindi il
  /// disegno resta corretto sopra qualunque sfondo.
  static final Path _liquid = Path()
    ..moveTo(94.36, 39.26)
    ..lineTo(24.28, 39.26)
    ..cubicTo(24.34, 39.88, 24.37, 40.42, 24.45, 40.93)
    ..cubicTo(25.12, 45.95, 25.8, 50.97, 26.5, 55.99)
    ..cubicTo(27.25, 61.36, 27.98, 66.73, 28.82, 72.1)
    ..cubicTo(28.9, 72.67, 29.39, 73.32, 29.87, 73.61)
    ..cubicTo(35.81, 77.23, 42.26, 77.79, 48.98, 76.74)
    ..cubicTo(53.94, 75.96, 58.34, 73.72, 62.55, 71.13)
    ..cubicTo(70.54, 66.19, 79.22, 64.22, 88.53, 65.0)
    ..cubicTo(89.32, 65.06, 90.1, 65.17, 90.96, 65.25)
    ..cubicTo(92.07, 56.56, 93.2, 48.0, 94.36, 39.26)
    ..close()
    ..moveTo(59.39, 33.14)
    ..lineTo(97.01, 33.14)
    ..cubicTo(100.03, 33.14, 101.03, 34.19, 100.68, 37.16)
    ..cubicTo(99.65, 45.31, 98.57, 53.43, 97.54, 61.58)
    ..cubicTo(96.76, 67.62, 96.06, 73.69, 95.28, 79.74)
    ..cubicTo(94.9, 82.71, 94.6, 85.73, 93.96, 88.64)
    ..cubicTo(92.42, 95.5, 86.38, 100.35, 79.41, 100.38)
    ..cubicTo(66.03, 100.46, 52.62, 100.46, 39.24, 100.43)
    ..cubicTo(32.06, 100.41, 25.64, 94.63, 24.69, 87.51)
    ..cubicTo(23.1, 75.74, 21.48, 63.95, 19.89, 52.19)
    ..cubicTo(19.21, 47.25, 18.57, 42.31, 18.0, 37.37)
    ..cubicTo(17.89, 36.43, 17.94, 35.38, 18.32, 34.51)
    ..cubicTo(18.86, 33.24, 20.13, 33.08, 21.43, 33.08)
    ..lineTo(44.23, 33.08)
    ..lineTo(59.47, 33.08)
    ..cubicTo(59.39, 33.11, 59.39, 33.14, 59.39, 33.14)
    ..close();
}
