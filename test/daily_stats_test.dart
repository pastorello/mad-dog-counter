import 'package:flutter_test/flutter_test.dart';
import 'package:mad_dog_counter/state/daily_stats.dart';

void main() {
  const DailyStats fresh = DailyStats(windowKey: '20261124');

  group('applyTapDelta', () {
    test('il +1 fa salire il giornaliero', () {
      expect(applyTapDelta(fresh, 1).todayCount, 1);
    });

    test('il -1 scala il conteggio del giorno', () {
      final DailyStats due = applyTapDelta(applyTapDelta(fresh, 1), 1);
      expect(applyTapDelta(due, -1).todayCount, 1);
    });

    test('il record si aggiorna appena superato (ratchet in linea)', () {
      final DailyStats after = applyTapDelta(fresh, 1);
      expect(after.bestCount, 1);
      expect(after.bestDayKey, '20261124');
    });

    test('il record non ridiscende mai', () {
      final DailyStats record = applyTapDelta(fresh, 1); // best 1
      final DailyStats dopo = applyTapDelta(record, -1); // today 0
      expect(dopo.bestCount, 1, reason: 'il -1 corregge oggi, non la storia');
      expect(dopo.todayCount, 0);
    });

    test('sotto il record il best resta quello vecchio', () {
      const DailyStats conStoria = DailyStats(
        windowKey: '20261124',
        bestCount: 10,
        bestDayKey: '20261101',
      );
      final DailyStats after = applyTapDelta(conStoria, 1);
      expect(after.bestCount, 10);
      expect(after.bestDayKey, '20261101');
    });
  });

  group('shouldCelebrateRecord', () {
    test('il primissimo mad dog del primissimo giorno è già un record', () {
      // Decisione del committente (DECISIONS.md → 01): il record parte da 0
      // e si festeggia anche il primo giorno.
      final DailyStats after = applyTapDelta(fresh, 1);
      expect(shouldCelebrateRecord(fresh, after), isTrue);
    });

    test('la celebrazione scatta una volta sola per finestra', () {
      final DailyStats celebrato = applyTapDelta(
        fresh,
        1,
      ).copyWith(celebratedThisWindow: true);
      final DailyStats oltre = applyTapDelta(celebrato, 1);
      expect(shouldCelebrateRecord(celebrato, oltre), isFalse);
    });

    test('sotto il record non si celebra', () {
      const DailyStats conStoria = DailyStats(
        windowKey: '20261124',
        todayCount: 3,
        bestCount: 10,
      );
      final DailyStats after = applyTapDelta(conStoria, 1);
      expect(shouldCelebrateRecord(conStoria, after), isFalse);
    });

    test('al pareggio non si celebra: il record va SUPERATO', () {
      const DailyStats pari = DailyStats(
        windowKey: '20261124',
        todayCount: 9,
        bestCount: 10,
      );
      final DailyStats after = applyTapDelta(pari, 1); // 10 == 10
      expect(shouldCelebrateRecord(pari, after), isFalse);
    });
  });

  group('displayCount', () {
    test('il giornaliero mostrato non scende mai sotto zero', () {
      final DailyStats negativo = applyTapDelta(fresh, -1);
      expect(negativo.todayCount, -1, reason: 'il conteggio vero è netto');
      expect(negativo.displayCount, 0, reason: 'a video c\'è il pavimento');
    });
  });
}
