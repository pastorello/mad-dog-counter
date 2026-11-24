import 'package:flutter_test/flutter_test.dart';
import 'package:mad_dog_counter/state/sliding_window.dart';

void main() {
  final DateTime base = DateTime(2026, 11, 24, 21);
  const Duration dueOre = Duration(hours: 2);

  group('SlidingWindowCounter', () {
    test('conta solo gli eventi dentro la finestra', () {
      final SlidingWindowCounter w = SlidingWindowCounter(dueOre);
      w.add(base);
      w.add(base.add(const Duration(minutes: 30)));
      w.add(base.add(const Duration(minutes: 90)));

      expect(w.countAt(base.add(const Duration(minutes: 90))), 3);
      // A +149' il primo (vecchio 2h29') è fuori; il secondo (2h esatte fra
      // un minuto) è ancora dentro.
      expect(w.countAt(base.add(const Duration(minutes: 149))), 2);
      // Molto dopo, sono fuori tutti.
      expect(w.countAt(base.add(const Duration(hours: 5))), 0);
    });

    test('l\'evento esattamente al bordo della finestra è fuori', () {
      final SlidingWindowCounter w = SlidingWindowCounter(dueOre);
      w.add(base);
      // L'ordine conta: countAt pota, quindi prima il controllo "dentro".
      expect(w.countAt(base.add(dueOre - const Duration(seconds: 1))), 1);
      expect(w.countAt(base.add(dueOre)), 0);
    });

    test('il seed dal log entra nel conteggio', () {
      final SlidingWindowCounter w = SlidingWindowCounter(dueOre);
      w.seed(<DateTime>[
        base.subtract(const Duration(minutes: 40)),
        base.subtract(const Duration(minutes: 20)),
      ]);
      w.add(base);
      expect(w.countAt(base), 3);
    });

    test('dopo clear si riparte da zero', () {
      final SlidingWindowCounter w = SlidingWindowCounter(dueOre);
      w.add(base);
      w.add(base.add(const Duration(minutes: 1)));
      w.clear();
      expect(w.countAt(base.add(const Duration(minutes: 2))), 0);
    });
  });
}
