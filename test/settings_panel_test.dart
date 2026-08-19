import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mad_dog_counter/audio/sound_manager.dart';
import 'package:mad_dog_counter/config.dart';
import 'package:mad_dog_counter/data/counter_repository.dart';
import 'package:mad_dog_counter/data/settings_repository.dart';
import 'package:mad_dog_counter/state/counter_provider.dart';
import 'package:mad_dog_counter/ui/counter_screen.dart';
import 'package:mad_dog_counter/ui/settings_panel.dart';
import 'package:mad_dog_counter/ui/widgets/panic_button.dart';
import 'package:mad_dog_counter/ui/widgets/settings_gear.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Clock {
  DateTime _now = DateTime(2026);
  DateTime call() => _now;
  void advance(Duration d) => _now = _now.add(d);
}

class _SpySounds implements SoundManager {
  @override
  bool enabled = kSoundEnabledDefault;

  @override
  Future<void> preload() async {}

  @override
  void play(String asset, {double rate = 1.0}) {}

  @override
  void stopAll() {}

  @override
  Future<void> dispose() async {}
}

Future<({LocalCounterRepository repo, _Clock clock, _SpySounds sounds})>
pumpApp(WidgetTester tester, {int total = 100}) async {
  SharedPreferences.setMockInitialValues(<String, Object>{
    kPrefsCounterTotal: total,
  });
  final LocalCounterRepository repo = await LocalCounterRepository.open();
  final SettingsRepository settings = await SettingsRepository.open();
  final _Clock clock = _Clock();
  final _SpySounds sounds = _SpySounds();

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        counterRepositoryProvider.overrideWithValue(repo),
        settingsRepositoryProvider.overrideWithValue(settings),
        soundManagerProvider.overrideWithValue(sounds),
        clockProvider.overrideWithValue(clock.call),
      ],
      child: const MaterialApp(home: CounterScreen()),
    ),
  );
  await tester.pump();
  return (repo: repo, clock: clock, sounds: sounds);
}

/// Tiene premuto l'ingranaggio per la durata data.
Future<void> holdGear(WidgetTester tester, Duration duration) async {
  final TestGesture gesture = await tester.startGesture(
    tester.getCenter(find.byType(SettingsGear)),
  );
  await tester.pump(duration);
  await gesture.up();
  await tester.pump();
}

