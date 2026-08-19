import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mad_dog_counter/config.dart';
import 'package:mad_dog_counter/data/counter_repository.dart';
import 'package:mad_dog_counter/state/counter_provider.dart';
import 'package:mad_dog_counter/ui/counter_screen.dart';
import 'package:mad_dog_counter/ui/widgets/panic_button.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<LocalCounterRepository> repoWith(int total) async {
  SharedPreferences.setMockInitialValues(<String, Object>{
    kPrefsCounterTotal: total,
  });
  return LocalCounterRepository.open();
}

Future<void> pumpScreen(WidgetTester tester, CounterRepository repo) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [counterRepositoryProvider.overrideWithValue(repo)],
      child: const MaterialApp(home: CounterScreen()),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('mostra una cifra per ogni carattere del totale', (
    WidgetTester tester,
  ) async {
    await pumpScreen(tester, await repoWith(1234));
    for (final String digit in <String>['1', '2', '3', '4']) {
      expect(find.text(digit), findsOneWidget);
    }
  });

  testWidgets('un tap nella zona destra incrementa', (
    WidgetTester tester,
  ) async {
    final LocalCounterRepository repo = await repoWith(10);
    await pumpScreen(tester, repo);

    final Size size = tester.view.physicalSize / tester.view.devicePixelRatio;
    await tester.tapAt(Offset(size.width * 0.8, size.height / 2));
    await tester.pumpAndSettle();

    expect(repo.total, 11);
  });

  testWidgets('un tap nella zona sinistra decrementa', (
    WidgetTester tester,
  ) async {
    final LocalCounterRepository repo = await repoWith(10);
    await pumpScreen(tester, repo);

    final Size size = tester.view.physicalSize / tester.view.devicePixelRatio;
    await tester.tapAt(Offset(size.width * 0.1, size.height / 2));
    await tester.pumpAndSettle();

    expect(repo.total, 9);
  });

  testWidgets('a zero il tap di decremento non porta sotto zero', (
    WidgetTester tester,
  ) async {
    final LocalCounterRepository repo = await repoWith(0);
    await pumpScreen(tester, repo);

    final Size size = tester.view.physicalSize / tester.view.devicePixelRatio;
    await tester.tapAt(Offset(size.width * 0.1, size.height / 2));
    await tester.pumpAndSettle();

    expect(repo.total, 0);
    expect(find.text('0'), findsOneWidget);
  });

  group('pulsante panico', () {
    testWidgets('il suo tap NON conta come incremento', (
      WidgetTester tester,
    ) async {
      final LocalCounterRepository repo = await repoWith(10);
      await pumpScreen(tester, repo);

      await tester.tap(find.byType(PanicButton));
      await tester.pump();

      expect(
        repo.total,
        10,
        reason: 'il kill switch tocca solo gli effetti, mai il contatore',
      );
    });

    testWidgets('mostra l esplosione a tutto schermo', (
      WidgetTester tester,
    ) async {
      await pumpScreen(tester, await repoWith(10));
      expect(find.byType(PanicBlast), findsNothing);

      await tester.tap(find.byType(PanicButton));
      await tester.pump();

      expect(find.byType(PanicBlast), findsOneWidget);

      // L'esplosione si esaurisce da sola e lascia la schermata pulita.
      await tester.pump(kPanicBlastDuration);
      await tester.pumpAndSettle();
      expect(find.byType(PanicBlast), findsNothing);
      expect(find.text('1'), findsOneWidget);
      expect(find.text('0'), findsOneWidget);
    });

    testWidgets('sta sopra la zona +1: un tap sull angolo non incrementa', (
      WidgetTester tester,
    ) async {
      final LocalCounterRepository repo = await repoWith(10);
      await pumpScreen(tester, repo);

      // Tocco proprio nell'angolo alto destro, dove finisce la zona +1.
      final Size size = tester.view.physicalSize / tester.view.devicePixelRatio;
      await tester.tapAt(Offset(size.width - 20, 20));
      await tester.pump();

      expect(repo.total, 10);
    });
  });
}
