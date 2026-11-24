import 'package:flutter_test/flutter_test.dart';
import 'package:mad_dog_counter/state/daily_window.dart';

void main() {
  group('dailyWindowKey', () {
    test('alle 11:59 la finestra è quella aperta ieri', () {
      expect(
        dailyWindowKey(DateTime(2026, 11, 24, 11, 59)),
        '20261123',
        reason: 'prima di mezzogiorno si è ancora nella serata di ieri',
      );
    });

    test('alle 12:00 in punto apre la finestra di oggi', () {
      expect(dailyWindowKey(DateTime(2026, 11, 24, 12)), '20261124');
    });

    test('alle 23:59 la finestra è quella di oggi', () {
      expect(dailyWindowKey(DateTime(2026, 11, 24, 23, 59)), '20261124');
    });

    test('a mezzanotte e un minuto la finestra resta quella di ieri', () {
      expect(dailyWindowKey(DateTime(2026, 11, 25, 0, 1)), '20261124');
    });

    test('il primo del mese prima di mezzogiorno torna al mese scorso', () {
      expect(dailyWindowKey(DateTime(2026, 12, 1, 9)), '20261130');
    });

    test('capodanno prima di mezzogiorno torna all\'anno scorso', () {
      expect(dailyWindowKey(DateTime(2027, 1, 1, 2)), '20261231');
    });
  });

  group('windowStartFor', () {
    test('dopo mezzogiorno parte dal mezzogiorno di oggi', () {
      expect(
        windowStartFor(DateTime(2026, 11, 24, 22, 30)),
        DateTime(2026, 11, 24, 12),
      );
    });

    test('prima di mezzogiorno parte dal mezzogiorno di ieri', () {
      expect(
        windowStartFor(DateTime(2026, 11, 24, 3)),
        DateTime(2026, 11, 23, 12),
      );
    });
  });

  group('nextNoonAfter', () {
    test('di pomeriggio risponde domani a mezzogiorno', () {
      expect(
        nextNoonAfter(DateTime(2026, 11, 24, 15)),
        DateTime(2026, 11, 25, 12),
      );
    });

    test('di mattina risponde oggi a mezzogiorno', () {
      expect(
        nextNoonAfter(DateTime(2026, 11, 24, 8)),
        DateTime(2026, 11, 24, 12),
      );
    });

    test(
      'non restituisce mai un istante passato, nemmeno alle 12 in punto',
      () {
        final DateTime noon = DateTime(2026, 11, 24, 12);
        expect(nextNoonAfter(noon).isAfter(noon), isTrue);
      },
    );
  });

  group('cambio ora legale', () {
    // Le finestre sono in ora locale: due volte l'anno durano 23 o 25 ore.
    // Accettato e documentato: qui si verifica solo che chiave e confini
    // restino coerenti a cavallo del cambio (date italiane 2026: 29 marzo
    // e 25 ottobre).
    test('la finestra resta coerente a cavallo del cambio di marzo', () {
      expect(dailyWindowKey(DateTime(2026, 3, 29, 11)), '20260328');
      expect(dailyWindowKey(DateTime(2026, 3, 29, 13)), '20260329');
      expect(
        windowStartFor(DateTime(2026, 3, 29, 11)),
        DateTime(2026, 3, 28, 12),
      );
    });

    test('la finestra resta coerente a cavallo del cambio di ottobre', () {
      expect(dailyWindowKey(DateTime(2026, 10, 25, 11)), '20261024');
      expect(dailyWindowKey(DateTime(2026, 10, 25, 12)), '20261025');
      expect(
        nextNoonAfter(DateTime(2026, 10, 24, 20)),
        DateTime(2026, 10, 25, 12),
      );
    });
  });
}
