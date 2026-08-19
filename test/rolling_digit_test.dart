import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mad_dog_counter/ui/widgets/rolling_digit.dart';

Widget glyph(String digit) => Text(digit, textDirection: TextDirection.ltr);

Future<void> pumpRoll(
  WidgetTester tester, {
  required String previous,
  required String current,
  required double progress,
  bool rollingUp = true,
}) {
  return tester.pumpWidget(
    Directionality(
      textDirection: TextDirection.ltr,
      child: Center(
        child: RollingDigit(
          previous: previous,
          current: current,
          progress: progress,
          rollingUp: rollingUp,
          height: 100,
          builder: glyph,
        ),
      ),
    ),
  );
}

/// Lo spostamento verticale applicato al Text con questa cifra.
double dyOf(WidgetTester tester, String digit) {
  final Transform transform = tester.widget<Transform>(
    find.ancestor(of: find.text(digit), matching: find.byType(Transform)).first,
  );
  return transform.transform.getTranslation().y;
}

void main() {
  group('alignDigits', () {
    test('a parita di cifre accoppia posizione per posizione', () {
      expect(alignDigits('1234', '1235'), <({String current, String previous})>[
        (previous: '1', current: '1'),
        (previous: '2', current: '2'),
        (previous: '3', current: '3'),
        (previous: '4', current: '5'),
      ]);
    });

    test('crescendo di una cifra le unita restano unita', () {
      final result = alignDigits('99', '100');
      expect(result, hasLength(3));
      // La cifra nuova non viene da nessuna parte...
      expect(result[0], (previous: '', current: '1'));
      // ...e decine e unita rollano da 9 a 0, non da 9 a 1.
      expect(result[1], (previous: '9', current: '0'));
      expect(result[2], (previous: '9', current: '0'));
    });

    test('calando di una cifra la vecchia sparisce', () {
      final result = alignDigits('100', '99');
      expect(result, hasLength(3));
      expect(result[0], (previous: '1', current: ''));
      expect(result[1], (previous: '0', current: '9'));
      expect(result[2], (previous: '0', current: '9'));
    });
  });

  group('RollingDigit', () {
    testWidgets('una cifra che non cambia non rolla', (
      WidgetTester tester,
    ) async {
      await pumpRoll(tester, previous: '7', current: '7', progress: 0.5);

      expect(find.text('7'), findsOneWidget);
      expect(
        find.byType(ClipRect),
        findsNothing,
        reason: 'senza roll niente taglio, cosi il glow non viene mangiato',
      );
    });

    testWidgets('a roll finito resta solo la cifra nuova', (
      WidgetTester tester,
    ) async {
      await pumpRoll(tester, previous: '4', current: '5', progress: 1);

      expect(find.text('5'), findsOneWidget);
      expect(find.text('4'), findsNothing);
    });

    testWidgets('a meta roll si vedono tutte e due', (
      WidgetTester tester,
    ) async {
      await pumpRoll(tester, previous: '4', current: '5', progress: 0.5);

      expect(find.text('4'), findsOneWidget);
      expect(find.text('5'), findsOneWidget);
      expect(find.byType(ClipRect), findsOneWidget);
    });

    testWidgets('in salita la cifra nuova entra dal basso', (
      WidgetTester tester,
    ) async {
      await pumpRoll(
        tester,
        previous: '4',
        current: '5',
        progress: 0.3,
        rollingUp: true,
      );

      expect(dyOf(tester, '5'), greaterThan(0), reason: 'entra da sotto');
      expect(dyOf(tester, '4'), lessThan(0), reason: 'esce da sopra');
    });

    testWidgets('in discesa il verso si inverte', (WidgetTester tester) async {
      await pumpRoll(
        tester,
        previous: '5',
        current: '4',
        progress: 0.3,
        rollingUp: false,
      );

      expect(dyOf(tester, '4'), lessThan(0), reason: 'entra da sopra');
      expect(dyOf(tester, '5'), greaterThan(0), reason: 'esce da sotto');
    });

    testWidgets('una cifra che prima non c era entra senza uscente', (
      WidgetTester tester,
    ) async {
      await pumpRoll(tester, previous: '', current: '1', progress: 0.4);
      expect(find.text('1'), findsOneWidget);
    });
  });
}
