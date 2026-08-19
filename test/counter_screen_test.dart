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
import 'package:confetti/confetti.dart';
import 'package:mad_dog_counter/ui/effects/boobs_digits.dart';
import 'package:mad_dog_counter/ui/effects/combo_overlay.dart';
import 'package:mad_dog_counter/ui/effects/idle_face.dart';
import 'package:mad_dog_counter/ui/widgets/panic_button.dart';
import 'package:mad_dog_counter/ui/widgets/homd_mark.dart';
import 'package:mad_dog_counter/ui/widgets/rolling_digit.dart';
import 'package:mad_dog_counter/ui/widgets/splash_overlay.dart';
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
    expect(
      find.text('0'),
      findsNWidgets(kCounterDigits),
      reason: 'a zero il tabellone mostra 000000',
    );
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
      expect(find.text('0'), findsNWidgets(kCounterDigits - 1));
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

    /// Il bagliore è dello schermo, non della sola area sotto il numerone:
    /// anche la fascia sinistra del -1 si deve scaldare.
    testWidgets('il bagliore copre tutto, zona -1 compresa', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1920, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final FakeClock clock = await pumpScreen(tester, await repoWith(0));
      await tapIncrement(tester, clock, kComboMinCount);
      await tester.pump();

      expect(
        tester.getRect(find.byKey(kComboGlowKey)),
        const Rect.fromLTWH(0, 0, 1920, 1200),
      );
    });

    /// I timbri escono ai due lati del marchio HoMD: sono grossi, e se
    /// nascessero al centro se lo mangerebbero.
    testWidgets('i timbri lasciano libero il marchio al centro', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1920, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final FakeClock clock = await pumpScreen(tester, await repoWith(0));
      // Fuori lo splash: finche' e' a video i marchi a schermo sono due.
      await tester.pump(kSplashHold);
      await tester.pumpAndSettle();

      await tapIncrement(tester, clock, kComboCiommoThreshold + 1);
      await tester.pump(kComboStampDuration);

      final Rect marchio = tester.getRect(find.byType(HomdMark));
      expect(find.byType(Image), findsNWidgets(2));
      for (int i = 0; i < 2; i++) {
        final Rect timbro = tester.getRect(find.byType(Image).at(i));
        expect(
          timbro.left >= marchio.right || timbro.right <= marchio.left,
          isTrue,
          reason: 'il timbro sta tutto da un lato del marchio',
        );
      }
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

    /// Con gli zeri davanti gli slot sono sempre sei, quindi il numerone non
    /// cambia piu' dimensione da un totale all'altro: e' un tabellone fisso.
    testWidgets('la dimensione non dipende dal totale', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1920, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpScreen(tester, await repoWith(7));
      await tester.pumpAndSettle();
      expect(
        find.text('0'),
        findsNWidgets(kCounterDigits - 1),
        reason: 'il 7 arriva imbottito di zeri',
      );
      final double conUnaCifra = tester
          .widget<Text>(find.text('7'))
          .style!
          .fontSize!;

      await pumpScreen(tester, await repoWith(239338));
      await tester.pumpAndSettle();
      final double conSeiCifre = tester
          .widget<Text>(find.text('2'))
          .style!
          .fontSize!;

      expect(conUnaCifra, conSeiCifre);
      expect(
        conUnaCifra,
        1920 * kBigNumberWidthFraction / kCounterDigits / kDigitSlotRatio,
        reason: 'con sei slot comanda sempre la larghezza',
      );
    });
  });

  group('easter egg a schermo', () {
    Future<void> tapOnce(WidgetTester tester) async {
      final Size size = tester.view.physicalSize / tester.view.devicePixelRatio;
      await tester.tapAt(Offset(size.width * 0.8, size.height / 2));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));
    }

    testWidgets('arrivare a 100 accende i fuochi', (WidgetTester tester) async {
      await pumpScreen(tester, await repoWith(99));
      expect(find.byType(ConfettiWidget), findsNothing);

      await tapOnce(tester);

      expect(find.byType(ConfettiWidget), findsWidgets);
      await tester.pump(kFireworksDuration);
      await tester.pumpAndSettle();
    });

    testWidgets('arrivare a 1000 fa lo strike, non i fuochi', (
      WidgetTester tester,
    ) async {
      await pumpScreen(tester, await repoWith(999));
      await tapOnce(tester);

      expect(
        find.byType(ConfettiWidget),
        findsNothing,
        reason: 'lo strike assorbe i fuochi',
      );
      // La palla e' l'unico CustomPaint dell'overlay dello strike.
      expect(find.byType(CustomPaint), findsWidgets);

      await tester.pump(kStrikeDuration);
      await tester.pumpAndSettle();
    });

    testWidgets('scendere a 100 non accende niente', (
      WidgetTester tester,
    ) async {
      await pumpScreen(tester, await repoWith(101));

      final Size size = tester.view.physicalSize / tester.view.devicePixelRatio;
      await tester.tapAt(Offset(size.width * 0.1, size.height / 2));
      await tester.pump();

      expect(find.byType(ConfettiWidget), findsNothing);
    });

    testWidgets('salire su una coppia di 8 trasforma le cifre', (
      WidgetTester tester,
    ) async {
      await pumpScreen(tester, await repoWith(87));
      expect(find.byType(BoobsDigits), findsNothing);

      await tapOnce(tester); // 88
      await tester.pump(kBoobsMorphDuration);

      expect(find.byType(BoobsDigits), findsOneWidget);
    });

    testWidgets('quando la coppia si rompe le cifre tornano normali', (
      WidgetTester tester,
    ) async {
      final LocalCounterRepository repo = await repoWith(87);
      final FakeClock clock = await pumpScreen(tester, repo);

      await tapOnce(tester); // 88
      await tester.pump(kBoobsMorphDuration);
      expect(find.byType(BoobsDigits), findsOneWidget);

      clock.advance(kTapDebounce * 2);
      await tapOnce(tester); // 89: la coppia sparisce
      await tester.pump(kBoobsMorphDuration);
      await tester.pumpAndSettle();

      expect(find.byType(BoobsDigits), findsNothing);
      expect(repo.total, 89);
    });

    testWidgets('in 888 si trasforma una coppia sola', (
      WidgetTester tester,
    ) async {
      await pumpScreen(tester, await repoWith(887));
      await tapOnce(tester); // 888
      await tester.pump(kBoobsMorphDuration);

      expect(find.byType(BoobsDigits), findsOneWidget);
      expect(
        find.text('8'),
        findsWidgets,
        reason: 'il terzo 8 resta una cifra',
      );
    });
  });

  group('faccina annoiata', () {
    // La faccina respira in loop, quindi pumpAndSettle non tornerebbe mai:
    // qui si avanza sempre a colpi di pump espliciti.
    testWidgets('compare dopo i minuti di inattivita', (
      WidgetTester tester,
    ) async {
      await pumpScreen(tester, await repoWith(42));
      expect(find.byType(IdleFace), findsNothing);

      await tester.pump(const Duration(minutes: kIdleMinutesDefault));
      await tester.pump();

      expect(find.byType(IdleFace), findsOneWidget);
    });

    testWidgets('un tap la sveglia e la manda via', (
      WidgetTester tester,
    ) async {
      final LocalCounterRepository repo = await repoWith(42);
      await pumpScreen(tester, repo);
      await tester.pump(const Duration(minutes: kIdleMinutesDefault));
      await tester.pump();
      expect(find.byType(IdleFace), findsOneWidget);

      final Size size = tester.view.physicalSize / tester.view.devicePixelRatio;
      await tester.tapAt(Offset(size.width * 0.8, size.height / 2));
      await tester.pump();

      // Durante il risveglio e' ancora in scena: sta esplodendo di gioia.
      expect(find.byType(IdleFace), findsOneWidget);
      expect(tester.widget<IdleFace>(find.byType(IdleFace)).waking, isTrue);

      await tester.pump(kIdleWakeDuration);
      await tester.pump();

      expect(find.byType(IdleFace), findsNothing);
      expect(repo.total, 43, reason: 'il tap che sveglia conta comunque');
    });

    testWidgets('non compare finche si continua a contare', (
      WidgetTester tester,
    ) async {
      final FakeClock clock = await pumpScreen(tester, await repoWith(0));
      final Size size = tester.view.physicalSize / tester.view.devicePixelRatio;

      // Un tap ogni mezzo tempo di attesa: il conto non arriva mai in fondo.
      for (int i = 0; i < 4; i++) {
        await tester.pump(const Duration(minutes: kIdleMinutesDefault ~/ 2));
        clock.advance(kTapDebounce * 2);
        await tester.tapAt(Offset(size.width * 0.8, size.height / 2));
        await tester.pump();
      }

      expect(find.byType(IdleFace), findsNothing);
    });
  });

  group('roll delle cifre', () {
    Future<void> tapZone(WidgetTester tester, double fraction) async {
      final Size size = tester.view.physicalSize / tester.view.devicePixelRatio;
      await tester.tapAt(Offset(size.width * fraction, size.height / 2));
      await tester.pump();
    }

    testWidgets('a riposo non c e nessun roll in corso', (
      WidgetTester tester,
    ) async {
      await pumpScreen(tester, await repoWith(1234));

      for (final RollingDigit slot in tester.widgetList<RollingDigit>(
        find.byType(RollingDigit),
      )) {
        expect(slot.progress, 1);
      }
    });

    testWidgets('dopo un tap la cifra vecchia e la nuova convivono', (
      WidgetTester tester,
    ) async {
      await pumpScreen(tester, await repoWith(1234));

      await tapZone(tester, 0.8); // 1235
      await tester.pump(kDigitRollDuration ~/ 2);

      expect(find.text('4'), findsOneWidget, reason: 'la vecchia esce');
      expect(find.text('5'), findsOneWidget, reason: 'la nuova entra');
    });

    testWidgets('rollano solo le cifre che cambiano', (
      WidgetTester tester,
    ) async {
      await pumpScreen(tester, await repoWith(1234));

      await tapZone(tester, 0.8); // 1235: cambiano solo le unita
      await tester.pump(kDigitRollDuration ~/ 2);

      expect(find.text('1'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('finito il roll resta solo il numero nuovo', (
      WidgetTester tester,
    ) async {
      await pumpScreen(tester, await repoWith(1234));

      await tapZone(tester, 0.8);
      await tester.pump(kDigitRollDuration);
      await tester.pump();

      expect(find.text('5'), findsOneWidget);
      expect(find.text('4'), findsNothing);
    });

    testWidgets('il verso segue il conteggio', (WidgetTester tester) async {
      final FakeClock clock = await pumpScreen(tester, await repoWith(1234));

      await tapZone(tester, 0.8); // +1
      await tester.pump(kDigitRollDuration ~/ 2);
      expect(
        tester
            .widgetList<RollingDigit>(find.byType(RollingDigit))
            .last
            .rollingUp,
        isTrue,
      );

      await tester.pump(kDigitRollDuration);
      clock.advance(kTapDebounce * 2);

      await tapZone(tester, 0.1); // -1
      await tester.pump(kDigitRollDuration ~/ 2);
      expect(
        tester
            .widgetList<RollingDigit>(find.byType(RollingDigit))
            .last
            .rollingUp,
        isFalse,
        reason: 'in discesa il roll va al contrario',
      );
    });

    testWidgets('passando a una cifra in piu le unita restano unita', (
      WidgetTester tester,
    ) async {
      await pumpScreen(tester, await repoWith(99));

      await tapZone(tester, 0.8); // 100
      await tester.pump(kDigitRollDuration ~/ 2);

      final List<RollingDigit> slots = tester
          .widgetList<RollingDigit>(find.byType(RollingDigit))
          .toList();
      expect(slots, hasLength(kCounterDigits));
      expect(
        slots[3].previous,
        '0',
        reason: 'la cifra nuova sale dallo zero di riempimento',
      );
      expect(slots[3].current, '1');
      expect(slots.last.previous, '9');
      expect(slots.last.current, '0');
    });

    testWidgets('un tap durante un roll riparte dal numero visibile', (
      WidgetTester tester,
    ) async {
      final FakeClock clock = await pumpScreen(tester, await repoWith(10));

      await tapZone(tester, 0.8); // 11
      await tester.pump(kDigitRollDuration ~/ 3); // roll ancora in corso
      clock.advance(kTapDebounce * 2);
      await tapZone(tester, 0.8); // 12, mentre il primo rolla ancora

      await tester.pump(kDigitRollDuration ~/ 2);
      final RollingDigit unita = tester
          .widgetList<RollingDigit>(find.byType(RollingDigit))
          .last;
      expect(unita.previous, '1', reason: 'si riparte da quello che si vede');
      expect(unita.current, '2');
    });
  });

  group('marchio HoMD', () {
    testWidgets('resta in basso al centro anche dopo lo splash', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1920, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpScreen(tester, await repoWith(1234));
      await tester.pump(kSplashHold);
      await tester.pumpAndSettle();

      expect(find.byType(SplashOverlay), findsNothing);
      expect(find.byType(HomdMark), findsOneWidget);

      final Rect mark = tester.getRect(find.byType(HomdMark));
      expect(mark.center.dx, closeTo(1920 / 2, 1));
      expect(mark.bottom, closeTo(1200 - kHomdMarkBottom, 1));
    });

    testWidgets('non ruba tap alla zona +1', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1920, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final LocalCounterRepository repo = await repoWith(10);
      await pumpScreen(tester, repo);
      await tester.pump(kSplashHold);
      await tester.pumpAndSettle();

      await tester.tapAt(tester.getCenter(find.byType(HomdMark)));
      await tester.pumpAndSettle();

      expect(repo.total, 11, reason: 'il marchio e decorativo, il tap passa');
    });
  });

  group('splash', () {
    Future<void> waitOutSplash(WidgetTester tester) async {
      await tester.pump(kSplashHold);
      // La dissolvenza parte al frame dopo che il timer e' scaduto, e
      // onEnd arriva alla fine di quella: pumpAndSettle le copre entrambe.
      await tester.pumpAndSettle();
    }

    testWidgets('all avvio mostra il logo', (WidgetTester tester) async {
      await pumpScreen(tester, await repoWith(239338));

      expect(find.byType(SplashOverlay), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(SplashOverlay),
          matching: find.byType(HomdMark),
        ),
        findsOneWidget,
      );
      expect(find.text(kBrandNameLine1), findsOneWidget);
      expect(find.text(kBrandNameLine2), findsOneWidget);
      expect(find.text(kBrandPub), findsOneWidget);
      expect(find.text(kBrandTagline), findsOneWidget);

      await waitOutSplash(tester);
    });

    testWidgets('poi svanisce e lascia il contatore', (
      WidgetTester tester,
    ) async {
      await pumpScreen(tester, await repoWith(1234));
      await waitOutSplash(tester);

      expect(find.byType(SplashOverlay), findsNothing);
      expect(find.text('4'), findsOneWidget);
    });

    testWidgets('un tap mentre il logo e a video conta lo stesso', (
      WidgetTester tester,
    ) async {
      // E' il punto che conta: lo splash non deve mai mangiare un cicchetto.
      final LocalCounterRepository repo = await repoWith(100);
      await pumpScreen(tester, repo);
      expect(find.byType(SplashOverlay), findsOneWidget);

      final Size size = tester.view.physicalSize / tester.view.devicePixelRatio;
      await tester.tapAt(Offset(size.width * 0.8, size.height / 2));
      await tester.pump();

      expect(repo.total, 101);
      await waitOutSplash(tester);
    });

    testWidgets('il logo sta dentro allo schermo del tablet', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1920, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpScreen(tester, await repoWith(239338));
      await tester.pump();

      expect(tester.takeException(), isNull);
      await waitOutSplash(tester);
    });

    testWidgets('e ci sta anche su uno schermo stretto', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(800, 480);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpScreen(tester, await repoWith(239338));
      await tester.pump();

      expect(tester.takeException(), isNull);
      await waitOutSplash(tester);
    });
  });
}
