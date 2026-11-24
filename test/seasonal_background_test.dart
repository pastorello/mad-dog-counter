import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mad_dog_counter/config.dart';
import 'package:mad_dog_counter/data/counter_repository.dart';
import 'package:mad_dog_counter/data/settings_repository.dart';
import 'package:mad_dog_counter/state/counter_provider.dart';
import 'package:mad_dog_counter/state/season.dart';
import 'package:mad_dog_counter/ui/counter_screen.dart';
import 'package:mad_dog_counter/ui/effects/seasonal_background.dart';
import 'package:mad_dog_counter/ui/widgets/settings_gear.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Lo sfondo stagionale sul tabellone vero (v2, DECISIONS → 06).
class _Clock {
  DateTime _now = DateTime(2026);
  DateTime call() => _now;
  void advance(Duration d) => _now = _now.add(d);
}

void main() {
  Future<({LocalCounterRepository repo, _Clock clock})> pumpWith(
    WidgetTester tester, {
    String? season,
  }) async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      kPrefsCounterTotal: 0,
      kPrefsSeason: ?season,
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
    return (repo: repo, clock: clock);
  }

  testWidgets('di default non c e nessuna stagione in scena', (
    WidgetTester tester,
  ) async {
    await pumpWith(tester);
    expect(
      find.byType(CustomPaint).evaluate().where((e) {
        final CustomPaint paint = e.widget as CustomPaint;
        return paint.painter.runtimeType.toString().contains('Halloween') ||
            paint.painter.runtimeType.toString().contains('Christmas');
      }),
      isEmpty,
    );
  });

  testWidgets('con Halloween attivo lo sfondo c e e non mangia i tap', (
    WidgetTester tester,
  ) async {
    final r = await pumpWith(tester, season: Season.halloween.dbValue);

    expect(find.byType(SeasonalBackground), findsOneWidget);

    // Sta DIETRO a tutto: il primo figlio dello Stack.
    final Stack stack = tester.widget<Stack>(
      find
          .descendant(of: find.byType(Scaffold), matching: find.byType(Stack))
          .first,
    );
    expect(
      (stack.children.first as Positioned).child.runtimeType.toString(),
      contains('Consumer'),
      reason: 'lo sfondo stagionale apre lo Stack',
    );

    // E i tap passano: il conteggio non si ferma mai.
    final Size size = tester.view.physicalSize / tester.view.devicePixelRatio;
    r.clock.advance(kTapDebounce * 2);
    await tester.tapAt(Offset(size.width * 0.8, size.height / 2));
    await tester.pump(const Duration(milliseconds: 16));
    expect(r.repo.total, 1);
  });

  testWidgets('la stagione si cambia dal pannello e si salva', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1920, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await pumpWith(tester);

    // Apri il pannello con la pressione lunga sull'ingranaggio.
    final TestGesture gesture = await tester.startGesture(
      tester.getCenter(find.byType(SettingsGear)),
    );
    await tester.pump(kSettingsLongPress);
    await gesture.up();
    await tester.pumpAndSettle();

    expect(find.text(kSettingsSeasonLabel), findsOneWidget);
    await tester.tap(find.text(kSeasonChristmasLabel));
    await tester.pump();

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(kPrefsSeason), Season.christmas.dbValue);
  });
}
