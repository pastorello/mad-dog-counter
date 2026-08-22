/// Il bicchiere shot di House of Mad Dogs.
///
/// Trascritto path per path da `design/processed/homd_shot_glass.svg`, che è
/// il ridisegno vettoriale del logo ufficiale. Trascritto e non caricato: il
/// disegno sono tre path, e importare un motore SVG per tre path sarebbe una
/// dipendenza in più da mantenere per niente.
///
/// Le coordinate sono quelle del viewBox originale, 400×460, riscalate.
library;

import 'package:flutter/material.dart';

import '../../config.dart';

class HomdMark extends StatelessWidget {
  const HomdMark({super.key, required this.size});

  /// Altezza del marchio. La larghezza segue le proporzioni del viewBox.
  final double size;

  static const Size _viewBox = Size(400, 460);

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
    // i numeri restano identici a quelli dell'SVG, così confrontarli è facile.
    canvas.scale(size.width / 400, size.height / 460);

    final Paint outline = Paint()
      ..color = kPrimaryRed
      ..style = PaintingStyle.stroke
      ..strokeWidth = 34
      ..strokeJoin = StrokeJoin.round;

    // Contorno esterno del bicchiere.
    final Path glass = Path()
      ..moveTo(60, 28)
      ..lineTo(340, 28)
      ..quadraticBezierTo(368, 28, 365, 56)
      ..lineTo(330, 408)
      ..quadraticBezierTo(327, 436, 298, 436)
      ..lineTo(102, 436)
      ..quadraticBezierTo(73, 436, 70, 408)
      ..lineTo(35, 56)
      ..quadraticBezierTo(32, 28, 60, 28)
      ..close();
    canvas.drawPath(glass, outline);

    // Il liquido, pieno.
    final Path liquid = Path()
      ..moveTo(112, 148)
      ..lineTo(288, 148)
      ..quadraticBezierTo(300, 148, 299, 160)
      ..lineTo(281, 348)
      ..quadraticBezierTo(280, 362, 266, 362)
      ..lineTo(134, 362)
      ..quadraticBezierTo(120, 362, 119, 348)
      ..lineTo(101, 160)
      ..quadraticBezierTo(100, 148, 112, 148)
      ..close();
    canvas.drawPath(liquid, Paint()..color = kPrimaryRed);

    // Lo scavo dell'onda in cima al liquido: nell'SVG è dipinto col colore di
    // sfondo, qui uguale. Sopra a un fondo diverso da kBackground si vedrebbe,
    // ma lo splash sta sempre sul fondo dell'app.
    final Path wave = Path()
      ..moveTo(101, 160)
      ..quadraticBezierTo(100, 148, 112, 148)
      ..lineTo(288, 148)
      ..quadraticBezierTo(300, 148, 299, 160)
      ..lineTo(296, 196)
      ..quadraticBezierTo(250, 230, 200, 210)
      ..quadraticBezierTo(150, 190, 104, 214)
      ..close();
    canvas.drawPath(wave, Paint()..color = kBackground);
  }

  @override
  bool shouldRepaint(ShotGlassPainter oldDelegate) => false;
}
