/// La geometria e la timeline dell'espansione delle tette (v3): funzioni
/// pure in `boobs_digits.dart`, senza widget — regola d'oro 3.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:mad_dog_counter/config.dart';
import 'package:mad_dog_counter/ui/effects/boobs_digits.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  group('boobsPaintedBounds (il contorno che si vede davvero)', () {
    test(
      'sta nel riquadro, centrato in orizzontale, un po sotto il centro',
      () {
        const Size box = Size(526 * kDigitSlotRatio * 2, 526);
        final Rect bounds = boobsPaintedBounds(box);

        expect(bounds.top, greaterThan(0));
        expect(bounds.bottom, lessThan(box.height));
        expect(bounds.center.dx, closeTo(box.width / 2, 0.001));
        expect(
          bounds.center.dy,
          greaterThan(box.height / 2),
          reason: 'le forme stanno sotto la mezzeria del riquadro',
        );
      },
    );

    test('occupa circa meta dell altezza del riquadro', () {
      // Per questo fino alla v3, scalando il RIQUADRO a tutto schermo, le
      // tette si fermavano a meta monitor.
      const Size box = Size(200, 100);
      expect(boobsPaintedBounds(box).height, closeTo(50, 1));
    });
  });

  group('boobsBlowUpTransform (100% dell altezza del monitor)', () {
    // Il tablet di produzione e una coppia a sinistra del centro, cifre a
    // ~526: il contorno a riposo, gia nelle coordinate dello schermo.
    const Size screen = Size(1920, 1200);
    final Rect rest = boobsPaintedBounds(
      const Size(526 * kDigitSlotRatio * 2, 526),
    ).shift(const Offset(400, 337));

    Rect apply(Matrix4 m, Rect r) => MatrixUtils.transformRect(m, r);

    test('a riposo non si muove niente', () {
      final Rect at0 = apply(
        boobsBlowUpTransform(screen: screen, rest: rest, progress: 0),
        rest,
      );
      expect(at0.left, closeTo(rest.left, 0.001));
      expect(at0.top, closeTo(rest.top, 0.001));
      expect(at0.width, closeTo(rest.width, 0.001));
      expect(at0.height, closeTo(rest.height, 0.001));
    });

    test('a fine corsa tocca il bordo alto e quello basso, centrata', () {
      final Rect at1 = apply(
        boobsBlowUpTransform(screen: screen, rest: rest, progress: 1),
        rest,
      );
      expect(at1.top, closeTo(0, 0.001));
      expect(at1.bottom, closeTo(screen.height, 0.001));
      expect(at1.center.dx, closeTo(screen.width / 2, 0.001));
      expect(
        at1.width,
        greaterThan(screen.width),
        reason: 'in landscape comanda l altezza: i lati escono, voluto',
      );
    });

    test('a meta corsa e a meta strada, in mezzo tra le due taglie', () {
      final Rect atHalf = apply(
        boobsBlowUpTransform(screen: screen, rest: rest, progress: 0.5),
        rest,
      );
      expect(atHalf.height, greaterThan(rest.height));
      expect(atHalf.height, lessThan(screen.height));
    });

    test('un contorno degenere non divide per zero', () {
      expect(
        boobsBlowUpTransform(screen: screen, rest: Rect.zero, progress: 1),
        Matrix4.identity(),
      );
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
