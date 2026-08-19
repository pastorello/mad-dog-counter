/// Le impostazioni utente come stato osservabile.
///
/// Il repository sa leggerle e scriverle; questo notifier le tiene in memoria
/// per la UI e propaga i cambi a chi li deve subire (il [SoundManager]).
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config.dart';
import '../data/settings_repository.dart';
import 'counter_provider.dart';

class SettingsState {
  const SettingsState({required this.soundEnabled, required this.idleMinutes});

  final bool soundEnabled;
  final int idleMinutes;

  SettingsState copyWith({bool? soundEnabled, int? idleMinutes}) =>
      SettingsState(
        soundEnabled: soundEnabled ?? this.soundEnabled,
        idleMinutes: idleMinutes ?? this.idleMinutes,
      );
}

class SettingsNotifier extends Notifier<SettingsState> {
  @override
  SettingsState build() {
    final SettingsRepository repository = ref.watch(settingsRepositoryProvider);
    return SettingsState(
      soundEnabled: repository.soundEnabled,
      idleMinutes: repository.idleMinutes,
    );
  }

  void setSoundEnabled(bool value) {
    state = state.copyWith(soundEnabled: value);
    // L'interruttore deve avere effetto subito, non al prossimo avvio.
    ref.read(soundManagerProvider).enabled = value;
    ref.read(settingsRepositoryProvider).setSoundEnabled(value);
  }

  /// I minuti restano dentro gli estremi ammessi: il campo non deve poter
  /// mettere l'idle in uno stato assurdo.
  void setIdleMinutes(int value) {
    final int clamped = value.clamp(kIdleMinutesMin, kIdleMinutesMax);
    if (clamped == state.idleMinutes) return;
    state = state.copyWith(idleMinutes: clamped);
    ref.read(settingsRepositoryProvider).setIdleMinutes(clamped);
  }
}

final NotifierProvider<SettingsNotifier, SettingsState> settingsProvider =
    NotifierProvider<SettingsNotifier, SettingsState>(SettingsNotifier.new);
