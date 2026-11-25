import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mad_dog_counter/config.dart';
import 'package:mad_dog_counter/data/counter_repository.dart';
import 'package:mad_dog_counter/data/settings_repository.dart';
import 'package:mad_dog_counter/state/counter_provider.dart';
import 'package:mad_dog_counter/state/daily_stats.dart';
import 'package:mad_dog_counter/state/daily_stats_provider.dart';
import 'package:mad_dog_counter/state/season.dart';
import 'package:mad_dog_counter/ui/counter_screen.dart';
import 'package:mad_dog_counter/ui/effects/seasonal_background.dart';
import 'package:mad_dog_counter/ui/widgets/daily_stats_badge.dart';
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
        final String painters =
            '${paint.painter.runtimeType} ${paint.foregroundPainter.runtimeType}';
        return painters.contains('Halloween') || painters.contains('Christmas');
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

  /// L'angolo del record (in alto a sinistra) resta libero: decorazioni e
  /// neve non ci disegnano niente, in nessun momento del ciclo. Si guarda il
  /// pittore delle decorazioni da solo: la cornice ci passa, ed è voluto.
  for (final Season season in <Season>[Season.halloween, Season.christmas]) {
    testWidgets('${season.name}: niente decorazioni sopra il record', (
      WidgetTester tester,
    ) async {
      const Size screen = Size(1920, 1200);
      tester.view.physicalSize = screen;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(SeasonalBackground(season: season));

      final Rect zone = kSeasonRecordClearZone;
      for (int step = 0; step < 8; step++) {
        await tester.pump(kSeasonCycleDuration ~/ 8);
        final CustomPaint paint = tester.widget<CustomPaint>(
          find.descendant(
            of: find.byType(SeasonalBackground),
            matching: find.byType(CustomPaint),
          ),
        );
        final ui.PictureRecorder recorder = ui.PictureRecorder();
        paint.foregroundPainter!.paint(Canvas(recorder), screen);
        final ui.Image image = recorder.endRecording().toImageSync(
          screen.width.toInt(),
          screen.height.toInt(),
        );
        final ByteData bytes = (await tester.runAsync(
          () async => (await image.toByteData())!,
        ))!;
        image.dispose();

        int alphaAt(int x, int y) =>
            bytes.getUint8((y * screen.width.toInt() + x) * 4 + 3);

        int inside = 0;
        for (int y = 0; y < zone.bottom.toInt(); y++) {
          for (int x = 0; x < zone.right.toInt(); x++) {
            if (alphaAt(x, y) != 0) inside++;
          }
        }
        expect(inside, 0, reason: 'passo $step: niente pixel sopra il record');

        // E non è un pittore vuoto: fuori dalla zona disegna eccome.
        int outside = 0;
        for (int y = 0; y < screen.height.toInt(); y += 4) {
          for (int x = 0; x < screen.width.toInt(); x += 4) {
            if (!zone.contains(Offset(x.toDouble(), y.toDouble())) &&
                alphaAt(x, y) != 0) {
              outside++;
            }
          }
        }
        expect(outside, greaterThan(0), reason: 'le decorazioni ci sono');
      }
    });
  }

  group('col font vero', () {
    // Con quello di test (glifi quadrati) il badge verrebbe largo il doppio
    // di quello che si vede sul tablet. Caricato prima dei test: dentro un
    // testWidgets l'avviso «font cambiati» chiederebbe un frame di troppo.
    setUpAll(() async {
      final FontLoader oswald = FontLoader(kBrandFont)
        ..addFont(rootBundle.load('assets/fonts/Oswald-Bold.ttf'));
      await oswald.load();
    });

    testWidgets('il badge del record sta tutto nella zona libera', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1920, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      // Numeri a cinque cifre: più largo di così il badge non diventa.
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            dailyStatsProvider.overrideWith(
              (Ref ref) => Stream<DailyStats>.value(
                const DailyStats(
                  windowKey: '20261124',
                  todayCount: 99999,
                  bestCount: 99999,
                ),
              ),
            ),
          ],
          child: const Directionality(
            textDirection: TextDirection.ltr,
            child: Stack(
              children: <Widget>[
                Positioned(
                  top: kBadgeTop,
                  left: kBadgeLeft,
                  child: DailyStatsBadge(),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pump();

      final Rect badge = tester.getRect(find.byType(DailyStatsBadge));
      expect(badge.width, greaterThan(0), reason: 'il badge e a schermo');
      expect(badge.right, lessThanOrEqualTo(kSeasonRecordClearZone.right));
      expect(badge.bottom, lessThanOrEqualTo(kSeasonRecordClearZone.bottom));
    });
  });
}
