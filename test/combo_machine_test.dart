import 'package:flutter_test/flutter_test.dart';
import 'package:mad_dog_counter/config.dart';
import 'package:mad_dog_counter/state/combo_machine.dart';

void main() {
  group('attivazione', () {
    test('un tap solo non e ancora una combo', () {
      expect(const ComboState(1).isActive, isFalse);
    });

    test('da kComboMinCount in su la combo e visibile', () {
      expect(const ComboState(kComboMinCount).isActive, isTrue);
      expect(ComboState.idle.isActive, isFalse);
    });

    test('next() avanza di uno', () {
      expect(ComboState.idle.next().next(), const ComboState(2));
    });
  });

  group('livelli e testi celebrativi', () {
    test('sotto la prima soglia non c e testo', () {
      expect(const ComboState(2).level, 0);
      expect(const ComboState(2).text, isNull);
    });

    test('ogni soglia superata alza il livello', () {
      expect(ComboState(kComboThresholds[0]).level, 1);
      expect(ComboState(kComboThresholds[1]).level, 2);
      expect(ComboState(kComboThresholds.last).level, kComboThresholds.length);
    });

    test('il testo segue il livello', () {
      expect(ComboState(kComboThresholds[0]).text, kComboTexts[0]);
      expect(ComboState(kComboThresholds.last).text, kComboTexts.last);
    });

    test('oltre l ultima soglia il testo resta l ultimo, non sfora', () {
      final ComboState oltre = ComboState(kComboThresholds.last + 50);
      expect(oltre.level, kComboThresholds.length);
      expect(oltre.text, kComboTexts.last);
    });

    test('c e un testo per ogni soglia', () {
      expect(
        kComboTexts.length,
        kComboThresholds.length,
        reason: 'se i baristi aggiungono una soglia serve anche il testo',
      );
    });

    test('crossedThreshold scatta solo sul tap che supera la soglia', () {
      final int soglia = kComboThresholds[0];
      final ComboState prima = ComboState(soglia - 1);
      expect(crossedThreshold(prima, prima.next()), isTrue);
      final ComboState dopo = ComboState(soglia);
      expect(crossedThreshold(dopo, dopo.next()), isFalse);
    });
  });

  group('pitch dei pop', () {
    test('il primo tap suona a velocita normale', () {
      expect(const ComboState(1).pitch, 1.0);
    });

    test('sale a ogni tap', () {
      expect(const ComboState(3).pitch, greaterThan(const ComboState(2).pitch));
    });

    test('non supera mai il tetto', () {
      expect(const ComboState(1000).pitch, kComboPitchMax);
    });
  });

  group('Ciommo (timbro gigante a ogni multiplo)', () {
    test('niente timbro sotto il primo multiplo', () {
      for (int count = 0; count < kCiommoIntervalDefault; count++) {
        expect(isCiommoMultiple(count, kCiommoIntervalDefault), isFalse);
      }
    });

    test('piomba a ogni multiplo esatto', () {
      expect(
        isCiommoMultiple(kCiommoIntervalDefault, kCiommoIntervalDefault),
        isTrue,
      );
      expect(
        isCiommoMultiple(kCiommoIntervalDefault * 2, kCiommoIntervalDefault),
        isTrue,
      );
      expect(
        isCiommoMultiple(kCiommoIntervalDefault * 3, kCiommoIntervalDefault),
        isTrue,
      );
    });

    test('tra un multiplo e l altro resta giu', () {
      expect(
        isCiommoMultiple(kCiommoIntervalDefault + 1, kCiommoIntervalDefault),
        isFalse,
      );
      expect(
        isCiommoMultiple(
          kCiommoIntervalDefault * 2 - 1,
          kCiommoIntervalDefault,
        ),
        isFalse,
      );
    });

    test('l intervallo e un parametro, non una costante', () {
      expect(isCiommoMultiple(3, 3), isTrue);
      expect(isCiommoMultiple(6, 3), isTrue);
      expect(isCiommoMultiple(5, 3), isFalse);
      expect(isCiommoMultiple(2, 2), isTrue);
    });

    test('un intervallo assurdo non divide per zero', () {
      expect(isCiommoMultiple(10, 0), isFalse);
    });
  });

  test('il moltiplicatore e il conteggio', () {
    expect(const ComboState(7).multiplier, 7);
  });
}
