import 'package:flutter_test/flutter_test.dart';
import 'package:mad_dog_counter/config.dart';
import 'package:mad_dog_counter/data/counter_repository.dart';
import 'package:mad_dog_counter/data/tap_log.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Log finto che ricorda cosa gli e' stato chiesto di registrare.
class _SpyTapLog implements TapLog {
  final List<(int, TapType)> records = <(int, TapType)>[];

  @override
  Future<void> record(int delta, {TapType type = TapType.tap}) async {
    records.add((delta, type));
  }

  @override
  Future<List<TapRecord>> recent({int limit = 100}) async =>
      const <TapRecord>[];

  @override
  Future<List<TapRecord>> dumpAll() async => const <TapRecord>[];

  @override
  Future<int> sumOfDeltas() async {
    int sum = 0;
    for (final (int delta, TapType _) in records) {
      sum += delta;
    }
    return sum;
  }

  @override
  Future<void> close() async {}
}

Future<(LocalCounterRepository, _SpyTapLog)> openWith(
  Map<String, Object> initial,
) async {
  SharedPreferences.setMockInitialValues(initial);
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  final _SpyTapLog log = _SpyTapLog();
  final LocalCounterRepository repo = await LocalCounterRepository.open(
    prefs: prefs,
    log: log,
  );
  return (repo, log);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('al primo avvio parte da INITIAL_COUNT', () async {
    final (LocalCounterRepository repo, _) = await openWith(<String, Object>{});
    expect(repo.total, kInitialCount);
    expect(kInitialCount, 0, reason: 'decisione: si parte da zero');
  });

  test('riprende il totale salvato', () async {
    final (LocalCounterRepository repo, _) = await openWith(<String, Object>{
      kPrefsCounterTotal: 239338,
    });
    expect(repo.total, 239338);
  });

  test('incrementa e persiste', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final LocalCounterRepository repo = await LocalCounterRepository.open(
      prefs: prefs,
      log: _SpyTapLog(),
    );

    expect(await repo.increment(), 1);
    expect(await repo.increment(), 2);
    expect(prefs.getInt(kPrefsCounterTotal), 2);
  });

  test('decrementa', () async {
    final (LocalCounterRepository repo, _) = await openWith(<String, Object>{
      kPrefsCounterTotal: 10,
    });
    expect(await repo.decrement(), 9);
  });

  group('clamp a zero', () {
    test('non scende sotto zero', () async {
      final (LocalCounterRepository repo, _) = await openWith(<String, Object>{
        kPrefsCounterTotal: 1,
      });
      expect(await repo.decrement(), 0);
      expect(await repo.decrement(), 0);
      expect(await repo.decrement(), 0);
      expect(repo.total, kMinCount);
    });

    test('un decremento bloccato dal clamp non finisce nel log', () async {
      final (LocalCounterRepository repo, _SpyTapLog log) = await openWith(
        <String, Object>{kPrefsCounterTotal: 0},
      );
      await repo.decrement();
      expect(log.records, isEmpty);
    });

    test('setTotal negativo viene riportato a zero', () async {
      final (LocalCounterRepository repo, _) = await openWith(<String, Object>{
        kPrefsCounterTotal: 5,
      });
      expect(await repo.setTotal(-100), 0);
    });
  });

  group('log dei tap', () {
    test('ogni tap scrive un record di tipo tap', () async {
      final (LocalCounterRepository repo, _SpyTapLog log) = await openWith(
        <String, Object>{kPrefsCounterTotal: 5},
      );
      await repo.increment();
      await repo.decrement();
      expect(log.records, <(int, TapType)>[
        (1, TapType.tap),
        (-1, TapType.tap),
      ]);
    });

    test('setTotal scrive un adjust col delta risultante', () async {
      final (LocalCounterRepository repo, _SpyTapLog log) = await openWith(
        <String, Object>{kPrefsCounterTotal: 100},
      );
      await repo.setTotal(239338);
      expect(log.records, <(int, TapType)>[(239238, TapType.adjust)]);
    });

    test('setTotal allo stesso valore non scrive nulla', () async {
      final (LocalCounterRepository repo, _SpyTapLog log) = await openWith(
        <String, Object>{kPrefsCounterTotal: 42},
      );
      expect(await repo.setTotal(42), 42);
      expect(log.records, isEmpty);
    });
  });

  test('watchTotal emette subito il valore corrente', () async {
    final (LocalCounterRepository repo, _) = await openWith(<String, Object>{
      kPrefsCounterTotal: 7,
    });
    expect(await repo.watchTotal().first, 7);
  });

  test('watchTotal emette a ogni variazione', () async {
    final (LocalCounterRepository repo, _) = await openWith(<String, Object>{
      kPrefsCounterTotal: 0,
    });
    final Future<List<int>> collected = repo.watchTotal().take(3).toList();
    await repo.increment();
    await repo.increment();
    expect(await collected, <int>[0, 1, 2]);
  });
}
