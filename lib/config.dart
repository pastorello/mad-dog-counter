/// Costanti di configurazione dell'app.
///
/// Regola d'oro 4 (CLAUDE.md): qui dentro vive OGNI numero magico e OGNI
/// stringa mostrata a schermo. Niente valori sparsi nel codice.
///
/// I valori regolabili dall'utente (audio on/off, minuti di idle) NON stanno
/// qui: vivono in shared_preferences. Qui c'è solo il loro default.
library;

import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// Contatore
// ---------------------------------------------------------------------------

/// Valore iniziale al primissimo avvio, quando `counter_total` non esiste.
///
/// Si parte da zero di proposito: il subentro al vecchio counter del pub si fa
/// a mano dal pannello impostazioni il giorno dell'installazione, perché il
/// counter vecchio resta in servizio fino allo switch e continua a salire.
/// Vedi docs/FUNCTIONAL_SPEC.md → Migrazione.
const int kInitialCount = 0;

/// Il contatore non scende mai sotto questo valore.
const int kMinCount = 0;

/// Debounce sui tap, contro i doppi tocchi hardware.
/// Volutamente basso: non deve penalizzare il tapping veloce delle combo.
const Duration kTapDebounce = Duration(milliseconds: 80);

// ---------------------------------------------------------------------------
// Combo
// ---------------------------------------------------------------------------

/// Tempo massimo tra due incrementi perché la combo prosegua.
const Duration kComboWindow = Duration(seconds: 2);

/// Numero di tap consecutivi da cui la combo è considerata "lunga" e
/// iniziano a comparire i timbri "Ciommo Approved".
///
/// DA CONFERMARE col committente (CLAUDE.md → Domande aperte): valore
/// provvisorio, esiste una variante alternativa basata sui cicchetti di sessione.
const int kComboCiommoThreshold = 5;

/// Soglie a cui la combo cambia livello (moltiplicatore e testo celebrativo).
const List<int> kComboThresholds = <int>[3, 5, 8, 12, 20];

/// Testi celebrativi delle combo, uno per soglia in [kComboThresholds].
///
/// PROVVISORI: la lista definitiva arriva dai baristi
/// (CLAUDE.md → Domande aperte).
const List<String> kComboTexts = <String>[
  'Bello!',
  'Grande!',
  'Fantastico!',
  'Incredibile!',
  'LEGGENDARIO!',
];

// ---------------------------------------------------------------------------
// Idle
// ---------------------------------------------------------------------------

/// Default dei minuti di inattività prima della faccina annoiata.
/// Il valore effettivo è modificabile dal pannello impostazioni.
const int kIdleMinutesDefault = 10;

/// Default dell'interruttore audio.
const bool kSoundEnabledDefault = true;

// ---------------------------------------------------------------------------
// Durate degli effetti
// ---------------------------------------------------------------------------
// Da tarare a mano sul tablet vero (ANIMATIONS_SPEC.md). Sono qui apposta
// perché la taratura sia un numero da cambiare, non un refactoring.

/// Pulsazione del numerone a ogni tap.
const Duration kTapPulseDuration = Duration(milliseconds: 150);

/// Roll verticale della singola cifra che cambia.
const Duration kDigitRollDuration = Duration(milliseconds: 220);

/// Shake orizzontale quando il totale finisce per 67.
const Duration kShake67Duration = Duration(milliseconds: 1500);

/// Fuochi d'artificio sui multipli di 100.
const Duration kFireworksDuration = Duration(milliseconds: 3500);

/// Palla da bowling + ricomposizione sui multipli di 1000.
const Duration kStrikeDuration = Duration(milliseconds: 5500);

/// Morph delle cifre quando una coppia di 8 adiacenti si forma o si rompe.
const Duration kBoobsMorphDuration = Duration(milliseconds: 400);

/// Esplosione a tutto schermo del pulsante panico.
const Duration kPanicBlastDuration = Duration(milliseconds: 1000);

/// Micro-animazione di risveglio della faccina idle al primo tap.
const Duration kIdleWakeDuration = Duration(milliseconds: 1000);

// ---------------------------------------------------------------------------
// Controlli di servizio
// ---------------------------------------------------------------------------

/// Durata della pressione lunga sull'ingranaggio per aprire le impostazioni.
/// Il tap semplice non fa nulla: è a prova di dita ubriache.
const Duration kSettingsLongPress = Duration(seconds: 3);

/// Frazione di larghezza schermo occupata dalla zona di decremento (sinistra).
/// Il resto è zona di incremento.
const double kDecrementZoneWidthFraction = 0.25;

