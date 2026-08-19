import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mad_dog_counter/config.dart';
import 'package:mad_dog_counter/state/effect_triggers.dart';
import 'package:mad_dog_counter/ui/effects/effect_catalog.dart';
import 'package:mad_dog_counter/ui/effects/shake_effect.dart';
import 'package:mad_dog_counter/ui/effects/strike_effect.dart';

const Widget _digit = Text('8');

DigitContext ctx(double progress, {int index = 0, int count = 6}) =>
    DigitContext(index: index, digitCount: count, progress: progress);

/// Estrae lo spostamento applicato da un Transform.
Offset translationOf(Widget widget) {
  final Transform transform = widget as Transform;
  final v = transform.transform.getTranslation();
  return Offset(v.x, v.y);
}

void main() {
  group('catalogo', () {
    test('ogni effetto ha durata e suono', () {
      for (final EffectKind kind in EffectKind.values) {
        expect(
          effectCatalog[kind],
          isNotNull,
          reason: '$kind non e nel catalogo',
        );
        expect(effectCatalog[kind]!.duration.inMilliseconds, greaterThan(0));
        expect(effectCatalog[kind]!.sound, isNotEmpty);
      }
    });

    test('overlay e trasformazioni si riferiscono a effetti esistenti', () {
      for (final EffectKind kind in effectOverlays.keys) {
        expect(effectCatalog.containsKey(kind), isTrue);
      }
      for (final EffectKind kind in digitTransforms.keys) {
        expect(effectCatalog.containsKey(kind), isTrue);
      }
    });

    test('offsetFromCenter va da -1 a 1', () {
      expect(ctx(0, index: 0, count: 5).offsetFromCenter, -1);
      expect(ctx(0, index: 4, count: 5).offsetFromCenter, 1);
      expect(ctx(0, index: 2, count: 5).offsetFromCenter, 0);
    });

    test('una cifra sola non ha lato', () {
      expect(ctx(0, index: 0, count: 1).offsetFromCenter, 0);
    });
  });

  group('shake del 67', () {
    test('parte e finisce fermo', () {
      expect(translationOf(shakeDigit(ctx(0), _digit)).dx, closeTo(0, 0.001));
      expect(translationOf(shakeDigit(ctx(1), _digit)).dx, closeTo(0, 0.001));
    });

    test('in mezzo il numero si sposta davvero', () {
      double maxDx = 0;
      for (double t = 0; t <= 1; t += 0.01) {
        final double dx = translationOf(shakeDigit(ctx(t), _digit)).dx.abs();
        if (dx > maxDx) maxDx = dx;
      }
      expect(maxDx, greaterThan(5));
    });

    test('trema in orizzontale, non in verticale', () {
      expect(translationOf(shakeDigit(ctx(0.3), _digit)).dy, 0);
    });

    test('tutte le cifre si muovono insieme: e il numero a tremare', () {
      final Offset prima = translationOf(
        shakeDigit(ctx(0.3, index: 0), _digit),
      );
      final Offset ultima = translationOf(
        shakeDigit(ctx(0.3, index: 5), _digit),
      );
      expect(prima.dx, ultima.dx);
    });

    test('l ampiezza cala verso la fine', () {
      double picco(double da, double a) {
        double m = 0;
        for (double t = da; t <= a; t += 0.005) {
          final double dx = translationOf(shakeDigit(ctx(t), _digit)).dx.abs();
          if (dx > m) m = dx;
        }
        return m;
      }

      expect(picco(0.7, 1.0), lessThan(picco(0.0, 0.3)));
    });
  });

  group('strike dei 1000', () {
    test('prima dell impatto il numero sta fermo', () {
      // La palla deve ancora arrivare: la cifra e' restituita intatta.
      expect(scatterDigit(ctx(0.05), _digit), same(_digit));
    });

    test('dopo l impatto le cifre volano', () {
      final Offset volo = translationOf(
        scatterDigit(ctx(0.6, index: 0), _digit),
      );
      expect(volo.dy, lessThan(0), reason: 'verso l alto, come birilli');
      expect(volo.dx.abs(), greaterThan(0));
    });

    test('le cifre schizzano verso il proprio lato', () {
      final Offset sinistra = translationOf(
        scatterDigit(ctx(0.6, index: 0, count: 6), _digit),
      );
      final Offset destra = translationOf(
        scatterDigit(ctx(0.6, index: 5, count: 6), _digit),
      );
      expect(sinistra.dx, lessThan(0));
      expect(destra.dx, greaterThan(0));
    });

    test('alla fine il contatore si ricompone', () {
      final Offset finale = translationOf(
        scatterDigit(ctx(1, index: 0, count: 6), _digit),
      );
      expect(finale.dx, closeTo(0, 0.001));
      expect(finale.dy, closeTo(0, 0.001));
    });

    test('e sincronizzato col suono dell impatto', () {
      // L'impatto visivo cade dove parte bowling_strike.wav: se qualcuno
      // cambia una delle due costanti senza l'altra, palla e botto si
      // scollano.
      final double sonoro =
          kStrikeImpactDelay.inMilliseconds / kStrikeDuration.inMilliseconds;
      // Appena prima: fermo. Appena dopo: in movimento.
      expect(scatterDigit(ctx(sonoro - 0.01), _digit), same(_digit));
      expect(
        translationOf(scatterDigit(ctx(sonoro + 0.05, index: 0), _digit)).dy,
        lessThan(0),
      );
    });
  });

  group('fuochi dei 100', () {
    test('il numero viene tinto, non spostato', () {
      final Widget gilded = digitTransforms[EffectKind.fireworks]!(
        ctx(0.5),
        _digit,
      );
      expect(gilded, isA<ShaderMask>());
    });
  });
}