void main() {
  group('apertura', () {
    testWidgets('un tap semplice non apre niente', (WidgetTester tester) async {
      await pumpApp(tester);

      await tester.tap(find.byType(SettingsGear));
      await tester.pump();

      expect(find.byType(SettingsPanel), findsNothing);
    });

    testWidgets('una pressione breve non basta', (WidgetTester tester) async {
      await pumpApp(tester);

      await holdGear(tester, kSettingsLongPress - const Duration(seconds: 1));

      expect(find.byType(SettingsPanel), findsNothing);
    });

    testWidgets('la pressione lunga di 3 s apre il pannello', (
      WidgetTester tester,
    ) async {
      await pumpApp(tester);

      await holdGear(tester, kSettingsLongPress);
      await tester.pumpAndSettle();

      expect(find.byType(SettingsPanel), findsOneWidget);
      expect(find.text(kSettingsTitle), findsOneWidget);
    });

    testWidgets('il tap sull ingranaggio non conta come incremento', (
      WidgetTester tester,
    ) async {
      final r = await pumpApp(tester, total: 100);

      await tester.tap(find.byType(SettingsGear));
      await tester.pump();

      expect(r.repo.total, 100);
    });
  });

  group('mentre e aperto', () {
    testWidgets('i tap sul contatore sono disabilitati', (
      WidgetTester tester,
    ) async {
      final r = await pumpApp(tester, total: 100);
      await holdGear(tester, kSettingsLongPress);
      await tester.pumpAndSettle();

      final Size size = tester.view.physicalSize / tester.view.devicePixelRatio;
      await tester.tapAt(Offset(size.width * 0.8, size.height / 2));
      await tester.pump();

      expect(r.repo.total, 100, reason: 'il pannello copre le zone di tap');
    });

    testWidgets('gli effetti si fermano senza esplosione', (
      WidgetTester tester,
    ) async {
      await pumpApp(tester);
      await holdGear(tester, kSettingsLongPress);
      await tester.pumpAndSettle();

      expect(
        find.byType(PanicBlast),
        findsNothing,
        reason: 'e un killAll silenzioso, non il pulsante panico',
      );
    });
  });

  group('imposta contatore', () {
    Future<void> openAndType(WidgetTester tester, String value) async {
      await holdGear(tester, kSettingsLongPress);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), value);
      await tester.tap(find.text(kSettingsApply));
      await tester.pumpAndSettle();
    }

    testWidgets('mostra vecchio → nuovo prima di applicare', (
      WidgetTester tester,
    ) async {
      final r = await pumpApp(tester, total: 100);
      await openAndType(tester, '239338');

      expect(find.text('100 → 239338'), findsOneWidget);
      expect(
        r.repo.total,
        100,
        reason: 'niente e cambiato finche non si conferma',
      );
    });

    testWidgets('la conferma applica il nuovo totale', (
      WidgetTester tester,
    ) async {
      final r = await pumpApp(tester, total: 100);
      await openAndType(tester, '239338');

      await tester.tap(find.text(kSettingsConfirm));
      await tester.pumpAndSettle();

      expect(r.repo.total, 239338);
    });

    testWidgets('annulla non tocca il totale', (WidgetTester tester) async {
      final r = await pumpApp(tester, total: 100);
      await openAndType(tester, '239338');

      await tester.tap(find.text(kSettingsCancel));
      await tester.pumpAndSettle();

      expect(r.repo.total, 100);
      expect(find.text('100 → 239338'), findsNothing);
    });

    testWidgets('un valore fuori scala viene rifiutato', (
      WidgetTester tester,
    ) async {
      final r = await pumpApp(tester, total: 100);
      await openAndType(tester, '999999999999');

      expect(find.text(kSettingsInvalidNumber), findsOneWidget);
      expect(r.repo.total, 100);
    });

    testWidgets('un campo vuoto viene rifiutato', (WidgetTester tester) async {
      final r = await pumpApp(tester, total: 100);
      await openAndType(tester, '');

      expect(find.text(kSettingsInvalidNumber), findsOneWidget);
      expect(r.repo.total, 100);
    });
  });

  group('audio', () {
    testWidgets('l interruttore ha effetto subito sul SoundManager', (
      WidgetTester tester,
    ) async {
      final r = await pumpApp(tester);
      await holdGear(tester, kSettingsLongPress);
      await tester.pumpAndSettle();

      expect(r.sounds.enabled, isTrue);

      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      expect(r.sounds.enabled, isFalse);
    });

    testWidgets('la scelta finisce nelle preferenze', (
      WidgetTester tester,
    ) async {
      await pumpApp(tester);
      await holdGear(tester, kSettingsLongPress);
      await tester.pumpAndSettle();

      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      final SharedPreferences prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool(kPrefsSoundEnabled), isFalse);
    });
  });

  group('minuti di idle', () {
    testWidgets('parte dal default e si puo alzare', (
      WidgetTester tester,
    ) async {
      await pumpApp(tester);
      await holdGear(tester, kSettingsLongPress);
      await tester.pumpAndSettle();

      expect(find.text('$kIdleMinutesDefault'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.add_circle_outline));
      await tester.pumpAndSettle();

      expect(find.text('${kIdleMinutesDefault + 1}'), findsOneWidget);
    });
  });

  group('chiusura', () {
    testWidgets('Chiudi e l unica uscita e restituisce il contatore', (
      WidgetTester tester,
    ) async {
      final r = await pumpApp(tester, total: 100);
      await holdGear(tester, kSettingsLongPress);
      await tester.pumpAndSettle();

      await tester.tap(find.text(kSettingsClose));
      await tester.pumpAndSettle();

      expect(find.byType(SettingsPanel), findsNothing);

      final Size size = tester.view.physicalSize / tester.view.devicePixelRatio;
      await tester.tapAt(Offset(size.width * 0.8, size.height / 2));
      await tester.pumpAndSettle();

      expect(
        r.repo.total,
        101,
        reason: 'il primo tap dopo la chiusura non deve essere scartato',
      );
    });
  });
}
