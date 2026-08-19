/// Effetto 5 — il totale finisce per 67: il numerone trema.
///
/// Shake orizzontale, stile brivido. Tutte le cifre si muovono insieme: è il
/// numero a tremare, non le cifre a sparpagliarsi.
library;

import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'effect_catalog.dart';

/// Quante oscillazioni complete nella durata dell'effetto.
const double _oscillations = 7;

/// Ampiezza massima dello scarto orizzontale, in pixel.
const double _amplitude = 18;

Widget shakeDigit(DigitContext context, Widget digit) {
  // L'ampiezza cala verso la fine: il brivido si spegne invece di troncarsi.
  final double decay = 1 - context.progress;
  final double dx =
      math.sin(context.progress * _oscillations * 2 * math.pi) *
      _amplitude *
      decay;
  return Transform.translate(offset: Offset(dx, 0), child: digit);
}
