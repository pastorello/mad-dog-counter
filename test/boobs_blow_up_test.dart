/// La geometria e la timeline dell'espansione delle tette (v3): funzioni
/// pure in `boobs_digits.dart`, senza widget — regola d'oro 3.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:mad_dog_counter/config.dart';
import 'package:mad_dog_counter/ui/effects/boobs_digits.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  group('boobsBlowUpScale (tocca i bordi, mai oltre)', () {
    test('in landscape vince l altezza: tocca sopra e sotto', () {
      // Le misure del tablet di produzione, cifre a ~526.
      const Size screen = Size(1920, 1200);
      final Size drawing = Size(526 * kDigitSlotRatio * 2, 526);

      final double scale = boobsBlowUpScale(screen, drawing);

      expect(scale * drawing.height, closeTo(screen.height, 0.001));
      expect(
        scale * drawing.width,
        lessThanOrEqualTo(screen.width),
        reason: 'tocca i bordi senza uscire dallo schermo',
      );
    });

    test('con un disegno proporzionalmente largo vince la larghezza', () {
      const Size screen = Size(1000, 5000);
      const Size drawing = Size(500, 100);

      final double scale = boobsBlowUpScale(screen, drawing);

      expect(scale * drawing.width, closeTo(screen.width, 0.001));
      expect(scale * drawing.height, lessThanOrEqualTo(screen.height));
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
