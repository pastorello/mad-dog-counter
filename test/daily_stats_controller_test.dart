import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mad_dog_counter/config.dart';
import 'package:mad_dog_counter/data/settings_repository.dart';
import 'package:mad_dog_counter/data/tap_log.dart';
import 'package:mad_dog_counter/state/daily_stats_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Log finto con somme e incrementi programmabili.
///
/// IMPLEMENTA TapLog invece di estendere [NoopTapLog] di proposito: il
/// controller tratta i Noop come "nessun log" e deve invece credere a questo.
class _FakeRangeLog implements TapLog {
  _FakeRangeLog({this.sum = 0, this.increments = const <DateTime>[]});

  int sum;
  List<DateTime> increments;

  @override
  Future<int> sumOfTapDeltasBetween(DateTime start, DateTime end) async => sum;

  @override
  Future<List<DateTime>> incrementTimestampsSince(DateTime since) async =>
      increments;

  @override
  Future<void> record(int delta, {TapType type = TapType.tap}) async {}

  @override
  Future<List<TapRecord>> recent({int limit = 100}) async =>
      const <TapRecord>[];

  @override
  Future<int> sumOfDeltas() async => 0;

  @override
  Future<List<TapRecord>> dumpAll() async => const <TapRecord>[];

  @override
  Future<void> close() async {}
}

class _FakeTimer implements Timer {
  _FakeTimer(this._onCancel);
  final void Function() _onCancel;

  @override
  void cancel() => _onCancel();

  @override
  bool get isActive => true;

  @override
  int get tick => 0;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Sera di martedì 24/11/2026: finestra aperta a mezzogiorno dello stesso
  // giorno.
  DateTime now = DateTime(2026, 11, 24, 21);

  final List<({Duration delay, void Function() action})> timers =
      <({Duration delay, void Function() action})>[];

  Timer schedule(Duration delay, void Function() action) {
    timers.add((delay: delay, action: action));
    return _FakeTimer(() {});
  }

  Future<SettingsRepository> settingsWith(Map<String, Object> initial) async {
    SharedPreferences.setMockInitialValues(initial);
    return SettingsRepository(await SharedPreferences.getInstance());
  }

  DailyStatsController buildController({
    required SettingsRepository settings,
    TapLog log = const NoopTapLog(),
  }) => DailyStatsController(
    settings: settings,
    log: log,
    clock: () => now,
    scheduler: schedule,
  );

  setUp(() {
    now = DateTime(2026, 11, 24, 21);
    timers.clear();
  });

  group('init', () {
    test('parte dalla cache prefs quando la finestra è la stessa', () async {
      final SettingsRepository settings = await settingsWith(<String, Object>{
        kPrefsDailyWindowKey: '20261124',
        kPrefsDailyCount: 42,
        kPrefsBestDayCount: 100,
        kPrefsBestDayKey: '20261101',
      });
      final DailyStatsController c = buildController(settings: settings);
      await c.init();

      expect(c.state.windowKey, '20261124');
      expect(c.state.todayCount, 42);
      expect(c.state.bestCount, 100);
      expect(c.state.bestDayKey, '20261101');
      await c.dispose();
    });

    test('una cache di una finestra vecchia riparte da zero', () async {
      final SettingsRepository settings = await settingsWith(<String, Object>{
        kPrefsDailyWindowKey: '20261120',
        kPrefsDailyCount: 42,
        kPrefsBestDayCount: 100,
      });
      final DailyStatsController c = buildController(settings: settings);
      await c.init();

      expect(c.state.windowKey, '20261124');
      expect(c.state.todayCount, 0, reason: 'quel 42 era di un\'altra serata');
      expect(c.state.bestCount, 100, reason: 'il record non ha scadenza');
      await c.dispose();
    });

    test('quando il log è vero, il log vince sulla cache', () async {
      final SettingsRepository settings = await settingsWith(<String, Object>{
        kPrefsDailyWindowKey: '20261124',
        kPrefsDailyCount: 42,
      });
      final DailyStatsController c = buildController(
        settings: settings,
        log: _FakeRangeLog(sum: 57),
      );
      await c.init();

      expect(c.state.todayCount, 57);
      await c.dispose();
    });

    test('con NoopTapLog resta la cache', () async {
      final SettingsRepository settings = await settingsWith(<String, Object>{
        kPrefsDailyWindowKey: '20261124',
        kPrefsDailyCount: 42,
      });
      final DailyStatsController c = buildController(settings: settings);
      await c.init();

      expect(c.state.todayCount, 42);
      await c.dispose();
    });

    test('il seed del tilt arriva dal log', () async {
      final List<DateTime> seed = <DateTime>[
        now.subtract(const Duration(minutes: 30)),
      ];
      final SettingsRepository settings = await settingsWith(
        <String, Object>{},
      );
      final DailyStatsController c = buildController(
        settings: settings,
        log: _FakeRangeLog(increments: seed),
      );
      await c.init();

      expect(await c.tiltSeed, seed);
      await c.dispose();
    });

    test('arma il timer del prossimo mezzogiorno', () async {
      final SettingsRepository settings = await settingsWith(
        <String, Object>{},
      );
      final DailyStatsController c = buildController(settings: settings);
      await c.init();

      // Dalle 21:00 al mezzogiorno di domani: 15 ore.
      expect(timers.map((t) => t.delay), contains(const Duration(hours: 15)));
      await c.dispose();
    });
  });

