import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mad_dog_counter/config.dart';
import 'package:mad_dog_counter/data/counter_repository.dart';
import 'package:mad_dog_counter/data/settings_repository.dart';
import 'package:mad_dog_counter/state/counter_provider.dart';
import 'package:mad_dog_counter/ui/counter_screen.dart';
import 'package:mad_dog_counter/ui/effects/tilt_overlay.dart';
import 'package:mad_dog_counter/ui/widgets/panic_button.dart';
import 'package:mad_dog_counter/ui/widgets/settings_gear.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// La scena TILT sul tabellone vero: compare oltre soglia, NON mangia i tap
/// (regola d'oro 2) e lascia libere le vie d'uscita (panico, ingranaggio).
class _Clock {
  DateTime _now = DateTime(2026, 11, 24, 21);
  DateTime call() => _now;
  void advance(Duration d) => _now = _now.add(d);
}

void main() {
  Future<({LocalCounterRepository repo, _Clock clock})> pumpWithTilt(
    WidgetTester tester, {
    int threshold = 10,
  }) async {
    tester.view.physicalSize = const Size(1920, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    SharedPreferences.setMockInitialValues(<String, Object>{
      kPrefsCounterTotal: 0,
      kPrefsTiltThreshold: threshold,
      kPrefsTiltDurationSeconds: kTiltDurationSecondsMin,
    });
    final LocalCounterRepository repo = await LocalCounterRepository.open();
    final SettingsRepository settings = await SettingsRepository.open();
    final _Clock clock = _Clock();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          counterRepositoryProvider.overrideWithValue(repo),
          settingsRepositoryProvider.overrideWithValue(settings),
          clockProvider.overrideWithValue(clock.call),
        ],
        child: const MaterialApp(home: CounterScreen()),
      ),
    );
    await tester.pump();
    // Via lo splash: dopo hold + fade non intercetta più niente di visibile.
    await tester.pump(kSplashHold);
    await tester.pump(kSplashFade);
    await tester.pump();
    return (repo: repo, clock: clock);
  }

  Future<void> tapIncrement(WidgetTester tester, _Clock clock) async {
    clock.advance(kTapDebounce * 2);
    await tester.tapAt(const Offset(1920 * 0.8, 600));
    await tester.pump(const Duration(milliseconds: 16));
  }

  testWidgets('oltre soglia compare la scena TILT', (
    WidgetTester tester,
  ) async {
    final r = await pumpWithTilt(tester);

    for (int i = 0; i < 10; i++) {
      await tapIncrement(tester, r.clock);
    }
    expect(find.byType(TiltOverlay), findsNothing, reason: '10 non supera 10');

    await tapIncrement(tester, r.clock);
    await tester.pump();

    expect(find.byType(TiltOverlay), findsOneWidget);
    expect(find.text(kTiltTitle), findsOneWidget);
    expect(find.text(kTiltMessageDefault), findsOneWidget);
    expect(r.repo.total, 11);
  });

  testWidgets('durante il tilt i tap passano attraverso la scena e contano', (
    WidgetTester tester,
  ) async {
    final r = await pumpWithTilt(tester);
    for (int i = 0; i < 11; i++) {
      await tapIncrement(tester, r.clock);
    }
    expect(find.byType(TiltOverlay), findsOneWidget);

    await tapIncrement(tester, r.clock);
    await tapIncrement(tester, r.clock);

    expect(
      r.repo.total,
      13,
      reason: 'la scena è un IgnorePointer: il conteggio non si blocca mai',
    );
    expect(find.byType(TiltOverlay), findsOneWidget);
  });

  testWidgets('il tilt non copre panico e ingranaggio, e il panico lo spegne', (
    WidgetTester tester,
  ) async {
    final r = await pumpWithTilt(tester);
    for (int i = 0; i < 11; i++) {
      await tapIncrement(tester, r.clock);
    }
    expect(find.byType(TiltOverlay), findsOneWidget);

    // Le vie d'uscita restano in cima: un tap sul panico arriva al panico.
    expect(find.byType(PanicButton), findsOneWidget);
    expect(find.byType(SettingsGear), findsOneWidget);

    await tester.tap(find.byType(PanicButton));
    await tester.pump();

    expect(
      find.byType(TiltOverlay),
      findsNothing,
      reason: 'il kill switch è l\'uscita manuale dal tilt',
    );

    // L'esplosione del panico fa il suo corso senza lasciare timer appesi.
    await tester.pump(kPanicBlastDuration);
    await tester.pump();
  });

  testWidgets('la scena mostra il messaggio personalizzato', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1920, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    SharedPreferences.setMockInitialValues(<String, Object>{
      kPrefsCounterTotal: 0,
      kPrefsTiltThreshold: kTiltThresholdMin,
      kPrefsTiltDurationSeconds: kTiltDurationSecondsMin,
      kPrefsTiltMessage: 'PIANO COI CICCHETTI',
    });
    final LocalCounterRepository repo = await LocalCounterRepository.open();
    final SettingsRepository settings = await SettingsRepository.open();
    final _Clock clock = _Clock();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          counterRepositoryProvider.overrideWithValue(repo),
          settingsRepositoryProvider.overrideWithValue(settings),
          clockProvider.overrideWithValue(clock.call),
        ],
        child: const MaterialApp(home: CounterScreen()),
      ),
    );
    await tester.pump(kSplashHold);
    await tester.pump(kSplashFade);
    await tester.pump();

    for (int i = 0; i <= kTiltThresholdMin; i++) {
      await tapIncrement(tester, clock);
    }

    expect(find.byType(TiltOverlay), findsOneWidget);
    expect(find.text('PIANO COI CICCHETTI'), findsOneWidget);
  });
}
