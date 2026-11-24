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

  // --- Record del giorno (cache: quando il log sqflite c'è, fa fede lui) ---

  /// La finestra giornaliera di cui parlano [dailyCount] e
  /// [recordCelebratedWindow]. Null al primissimo avvio.
  String? get dailyWindowKey => _prefs.getString(kPrefsDailyWindowKey);

  Future<void> setDailyWindowKey(String value) async {
    try {
      await _prefs.setString(kPrefsDailyWindowKey, value);
    } catch (_) {
      // Cache: al prossimo avvio si ricalcola dal log.
    }
  }

  /// Conteggio della finestra corrente.
  int get dailyCount => _prefs.getInt(kPrefsDailyCount) ?? 0;

  Future<void> setDailyCount(int value) async {
    try {
      await _prefs.setInt(kPrefsDailyCount, value);
    } catch (_) {
      // idem
    }
  }

  /// Il record storico e la finestra in cui è stato fatto.
  int get bestDayCount => _prefs.getInt(kPrefsBestDayCount) ?? 0;

  Future<void> setBestDayCount(int value) async {
    try {
      await _prefs.setInt(kPrefsBestDayCount, value);
    } catch (_) {
      // idem
    }
  }

  String? get bestDayKey => _prefs.getString(kPrefsBestDayKey);

  Future<void> setBestDayKey(String value) async {
    try {
      await _prefs.setString(kPrefsBestDayKey, value);
    } catch (_) {
      // idem
    }
  }

  /// La finestra in cui la festa del record è già partita.
  String? get recordCelebratedWindow =>
      _prefs.getString(kPrefsRecordCelebratedWindow);

  Future<void> setRecordCelebratedWindow(String value) async {
    try {
      await _prefs.setString(kPrefsRecordCelebratedWindow, value);
    } catch (_) {
      // Al peggio si festeggia due volte: un dramma sopportabile.
    }
  }

  // --- Tilt ---

  /// Oltre quanti mad dog in [kTiltWindow] scatta il tilt.
  int get tiltThreshold =>
      _prefs.getInt(kPrefsTiltThreshold) ?? kTiltThresholdDefault;

  Future<void> setTiltThreshold(int value) async {
    try {
      await _prefs.setInt(kPrefsTiltThreshold, value);
    } catch (_) {
      // idem
    }
  }

  /// Quanti secondi resta in scena il tilt.
  int get tiltDurationSeconds =>
      _prefs.getInt(kPrefsTiltDurationSeconds) ?? kTiltDurationSecondsDefault;

  Future<void> setTiltDurationSeconds(int value) async {
    try {
      await _prefs.setInt(kPrefsTiltDurationSeconds, value);
    } catch (_) {
      // idem
    }
  }

  /// Ogni quanti tap di combo piomba il timbro gigante di Ciommo.
  int get ciommoInterval =>
      _prefs.getInt(kPrefsCiommoInterval) ?? kCiommoIntervalDefault;

  Future<void> setCiommoInterval(int value) async {
    try {
      await _prefs.setInt(kPrefsCiommoInterval, value);
    } catch (_) {
      // idem
    }
  }

  /// Il messaggio sotto al TILT. Vuoto ⇒ la UI mostra il default.
  String get tiltMessage =>
      _prefs.getString(kPrefsTiltMessage) ?? kTiltMessageDefault;

  Future<void> setTiltMessage(String value) async {
    try {
      await _prefs.setString(kPrefsTiltMessage, value);
    } catch (_) {
      // idem
    }
  }
}
