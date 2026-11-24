/// La finestra giornaliera del pub: da mezzogiorno a mezzogiorno.
///
/// Regola d'oro 3 (CLAUDE.md): funzioni pure, niente storage, niente orologio
/// di sistema. Il tempo arriva sempre come argomento.
///
/// Il "giorno" del record non è il giorno di calendario: la serata vive a
/// cavallo della mezzanotte, quindi la finestra si chiude a
/// [kDayRolloverHour] (mezzogiorno), quando il pub è certamente vuoto.
///
/// Nota sul cambio d'ora: le finestre si definiscono in ora locale, quindi
/// due volte l'anno una finestra dura 23 o 25 ore. Accettato: il tabellone
/// vive nell'ora del pub, non in UTC.
library;

import '../config.dart';

String _dateKey(DateTime day) =>
    '${day.year.toString().padLeft(4, '0')}'
    '${day.month.toString().padLeft(2, '0')}'
    '${day.day.toString().padLeft(2, '0')}';

/// La data del mezzogiorno che ha aperto la finestra in cui cade [now],
/// in formato `YYYYMMDD`: prima di mezzogiorno si è ancora nella finestra
/// aperta ieri.
///
/// Il giorno precedente si calcola col calendario (`day - 1`), non
/// sottraendo 24 ore: nei giorni da 25 ore le due cose non coincidono.
String dailyWindowKey(DateTime now) {
  if (now.hour >= kDayRolloverHour) return _dateKey(now);
  return _dateKey(DateTime(now.year, now.month, now.day - 1));
}

/// L'istante di apertura della finestra in cui cade [now]: il mezzogiorno
/// di oggi, o di ieri se non è ancora mezzogiorno.
DateTime windowStartFor(DateTime now) {
  if (now.hour >= kDayRolloverHour) {
    return DateTime(now.year, now.month, now.day, kDayRolloverHour);
  }
  return DateTime(now.year, now.month, now.day - 1, kDayRolloverHour);
}

/// Il prossimo mezzogiorno DOPO [now]: quando va programmato il timer di
/// chiusura. Mai nel passato; a mezzogiorno in punto risponde domani.
DateTime nextNoonAfter(DateTime now) {
  if (now.hour >= kDayRolloverHour) {
    return DateTime(now.year, now.month, now.day + 1, kDayRolloverHour);
  }
  return DateTime(now.year, now.month, now.day, kDayRolloverHour);
}
