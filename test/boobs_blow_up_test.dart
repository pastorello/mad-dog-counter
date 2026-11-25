/// La geometria e la timeline dell'espansione delle tette (v3): funzioni
/// pure in `boobs_digits.dart`, senza widget — regola d'oro 3.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:mad_dog_counter/config.dart';
import 'package:mad_dog_counter/ui/effects/boobs_digits.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  group('boobsBlowUpScale (100% dell altezza del monitor)', () {
    test('sul tablet landscape tocca sopra e sotto, dentro ai lati', () {
      // Le misure del tablet di produzione, cifre a ~526.
      const Size screen = Size(1920, 1200);
      final Size drawing = Size(526 * kDigitSlotRatio * 2, 526);

      final double scale = boobsBlowUpScale(screen, drawing);

      expect(scale * drawing.height, closeTo(screen.height, 0.001));
      expect(
        scale * drawing.width,
        lessThanOrEqualTo(screen.width),
        reason: 'in landscape i lati restano dentro',
      );
    });

    test('comanda sempre l altezza, anche se i lati sbordano', () {
      // Schermo quasi quadrato (l'anteprima web): l'altezza arriva comunque
      // al 100% e la larghezza può uscire di poco — voluto.
      const Size screen = Size(800, 827);
      final Size drawing = Size(219 * kDigitSlotRatio * 2, 219);

      final double scale = boobsBlowUpScale(screen, drawing);

      expect(scale * drawing.height, closeTo(screen.height, 0.001));
      expect(scale * drawing.width, greaterThan(screen.width));
    });

    test('un disegno degenere non divide per zero', () {
      expect(boobsBlowUpScale(const Size(1920, 1200), Size.zero), 1);
    });
  });

  group('timeline posa + espansione', () {
    test('durante la posa non si muove niente', () {
      expect(boobsExpandProgress(0), 0);
      expect(boobsExpandProgress(kBoobsBlowUpHoldFraction), 0);
    });

    test('poi corre fino in fondo', () {
      final double mid = boobsExpandProgress(
        kBoobsBlowUpHoldFraction + (1 - kBoobsBlowUpHoldFraction) / 2,
      );
      expect(mid, closeTo(0.5, 0.001));
      expect(boobsExpandProgress(1), 1);
    });

    test('la dissolvenza parte solo sul finale', () {
      expect(boobsFadeProgress(0), 0);
      expect(boobsFadeProgress(kBoobsBlowUpFadeStart), 0);
      expect(boobsFadeProgress(kBoobsBlowUpFadeStart + 0.01), greaterThan(0));
      expect(boobsFadeProgress(1), 1, reason: 'a fine corsa non resta nulla');
    });
  });
}
