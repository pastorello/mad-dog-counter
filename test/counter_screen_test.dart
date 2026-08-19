import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mad_dog_counter/audio/sound_manager.dart';
import 'package:mad_dog_counter/config.dart';
import 'package:mad_dog_counter/data/counter_repository.dart';
import 'package:mad_dog_counter/state/counter_provider.dart';
import 'package:mad_dog_counter/ui/counter_screen.dart';
import 'package:mad_dog_counter/data/settings_repository.dart';
import 'package:mad_dog_counter/state/combo_machine.dart';
import 'package:mad_dog_counter/ui/effects/combo_overlay.dart';
import 'package:mad_dog_counter/ui/widgets/panic_button.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<LocalCounterRepository> repoWith(int total) async {
  SharedPreferences.setMockInitialValues(<String, Object>{
    kPrefsCounterTotal: total,
  });
  return LocalCounterRepository.open();
}

/// Orologio pilotato a mano: il debounce dei tap non deve dipendere da quanto
/// e' veloce la macchina che esegue i test.
class FakeClock {
  DateTime _now = DateTime(2026);

  DateTime call() => _now;

  void advance(Duration d) => _now = _now.add(d);
}

Future<FakeClock> pumpScreen(
  WidgetTester tester,
  CounterRepository repo, {
  SoundManager? sounds,
}) async {
  final FakeClock clock = FakeClock();
  final SettingsRepository settings = await SettingsRepository.open();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        counterRepositoryProvider.overrideWithValue(repo),
        settingsRepositoryProvider.overrideWithValue(settings),
        clockProvider.overrideWithValue(clock.call),
        if (sounds != null) soundManagerProvider.overrideWithValue(sounds),
      ],
      child: const MaterialApp(home: CounterScreen()),
    ),
  );
  await tester.pump();
  return clock;
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

  group('overlay della combo', () {
    /// Tap ravvicinati ma oltre il debounce: e' il tapping di una combo.
    Future<void> tapIncrement(
      WidgetTester tester,
      FakeClock clock,
      int times,
    ) async {
      final Size size = tester.view.physicalSize / tester.view.devicePixelRatio;
      for (int i = 0; i < times; i++) {
        await tester.tapAt(Offset(size.width * 0.8, size.height / 2));
        clock.advance(kTapDebounce * 2);
        await tester.pump(const Duration(milliseconds: 16));
      }
    }

    testWidgets('il moltiplicatore compare dal secondo tap', (
      WidgetTester tester,
    ) async {
      final FakeClock clock = await pumpScreen(tester, await repoWith(0));
      expect(find.text('x$kComboMinCount'), findsNothing);

      // Un tap solo non e' ancora una combo.
      await tapIncrement(tester, clock, 1);
      await tester.pump();
      expect(find.text('x1'), findsNothing);

      await tapIncrement(tester, clock, 1);
      await tester.pump();
      expect(find.text('x$kComboMinCount'), findsOneWidget);
    });

    testWidgets('alla soglia compare il testo celebrativo', (
      WidgetTester tester,
    ) async {
      final FakeClock clock = await pumpScreen(tester, await repoWith(0));
      await tapIncrement(tester, clock, kComboThresholds[0]);
      await tester.pump();

      expect(find.text(kComboTexts[0]), findsOneWidget);
    });

    testWidgets('alla soglia di Ciommo compare il timbro', (
      WidgetTester tester,
    ) async {
      final FakeClock clock = await pumpScreen(tester, await repoWith(0));
      expect(find.byType(Image), findsNothing);

      await tapIncrement(tester, clock, kComboCiommoThreshold);
      await tester.pump();

      expect(
        find.byType(Image),
        findsOneWidget,
        reason: 'un timbro alla soglia esatta',
      );
    });

    testWidgets('scaduta la finestra la combo sfuma via', (
      WidgetTester tester,
    ) async {
      final FakeClock clock = await pumpScreen(tester, await repoWith(0));
      await tapIncrement(tester, clock, kComboThresholds[0]);
      await tester.pump();
      expect(find.text(kComboTexts[0]), findsOneWidget);

      await tester.pump(kComboWindow);
      await tester.pumpAndSettle();

      // Il testo esce di scena con la dissolvenza, non di scatto: resta nel
      // tree mentre l'opacita' scende.
      final ComboOverlay overlay = tester.widget<ComboOverlay>(
        find.byType(ComboOverlay),
      );
      expect(overlay.combo, ComboState.idle);
      expect(find.text(kComboTexts[0]), findsOneWidget);

      await tester.pump(kComboFadeDuration);
      final AnimatedOpacity fade = tester.widget<AnimatedOpacity>(
        find.byType(AnimatedOpacity),
      );
      expect(fade.opacity, 0);
    });
  });

  group('numerone', () {
    /// Il totale vero del pub e' a sei cifre: se il numerone non si adatta
    /// alla larghezza, sfora lo schermo proprio sul device di produzione.
    testWidgets('un totale a sei cifre non sfora la larghezza', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1920, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpScreen(tester, await repoWith(239338));
      await tester.pumpAndSettle();

      // Un overflow di RenderFlex verrebbe raccolto come eccezione del test.
      expect(tester.takeException(), isNull);
      expect(find.text('9'), findsOneWidget);
    });

    testWidgets('con poche cifre il numero resta grande', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1920, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpScreen(tester, await repoWith(7));
      await tester.pumpAndSettle();

      final Text digit = tester.widget<Text>(find.text('7'));
      expect(
        digit.style!.fontSize,
        1200 * kBigNumberHeightFraction,
        reason: 'con una cifra sola comanda l altezza, non la larghezza',
      );
    });
  });
}