// ---------------------------------------------------------------------------
// Palette (UX_UI_SPEC.md → Brand system)
// ---------------------------------------------------------------------------
// Colori ufficiali di stampa: bianco / Pantone 186C / Pantone 2728C.
// Mai bianco puro, mai rosa.

/// Sfondo nero-antracite, con una punta di blu come nei logo.
const Color kBackground = Color(0xFF0E0E14);

/// Rosso Pantone 186C — il rosso del bicchiere House of Mad Dogs.
const Color kPrimaryRed = Color(0xFFC8102E);

/// Blu Pantone 2728C pieno, per gli accenti (feedback del decremento).
const Color kAccentBlue = Color(0xFF0047BB);

/// Navy della bandierina, per le superfici.
const Color kSurfaceNavy = Color(0xFF204070);

/// Bianco sporco: il testo e il numerone. Mai `Colors.white`.
const Color kTextColor = Color(0xFFF0F0F0);

/// Oro/ambra dei momenti epici: fuochi, glow della combo.
const Color kCelebrationGold = Color(0xFFF0A830);

// ---------------------------------------------------------------------------
// Tipografia
// ---------------------------------------------------------------------------

/// Font del numerone e dei testi celebrativi (lettering brush, come il poster).
const String kDisplayFont = 'Creepster';

/// Alternativa più morbida, già nel pacchetto: da validare sul tablet vero.
const String kDisplayFontAlt = 'Knewave';

// ---------------------------------------------------------------------------
// Storage
// ---------------------------------------------------------------------------

/// Chiave shared_preferences del totale. Fonte di verità del prodotto.
const String kPrefsCounterTotal = 'counter_total';

/// Chiave shared_preferences dell'interruttore audio.
const String kPrefsSoundEnabled = 'sound_enabled';

/// Chiave shared_preferences dei minuti di idle.
const String kPrefsIdleMinutes = 'idle_minutes';

/// Nome del database sqflite che ospita il log dei tap.
const String kTapLogDatabase = 'mad_dog_taps.db';

/// Versione dello schema del log dei tap.
const int kTapLogSchemaVersion = 1;

// ---------------------------------------------------------------------------
// Suoni (assets/sounds/)
// ---------------------------------------------------------------------------
// Set sintetizzato proceduralmente, nessuna licenza da gestire.
// I nomi dei file sono il contratto col codice: per cambiare un suono si
// sostituisce il WAV mantenendo il nome. Mappa completa e durate in
// assets/sounds/README.md.
//
// Il percorso e' relativo alla root degli asset: `audioplayers` con
// AssetSource vuole il path senza il prefisso `assets/`.

const String _sfxDir = 'sounds';

/// Tap di incremento.
const String kSfxTapPop = '$_sfxDir/tap_pop.wav';

/// Tap di decremento: blip discendente, volutamente diverso dall'incremento.
const String kSfxTapDown = '$_sfxDir/tap_down.wav';

/// Soglie della combo. Per il pitch crescente dei pop si riusa [kSfxTapPop]
/// con playback rate variabile, non un file per livello.
const String kSfxComboMilestone = '$_sfxDir/combo_milestone.wav';

/// Il totale finisce per 67.
const String kSfxWobble67 = '$_sfxDir/wobble_67.wav';

/// Trasformazione degli 8 adiacenti. Solo al momento del morph, mai in loop.
const String kSfxBoing = '$_sfxDir/boing.wav';

/// Multiplo di 100.
const String kSfxFireworks = '$_sfxDir/fireworks.wav';

/// Multiplo di 1000, parte 1: rotolamento, da sincronizzare con l'ingresso
/// della palla.
const String kSfxBowlingRoll = '$_sfxDir/bowling_roll.wav';

/// Multiplo di 1000, parte 2: impatto, birilli e campanella.
const String kSfxBowlingStrike = '$_sfxDir/bowling_strike.wav';

/// Pulsante panico.
const String kSfxPanicExplosion = '$_sfxDir/panic_explosion.wav';

/// Risveglio dopo l'idle. L'idle in se' e' muto per specifica: non deve
/// disturbare il pub nei momenti calmi.
const String kSfxWakeJubilation = '$_sfxDir/wake_jubilation.wav';

/// Tutti i suoni, per il precaricamento all'avvio.
const List<String> kAllSfx = <String>[
  kSfxTapPop,
  kSfxTapDown,
  kSfxComboMilestone,
  kSfxWobble67,
  kSfxBoing,
  kSfxFireworks,
  kSfxBowlingRoll,
  kSfxBowlingStrike,
  kSfxPanicExplosion,
  kSfxWakeJubilation,
];

