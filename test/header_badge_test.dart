import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mad_dog_counter/config.dart';
import 'package:mad_dog_counter/data/counter_repository.dart';
import 'package:mad_dog_counter/data/settings_repository.dart';
import 'package:mad_dog_counter/data/tap_log.dart';
import 'package:mad_dog_counter/state/counter_provider.dart';
import 'package:mad_dog_counter/state/daily_stats_provider.dart';
import 'package:mad_dog_counter/ui/counter_screen.dart';
import 'package:mad_dog_counter/ui/widgets/header_title.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Intestazione «MAD DOG COUNTER» e badge OGGI/RECORD (v2, DECISIONS → 01).
class _Clock {
  DateTime _now = DateTime(2026, 11, 24, 21);
  DateTime call() => _now;
  void advance(Duration d) => _now = _now.add(d);
}

/// Timer che non esiste: il controller arma il mezzogiorno, ma qui nessun
/// rollover deve scattare e nessun timer vero deve restare appeso.
class _InertTimer implements Timer {
  const _InertTimer();

  @override
  void cancel() {}

  @override
  bool get isActive => false;

  @override
  int get tick => 0;
}

Timer _noSchedule(Duration _, void Function() _) => const _InertTimer();

void main() {
  Future<
    ({LocalCounterRepository repo, _Clock clock, DailyStatsController daily})
  >
  pumpApp(WidgetTester tester, {Map<String, Object> prefs = const {}}) async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      kPrefsCounterTotal: 0,
      ...prefs,
    });
    final LocalCounterRepository repo = await LocalCounterRepository.open();
    final SettingsRepository settings = await SettingsRepository.open();
    final _Clock clock = _Clock();
    final DailyStatsController daily = DailyStatsController(
      settings: settings,
      log: const NoopTapLog(),
      clock: clock.call,
      scheduler: _noSchedule,
    );
    await daily.init();
    addTearDown(daily.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          counterRepositoryProvider.overrideWithValue(repo),
          settingsRepositoryProvider.overrideWithValue(settings),
          clockProvider.overrideWithValue(clock.call),
          dailyStatsControllerProvider.overrideWithValue(daily),
        ],
        child: const MaterialApp(home: CounterScreen()),
      ),
    );
    await tester.pump();
    return (repo: repo, clock: clock, daily: daily);
  }

  Future<void> tapIncrement(
    WidgetTester tester,
    _Clock clock, [
    int times = 1,
  ]) async {
    final Size size = tester.view.physicalSize / tester.view.devicePixelRatio;
    for (int i = 0; i < times; i++) {
      clock.advance(kTapDebounce * 2);
      await tester.tapAt(Offset(size.width * 0.8, size.height / 2));
      await tester.pump(const Duration(milliseconds: 16));
    }
  }

  group('intestazione', () {
    testWidgets('e a schermo, a riposo', (WidgetTester tester) async {
      await pumpApp(tester);
      expect(find.text(kHeaderText), findsOneWidget);

      final AnimatedOpacity fade = tester.widget<AnimatedOpacity>(
        find.descendant(
          of: find.byType(HeaderTitle),
          matching: find.byType(AnimatedOpacity),
        ),
      );
      expect(fade.opacity, 1);
    });

    testWidgets('si dissolve quando parte la combo e poi torna', (
      WidgetTester tester,
    ) async {
      final r = await pumpApp(tester);
      await tapIncrement(tester, r.clock, kComboMinCount);
      await tester.pump();

      AnimatedOpacity fade = tester.widget<AnimatedOpacity>(
        find.descendant(
          of: find.byType(HeaderTitle),
          matching: find.byType(AnimatedOpacity),
        ),
      );
      expect(fade.opacity, 0, reason: 'la fascia alta e degli eventi');

      // La finestra della combo scade: l'intestazione torna.
      await tester.pump(kComboWindow + const Duration(milliseconds: 50));
      await tester.pumpAndSettle();
      fade = tester.widget<AnimatedOpacity>(
        find.descendant(
          of: find.byType(HeaderTitle),
          matching: find.byType(AnimatedOpacity),
        ),
      );
      expect(fade.opacity, 1);
    });
  });

  group('badge OGGI/RECORD', () {
    testWidgets('primo giorno: OGGI 0 · RECORD —', (WidgetTester tester) async {
      await pumpApp(tester);
      await tester.pump();

      expect(
        find.text(
          '$kDailyLabel 0 · $kRecordLabel $kRecordEmptyPlaceholder',
          findRichText: true,
        ),
        findsOneWidget,
      );
    });

    testWidgets('si aggiorna coi tap e mostra il record', (
      WidgetTester tester,
    ) async {
      final r = await pumpApp(tester);
      await tapIncrement(tester, r.clock, 3);
      await tester.pump();

      // Tre mad dog: giornaliero 3, e col ratchet il record e gia 3.
      expect(
        find.text('$kDailyLabel 3 · $kRecordLabel 3', findRichText: true),
        findsOneWidget,
      );
    });

    testWidgets('nessun Text a cifra singola: il numerone non si confonde', (
      WidgetTester tester,
    ) async {
      final r = await pumpApp(tester);
      await tapIncrement(tester, r.clock, 1);
      // Fine del roll: la cifra vecchia e la nuova convivono per la durata
      // del roll, e qui si contano i Text.
      await tester.pump(kDigitRollDuration);
      await tester.pump();

      // Il totale e' 1: il numerone mostra 000001. Il badge dice OGGI 1 ma
      // non deve produrre un Text il cui intero contenuto sia '1'.
      expect(
        find.text('1'),
        findsOneWidget,
        reason: 'solo la cifra del numerone',
      );
      expect(find.text('0'), findsNWidgets(kCounterDigits - 1));
    });

    testWidgets('il giornaliero mostrato non scende sotto zero', (
      WidgetTester tester,
    ) async {
      final r = await pumpApp(tester);
      // Un decremento a totale zero non conta; ma un -1 dopo un adjust si'.
      r.repo.setTotal(10);
      await tester.pump();
      final Size size = tester.view.physicalSize / tester.view.devicePixelRatio;
      r.clock.advance(kTapDebounce * 2);
      await tester.tapAt(Offset(size.width * 0.1, size.height / 2));
      await tester.pump();

      // Giornaliero netto: -1. A video: 0.
      expect(r.daily.state.todayCount, -1);
      expect(
        find.text(
          '$kDailyLabel 0 · $kRecordLabel $kRecordEmptyPlaceholder',
          findRichText: true,
        ),
        findsOneWidget,
      );
    });
  });
}
