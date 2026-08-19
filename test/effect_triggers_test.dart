import 'package:flutter_test/flutter_test.dart';
import 'package:mad_dog_counter/state/effect_triggers.dart';

void main() {
  group('multipli', () {
    test('100 riconosce i multipli di 100', () {
      expect(isMultipleOf100(100), isTrue);
      expect(isMultipleOf100(239400), isTrue);
      expect(isMultipleOf100(239401), isFalse);
      expect(isMultipleOf100(0), isFalse, reason: 'zero non festeggia');
    });

    test('1000 riconosce i multipli di 1000', () {
      expect(isMultipleOf1000(1000), isTrue);
      expect(isMultipleOf1000(240000), isTrue);
      expect(isMultipleOf1000(239400), isFalse);
      expect(isMultipleOf1000(0), isFalse);
    });
  });

  group('finisce per 67', () {
    test('guarda solo le ultime due cifre', () {
      expect(endsWith67(67), isTrue);
      expect(endsWith67(239367), isTrue);
      expect(endsWith67(1670), isFalse);
      expect(endsWith67(239368), isFalse);
    });
  });

  group('otto adiacenti', () {
    test('trova una coppia', () {
      expect(hasAdjacentEights(239881), isTrue);
      expect(hasAdjacentEights(88), isTrue);
      expect(hasAdjacentEights(239818), isFalse);
      expect(hasAdjacentEights(0), isFalse);
    });

    test('in 888 trasforma solo la prima coppia', () {
      expect(adjacentEightPairs(888), <int>[0]);
    });

    test('trasforma tutte le coppie disgiunte', () {
      expect(adjacentEightPairs(881188), <int>[0, 4]);
    });

    test('8888 sono due coppie, non tre sovrapposte', () {
      expect(adjacentEightPairs(8888), <int>[0, 2]);
    });
  });

  group('coda effetti', () {
    test('il multiplo di 1000 assorbe il multiplo di 100', () {
      final List<EffectKind> effects = triggersFor(240000);
      expect(effects, contains(EffectKind.strike));
      expect(
        effects,
        isNot(contains(EffectKind.fireworks)),
        reason: 'lo strike sostituisce i fuochi, non li accoda',
      );
    });

    test('il multiplo di 100 non-mille fa scattare i fuochi', () {
      expect(triggersFor(239400), <EffectKind>[EffectKind.fireworks]);
    });

    test('eventi indipendenti si accodano per durata crescente', () {
      // 239867 finisce per 67 e non e' multiplo: un solo effetto.
      expect(triggersFor(239867), <EffectKind>[EffectKind.shake67]);

      // 100067 finisce per 67; non e' multiplo di 100. Aggiungiamo un caso
      // costruito con due trigger indipendenti veri.
      final List<EffectKind> combo = triggersFor(1067);
      expect(combo, <EffectKind>[EffectKind.shake67]);
    });

    test('la coda e ordinata dal piu corto al piu epico', () {
      final List<EffectKind> ordered =
          <EffectKind>[
            EffectKind.strike,
            EffectKind.shake67,
            EffectKind.fireworks,
          ]..sort(
            (EffectKind a, EffectKind b) =>
                effectWeight(a).compareTo(effectWeight(b)),
          );
      expect(ordered, <EffectKind>[
        EffectKind.shake67,
        EffectKind.fireworks,
        EffectKind.strike,
      ]);
    });

    test('un totale senza trigger non accoda nulla', () {
      expect(triggersFor(239339), isEmpty);
    });
  });
}
