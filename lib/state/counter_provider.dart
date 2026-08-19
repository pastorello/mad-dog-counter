/// Stato Riverpod del contatore.
library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../audio/sound_manager.dart';
import '../data/backup_service.dart';
import '../data/counter_repository.dart';
import '../data/settings_repository.dart';
import '../data/tap_log.dart';
import 'effects_provider.dart';
import 'settings_provider.dart';

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

/// L'orologio usato dalla UI per il debounce dei tap.
///
/// È un provider e non `DateTime.now` diretto perché il debounce decide quali
/// tap contano: va potuto testare che non mangi il tapping veloce di una
/// combo, e con l'orologio di sistema il test dipenderebbe da quanto è veloce
/// la macchina che lo esegue.
final Provider<DateTime Function()> clockProvider =
    Provider<DateTime Function()>((Ref ref) => DateTime.now);

/// Il gestore audio. Sovrascritto in `main()` con quello vero; il default
/// silenzioso fa sì che i test e un'inizializzazione audio fallita non
/// impediscano all'app di contare.
final Provider<SoundManager> soundManagerProvider = Provider<SoundManager>(
  (Ref ref) => SilentSoundManager(),
);

/// Il motore effetti, agganciato alle variazioni del contatore.
///
/// L'aggancio è qui e non nella UI di proposito: gli effetti sono spettatori
/// del conteggio, non partecipanti. Se il motore muore, il contatore continua.
final Provider<EffectsEngine> effectsEngineProvider = Provider<EffectsEngine>((
  Ref ref,
) {
  final EffectsEngine engine = EffectsEngine(
    ref.watch(soundManagerProvider),
    idleDelay: Duration(minutes: ref.read(settingsProvider).idleMinutes),
  );

  // I minuti si cambiano dal pannello: si ascoltano, non si osservano con
  // watch, altrimenti ogni modifica ricostruirebbe il motore da capo e
  // butterebbe via la coda e gli stati persistenti.
  ref.listen(settingsProvider, (SettingsState? _, SettingsState next) {
    engine.idleDelay = Duration(minutes: next.idleMinutes);
  });

  final StreamSubscription<CounterChange> subscription = ref
      .watch(counterRepositoryProvider)
      .watchChanges()
      .listen(engine.onChange);

  ref.onDispose(() {
    subscription.cancel();
    engine.dispose();
  });

  return engine;
});

/// Lo stato del layer effetti, per la UI.
final StreamProvider<EffectsState> effectsStateProvider =
    StreamProvider<EffectsState>(
      (Ref ref) => ref.watch(effectsEngineProvider).watch(),
    );

/// Le impostazioni utente. Sovrascritto in `main()`.
final Provider<SettingsRepository> settingsRepositoryProvider =
    Provider<SettingsRepository>(
      (Ref ref) => throw UnimplementedError(
        'settingsRepositoryProvider va sovrascritto in main() con '
        'SettingsRepository.open()',
      ),
    );

/// Il servizio di backup. Sovrascritto in `main()` con la cartella vera;
/// senza override non esiste, e l'app conta lo stesso.
final Provider<BackupService?> backupServiceProvider = Provider<BackupService?>(
  (Ref ref) => null,
);

/// Tiene il backup aggiornato.
///
/// Controlla all'avvio e a ogni scrittura: il tablet sta acceso a muro per
/// settimane, quindi contare solo sull'avvio vorrebbe dire un backup al mese.
/// Il controllo è un confronto di date, e la scrittura è fire-and-forget:
/// nessun tap aspetta il disco.
final Provider<void> backupWatcherProvider = Provider<void>((Ref ref) {
  final BackupService? backup = ref.watch(backupServiceProvider);
  if (backup == null) return;

  unawaited(backup.backupIfNeeded());

  final StreamSubscription<CounterChange> subscription = ref
      .watch(counterRepositoryProvider)
      .watchChanges()
      .listen((CounterChange _) => unawaited(backup.backupIfNeeded()));

  ref.onDispose(subscription.cancel);
});
