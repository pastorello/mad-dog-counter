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

  group('Ciommo', () {
    test('non compare sotto la soglia', () {
      expect(ComboState(kComboCiommoThreshold - 1).showsCiommo, isFalse);
      expect(ComboState(kComboCiommoThreshold - 1).ciommoStamps, 0);
    });

    test('compare alla soglia con un timbro', () {
      final ComboState s = ComboState(kComboCiommoThreshold);
      expect(s.showsCiommo, isTrue);
      expect(s.ciommoStamps, 1);
    });

    test('piu la combo cresce, piu timbri spuntano', () {
      expect(ComboState(kComboCiommoThreshold + 2).ciommoStamps, 3);
    });

    test('i timbri non riempiono lo schermo all infinito', () {
      expect(const ComboState(500).ciommoStamps, kComboCiommoMaxStamps);
    });
  });

  test('il moltiplicatore e il conteggio', () {
    expect(const ComboState(7).multiplier, 7);
  });
}
