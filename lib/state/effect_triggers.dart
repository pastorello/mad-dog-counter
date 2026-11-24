/// Logica pura dei trigger easter egg.
///
/// Regola d'oro 3 (CLAUDE.md): nessuna dipendenza da storage, widget o tempo
/// di sistema. Solo funzioni pure, così sono testabili davvero.
///
/// REGOLA MADRE (ANIMATIONS_SPEC → regola 0): tutto qui dentro si valuta
/// **solo dopo un incremento**. Il chiamante non deve mai invocare
/// [triggersFor] dopo un decremento.
library;

/// Gli effetti celebrativi del catalogo, con la loro durata indicativa.
enum EffectKind {
  /// Multiplo di 100: fuochi d'artificio.
  fireworks,

  /// Multiplo di 1000: palla da bowling e cifre per aria.
  strike,

  /// Il totale finisce per 67: il numerone trema.
  shake67,

  /// Il giornaliero ha superato il record: NUOVO RECORD! in oro.
  ///
  /// Non dipende dal totale ma dal record del giorno: il chiamante lo passa
  /// a [triggersFor] come flag. È un evento indipendente come lo shake,
  /// fuori dalla regola di assorbimento dei multipli.
  dailyRecord,

  /// Multiplo di 10.000: la pioggia di Mad Dog (bicchierini fitti in oro).
  madDogRain,

  /// Multiplo di 100.000: l'apoteosi. Il momento più epico di tutti.
  apotheosis,
}

/// `total % 100 == 0`.
bool isMultipleOf100(int total) => total > 0 && total % 100 == 0;

/// `total % 1000 == 0`.
bool isMultipleOf1000(int total) => total > 0 && total % 1000 == 0;

/// Le ultime due cifre sono `67`.
bool endsWith67(int total) => total % 100 == 67;

/// Il numero contiene due `8` consecutivi (es. 239881).
///
/// Stato persistente, non un effetto in coda: vale finché la coppia resta
/// nel numero.
bool hasAdjacentEights(int total) {
  final String digits = total.abs().toString();
  for (int i = 0; i + 1 < digits.length; i++) {
    if (digits[i] == '8' && digits[i + 1] == '8') return true;
  }
  return false;
}

/// Indici di partenza delle coppie di 8 adiacenti da trasformare in tette.
///
/// Le coppie non si sovrappongono: in `888` viene presa solo la prima
/// (indici 0-1), il terzo 8 resta una cifra normale.
List<int> adjacentEightPairs(int total) {
  final String digits = total.abs().toString();
  final List<int> pairs = <int>[];
  int i = 0;
  while (i + 1 < digits.length) {
    if (digits[i] == '8' && digits[i + 1] == '8') {
      pairs.add(i);
      i += 2; // consuma la coppia: niente sovrapposizioni
    } else {
      i++;
    }
  }
  return pairs;
}

/// Durata indicativa di un effetto, usata per ordinare la coda.
/// Non sono le durate reali (quelle stanno in `config.dart`): qui serve solo
/// un ordinamento stabile, e tenerlo puro evita di importare Flutter.
int effectWeight(EffectKind kind) => switch (kind) {
  EffectKind.shake67 => 1500,
  EffectKind.fireworks => 3500,
  EffectKind.dailyRecord => 4000,
  EffectKind.strike => 5500,
  EffectKind.madDogRain => 7000,
  EffectKind.apotheosis => 9000,
};

/// La milestone del totale, se c'è.
///
/// La catena è ordinata dal più raro, e **il più raro vince** (regola di
/// assorbimento generalizzata, ANIMATIONS_SPEC → §4): ogni milestone più
/// grande è anche multiplo delle più piccole, quindi sullo stesso tap
/// scatta solo lei — l'apoteosi assorbe tutto, la pioggia assorbe strike e
/// fuochi, lo strike assorbe i fuochi.
EffectKind? milestoneFor(int total) {
  if (total <= 0) return null;
  if (total % 100000 == 0) return EffectKind.apotheosis;
  if (total % 10000 == 0) return EffectKind.madDogRain;
  if (total % 1000 == 0) return EffectKind.strike;
  if (total % 100 == 0) return EffectKind.fireworks;
  return null;
}

/// Gli effetti da accodare per [total], già ordinati per durata crescente:
/// prima i corti, per ultimo l'evento più epico che chiude in bellezza
/// (ANIMATIONS_SPEC → regola 1).
///
/// Applica la **regola di assorbimento** via [milestoneFor]: delle milestone
/// scatta solo la più rara. Lo shake del 67 e il record del giorno sono
/// eventi indipendenti e si accodano accanto a lei.
///
/// Da chiamare SOLO dopo un incremento. [dailyRecord] dice se con questo tap
/// il giornaliero ha superato il record (lo sa il chiamante, non il totale).
List<EffectKind> triggersFor(int total, {bool dailyRecord = false}) {
  final List<EffectKind> effects = <EffectKind>[];

  if (endsWith67(total)) effects.add(EffectKind.shake67);

  if (dailyRecord) effects.add(EffectKind.dailyRecord);

  if (milestoneFor(total) case final EffectKind milestone) {
    effects.add(milestone);
  }

  effects.sort(
    (EffectKind a, EffectKind b) => effectWeight(a).compareTo(effectWeight(b)),
  );
  return effects;
}
