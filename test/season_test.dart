import 'package:flutter_test/flutter_test.dart';
import 'package:mad_dog_counter/state/season.dart';

void main() {
  group('Season', () {
    test('dbValue e fromDbValue sono inversi', () {
      for (final Season season in Season.values) {
        expect(Season.fromDbValue(season.dbValue), season);
      }
    });

    test('un valore sconosciuto o mancante e Nessuna: mai rompersi', () {
      expect(Season.fromDbValue(null), Season.none);
      expect(Season.fromDbValue(''), Season.none);
      expect(Season.fromDbValue('ferragosto'), Season.none);
    });

    test('il default e Nessuna', () {
      expect(Season.fromDbValue(null), Season.none);
    });
  });
}
