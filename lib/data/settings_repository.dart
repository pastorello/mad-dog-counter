/// Le impostazioni regolabili dall'utente.
///
/// Stanno in shared_preferences, non in `config.dart`: lì ci sono solo i loro
/// default (CLAUDE.md → regola d'oro 4). Qui c'è l'unico punto che le legge e
/// le scrive, così il pannello impostazioni e il resto dell'app non toccano
/// mai lo storage direttamente.
library;

import 'package:shared_preferences/shared_preferences.dart';

import '../config.dart';

class SettingsRepository {
  const SettingsRepository(this._prefs);

  final SharedPreferences _prefs;

  static Future<SettingsRepository> open({SharedPreferences? prefs}) async {
    return SettingsRepository(prefs ?? await SharedPreferences.getInstance());
  }

  /// Interruttore audio degli effetti sonori.
  bool get soundEnabled =>
      _prefs.getBool(kPrefsSoundEnabled) ?? kSoundEnabledDefault;

  Future<void> setSoundEnabled(bool value) async {
    try {
      await _prefs.setBool(kPrefsSoundEnabled, value);
    } catch (_) {
      // Un'impostazione che non si salva è un fastidio, non un disastro:
      // non deve mai propagare.
    }
  }

  /// Ultimo giorno di cui esiste un backup, in formato `YYYYMMDD`.
  /// Null se non è mai stato fatto.
  String? get lastBackupDay => _prefs.getString(kPrefsLastBackupDay);

  Future<void> setLastBackupDay(String day) async {
    try {
      await _prefs.setString(kPrefsLastBackupDay, day);
    } catch (_) {
      // Se non si segna, domani si rifà: un backup in più non fa danni.
    }
  }

  /// Minuti di inattività prima della faccina annoiata.
  int get idleMinutes =>
      _prefs.getInt(kPrefsIdleMinutes) ?? kIdleMinutesDefault;

  Future<void> setIdleMinutes(int value) async {
    try {
      await _prefs.setInt(kPrefsIdleMinutes, value);
    } catch (_) {
      // idem
    }
  }
}
