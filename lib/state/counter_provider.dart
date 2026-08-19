/// Stato Riverpod del contatore.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/counter_repository.dart';
import '../data/tap_log.dart';

/// Il log dei tap. Sovrascritto in `main()` con l'istanza sqflite aperta,
/// e nei test con un [NoopTapLog].
final Provider<TapLog> tapLogProvider = Provider<TapLog>(
  (Ref ref) => const NoopTapLog(),
);

/// Il repository. Va sovrascritto in `main()` con l'istanza già aperta, così
/// l'app è pronta a contare senza attendere un future al primo frame.
final Provider<CounterRepository> counterRepositoryProvider =
    Provider<CounterRepository>(
      (Ref ref) => throw UnimplementedError(
        'counterRepositoryProvider va sovrascritto in main() con '
        'LocalCounterRepository.open()',
      ),
    );

/// Il totale corrente. Parte dal valore già in memoria, quindi non ha mai uno
/// stato di caricamento: il numerone è sullo schermo dal primo frame.
final StreamProvider<int> counterTotalProvider = StreamProvider<int>((Ref ref) {
  return ref.watch(counterRepositoryProvider).watchTotal();
});

/// Le azioni sul contatore.
///
/// Non restituiscono future attesi dalla UI: il conteggio non aspetta mai
/// nessuno (regola d'oro 2).
class CounterActions {
  const CounterActions(this._repository);

  final CounterRepository _repository;

  void increment() => _repository.increment();

  void decrement() => _repository.decrement();

  void setTotal(int value) => _repository.setTotal(value);
}

final Provider<CounterActions> counterActionsProvider =
    Provider<CounterActions>(
      (Ref ref) => CounterActions(ref.watch(counterRepositoryProvider)),
    );