/// Quanti player audio tenere in pool. Durante una combo i pop si
/// sovrappongono: con un player solo ogni tap taglierebbe il precedente.
const int kSfxPoolSize = 6;

/// Ritardo tra il rotolamento della palla e l'impatto sui birilli, nello
/// strike dei multipli di 1000. Corrisponde alla durata di `bowling_roll.wav`.
const Duration kStrikeImpactDelay = Duration(milliseconds: 1800);

// ---------------------------------------------------------------------------
// Combo — parametri di taratura
// ---------------------------------------------------------------------------

/// Da quanti tap consecutivi si vede il moltiplicatore.
/// Sotto questa soglia non c'è ancora "combo", c'è solo gente che conta.
const int kComboMinCount = 2;

/// Di quanto sale il pitch del pop a ogni tap della combo.
/// Si riusa `tap_pop.wav` accelerandolo, invece di un file per livello.
const double kComboPitchStep = 0.06;

/// Tetto del pitch: oltre, il pop diventa un fischio.
const double kComboPitchMax = 1.8;

/// Quanti timbri "Ciommo Approved" al massimo contemporaneamente a schermo.
const int kComboCiommoMaxStamps = 5;

/// Durata della dissolvenza a fine combo.
/// «Gli effetti sfumano dolcemente» (ANIMATIONS_SPEC → Fine combo).
const Duration kComboFadeDuration = Duration(milliseconds: 450);

/// Durata dello schiaffo di timbro di Ciommo.
const Duration kComboStampDuration = Duration(milliseconds: 260);

// ---------------------------------------------------------------------------
// Asset immagine
// ---------------------------------------------------------------------------

/// Timbro "Ciommo Approved", line-art bianco sporco su fondo scuro.
const String kImgCiommoApproved = 'assets/images/ciommo_approved.png';

/// Variante badge rotonda dello stesso timbro.
const String kImgCiommoSticker = 'assets/images/ciommo_sticker_round.png';

// ---------------------------------------------------------------------------
// Pannello impostazioni
// ---------------------------------------------------------------------------

/// Estremi ammessi per i minuti di idle. Sotto il minimo la faccina
/// comparirebbe tra un giro di Mad Dog e l'altro; sopra il massimo non
/// comparirebbe mai.
const int kIdleMinutesMin = 1;
const int kIdleMinutesMax = 60;

/// Valore massimo accettato dal campo "Imposta contatore". Non è un limite di
/// prodotto, è una rete contro il dito che resta premuto sul tastierino.
const int kMaxSettableTotal = 99999999;

// Testi del pannello. Stanno qui come tutto il resto della UI
// (regola d'oro 4): niente stringhe cablate nei widget.
const String kSettingsTitle = 'Impostazioni';
const String kSettingsCounterLabel = 'Imposta contatore';
const String kSettingsCounterHint = 'Nuovo totale';
const String kSettingsApply = 'Imposta';
const String kSettingsConfirm = 'Conferma';
const String kSettingsCancel = 'Annulla';
const String kSettingsAudioLabel = 'Effetti sonori';
const String kSettingsIdleLabel = 'Minuti di inattività';
const String kSettingsClose = 'Chiudi';
const String kSettingsInvalidNumber =
    'Serve un numero tra 0 e $kMaxSettableTotal';

// ---------------------------------------------------------------------------
// Numerone
// ---------------------------------------------------------------------------

/// Quanta altezza dello schermo può occupare una cifra.
const double kBigNumberHeightFraction = 0.45;

/// Quanta larghezza può occupare il numero intero: il resto è respiro ai lati.
const double kBigNumberWidthFraction = 0.92;

/// Larghezza dello slot di una cifra, in proporzione alla sua dimensione.
/// Slot a larghezza fissa perché i font brush non hanno cifre tabular e il
/// numero ballerebbe a ogni cifra che cambia (UX_UI_SPEC → Tipografia).
const double kDigitSlotRatio = 0.62;

// ---------------------------------------------------------------------------
// Idle — la faccina annoiata
// ---------------------------------------------------------------------------

/// Lato del quadrato in cui sta la faccina.
const double kIdleFaceSize = 320;

/// Durata di un ciclo di respiro: sale, sospira, scende. Lento di proposito.
const Duration kIdleBreathDuration = Duration(milliseconds: 3600);

/// L'ambra della faccina. È l'oro celebrativo della palette: l'arancio del
/// riferimento non è un colore di brand, questo sì e gli somiglia.
const Color kIdleFaceColor = kCelebrationGold;

/// Il riflesso pallido in fondo agli occhioni. Bianco sporco, mai puro.
const Color kIdleEyeSheen = kTextColor;