  group('onTapDelta', () {
    test('somma netta e persistenza in prefs', () async {
      final SettingsRepository settings = await settingsWith(
        <String, Object>{},
      );
      final DailyStatsController c = buildController(settings: settings);
      await c.init();

      c.onTapDelta(1);
      c.onTapDelta(1);
      c.onTapDelta(-1);

      expect(c.state.todayCount, 1);
      // Le scritture sono fire-and-forget: un giro di event loop e sono lì.
      await Future<void>.delayed(Duration.zero);
      expect(settings.dailyCount, 1);
      expect(
        settings.dailyWindowKey,
        isNull,
        reason: 'si scrive solo al cambio finestra',
      );
      await c.dispose();
    });

    test('il primissimo mad dog è già un record e si festeggia', () async {
      final SettingsRepository settings = await settingsWith(
        <String, Object>{},
      );
      final DailyStatsController c = buildController(settings: settings);
      await c.init();

      final DailyTapOutcome outcome = c.onTapDelta(1);
      expect(outcome.recordSurpassed, isTrue);
      expect(c.state.bestCount, 1);
      await c.dispose();
    });

    test('la festa parte una volta sola per finestra', () async {
      final SettingsRepository settings = await settingsWith(
        <String, Object>{},
      );
      final DailyStatsController c = buildController(settings: settings);
      await c.init();

      expect(c.onTapDelta(1).recordSurpassed, isTrue);
      expect(c.onTapDelta(1).recordSurpassed, isFalse);
      expect(c.onTapDelta(1).recordSurpassed, isFalse);
      await c.dispose();
    });

    test(
      'a cavallo di mezzogiorno il tap apre da solo la finestra nuova',
      () async {
        final SettingsRepository settings = await settingsWith(
          <String, Object>{},
        );
        final DailyStatsController c = buildController(settings: settings);
        await c.init();
        c.onTapDelta(1);
        expect(c.state.windowKey, '20261124');

        // Il giorno dopo, alle 12:30, arriva il primo tap: nessun timer è
        // scattato (il finto scheduler non scatta da solo), ma la finestra
        // si apre comunque.
        now = DateTime(2026, 11, 25, 12, 30);
        c.onTapDelta(1);

        expect(c.state.windowKey, '20261125');
        expect(c.state.todayCount, 1);
        expect(c.state.bestCount, 1, reason: 'il ratchet di ieri resta');
        await c.dispose();
      },
    );
  });

  group('rolloverIfNeeded', () {
    test('è idempotente per chiave di finestra', () async {
      final SettingsRepository settings = await settingsWith(
        <String, Object>{},
      );
      final _FakeRangeLog log = _FakeRangeLog(sum: 3);
      final DailyStatsController c = buildController(
        settings: settings,
        log: log,
      );
      await c.init();
      expect(c.state.todayCount, 3);

      // Mezzogiorno passa; il log della finestra nuova dice 0.
      now = DateTime(2026, 11, 25, 12, 5);
      log.sum = 0;
      await c.rolloverIfNeeded();
      expect(c.state.windowKey, '20261125');

      // Richiamarla non cambia niente: la chiave è il lucchetto.
      log.sum = 99;
      await c.rolloverIfNeeded();
      expect(c.state.todayCount, 0);
      await c.dispose();
    });

    test('dentro la stessa finestra non fa nulla', () async {
      final SettingsRepository settings = await settingsWith(
        <String, Object>{},
      );
      final DailyStatsController c = buildController(settings: settings);
      await c.init();
      c.onTapDelta(1);

      await c.rolloverIfNeeded();
      expect(c.state.todayCount, 1);
      expect(c.state.windowKey, '20261124');
      await c.dispose();
    });

    test('la celebrazione si riarma a ogni finestra nuova', () async {
      final SettingsRepository settings = await settingsWith(
        <String, Object>{},
      );
      final DailyStatsController c = buildController(settings: settings);
      await c.init();
      expect(c.onTapDelta(1).recordSurpassed, isTrue); // best 1, festeggiato

      now = DateTime(2026, 11, 25, 13);
      await c.rolloverIfNeeded();

      expect(
        c.onTapDelta(1).recordSurpassed,
        isFalse,
        reason: '1 non supera 1',
      );
      expect(c.onTapDelta(1).recordSurpassed, isTrue, reason: '2 supera 1');
      await c.dispose();
    });
  });
}
