/// Le impostazioni utente come stato osservabile.
///
/// Il repository sa leggerle e scriverle; questo notifier le tiene in memoria
/// per la UI e propaga i cambi a chi li deve subire (il [SoundManager], il
/// motore effetti per i parametri del tilt).
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config.dart';
import '../data/settings_repository.dart';
import 'counter_provider.dart';

class SettingsState {
  const SettingsState({
    required this.soundEnabled,
    required this.idleMinutes,
    required this.tiltThreshold,
    required this.tiltDurationSeconds,
    required this.tiltMessage,
  });

  final bool soundEnabled;
  final int idleMinutes;

  /// Oltre quanti mad dog in [kTiltWindow] scatta il tilt.
  final int tiltThreshold;

  /// Quanti secondi resta in scena il tilt.
  final int tiltDurationSeconds;

  /// Il messaggio sotto al TILT. Può essere vuoto mentre lo si riscrive:
  /// a video, vuoto ⇒ si mostra [kTiltMessageDefault].
  final String tiltMessage;

  /// Il messaggio effettivamente mostrato dalla scena.
  String get effectiveTiltMessage =>
      tiltMessage.trim().isEmpty ? kTiltMessageDefault : tiltMessage;

  SettingsState copyWith({
    bool? soundEnabled,
    int? idleMinutes,
    int? tiltThreshold,
    int? tiltDurationSeconds,
    String? tiltMessage,
  }) => SettingsState(
    soundEnabled: soundEnabled ?? this.soundEnabled,
    idleMinutes: idleMinutes ?? this.idleMinutes,
    tiltThreshold: tiltThreshold ?? this.tiltThreshold,
    tiltDurationSeconds: tiltDurationSeconds ?? this.tiltDurationSeconds,
    tiltMessage: tiltMessage ?? this.tiltMessage,
  );
}

class SettingsNotifier extends Notifier<SettingsState> {
  @override
  SettingsState build() {
    final SettingsRepository repository = ref.watch(settingsRepositoryProvider);
    return SettingsState(
      soundEnabled: repository.soundEnabled,
      idleMinutes: repository.idleMinutes,
      tiltThreshold: repository.tiltThreshold,
      tiltDurationSeconds: repository.tiltDurationSeconds,
      tiltMessage: repository.tiltMessage,
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

  void setTiltThreshold(int value) {
    final int clamped = value.clamp(kTiltThresholdMin, kTiltThresholdMax);
    if (clamped == state.tiltThreshold) return;
    state = state.copyWith(tiltThreshold: clamped);
    ref.read(settingsRepositoryProvider).setTiltThreshold(clamped);
  }

  void setTiltDurationSeconds(int value) {
    final int clamped = value.clamp(
      kTiltDurationSecondsMin,
      kTiltDurationSecondsMax,
    );
    if (clamped == state.tiltDurationSeconds) return;
    state = state.copyWith(tiltDurationSeconds: clamped);
    ref.read(settingsRepositoryProvider).setTiltDurationSeconds(clamped);
  }

  /// Il testo si salva com'è, anche vuoto (si sta riscrivendo): il fallback
  /// al default è compito di chi lo mostra ([SettingsState.effectiveTiltMessage]).
  void setTiltMessage(String value) {
    if (value == state.tiltMessage) return;
    state = state.copyWith(tiltMessage: value);
    ref.read(settingsRepositoryProvider).setTiltMessage(value);
  }
}

final NotifierProvider<SettingsNotifier, SettingsState> settingsProvider =
    NotifierProvider<SettingsNotifier, SettingsState>(SettingsNotifier.new);
