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

// Le due salve partono dai angoli bassi e sparano verso il centro alto: una
// copre la meta' sinistra dello schermo, l'altra la meta' destra. I valori
// sotto servono a farle ARRIVARE al centro — con la forza iniziale la salva
// si spegneva a un quarto di schermo e i coriandoli si notavano appena.

/// Spinta iniziale di un coriandolo dei fuochi, minima e massima.
///
/// Tarata a schermo sul tablet: sotto i 120 la salva si spegneva
/// nell'angolo senza arrivare al centro, sopra i 300 lo attraversava in
/// mezzo secondo e usciva dal bordo alto. Qui i coriandoli fanno l'arco e
/// restano in scena per la durata dell'effetto.
const double kFireworksBlastForceMin = 110;
const double kFireworksBlastForceMax = 220;

/// Inclinazione del tiro rispetto all'orizzonte, in radianti (45°).
///
/// Conta quanto la forza: a 60° i coriandoli salivano quasi dritti e
/// ricadevano vicino all'angolo. A 45° la componente orizzontale e quella
/// verticale sono uguali, e la salva spazza davvero la sua metà schermo.
const double kFireworksBlastAngle = 0.7853981633974483; // pi / 4

/// Attrito dell'aria: sotto il default del pacchetto (0,05), altrimenti i
/// coriandoli frenano prima di arrivare a meta' schermo.
const double kFireworksDrag = 0.015;

/// Quanto in fretta ricadono. Bassa: devono attraversare in arco, non
/// tuffarsi subito né sfilare dritti fuori dal bordo alto.
const double kFireworksGravity = 0.15;

/// Quanti coriandoli per salva, e ogni quanto ne parte uno.
const int kFireworksParticles = 20;
const double kFireworksEmissionFrequency = 0.05;

/// Palla da bowling + ricomposizione sui multipli di 1000.
const Duration kStrikeDuration = Duration(milliseconds: 5500);

/// Durata della pioggia di cuoricini che accompagna le tette.
const Duration kHeartsBurstDuration = Duration(milliseconds: 900);

/// Quanti cuoricini partono nella salva.
const int kHeartsCount = 18;

/// Gravità dei cuoricini: devono ricadere, non galleggiare.
const double kHeartsGravity = 0.45;

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
const Duration kSettingsLongPress = Duration(seconds: 2);

/// Spessore dell'anello rosso che si riempie mentre si tiene premuto:
/// sottile non si notava, e la pressione lunga sembrava non fare niente.
const double kSettingsRingStroke = 4;

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

/// Rosa carne delle tette (effetto 8 adiacenti) e rosa dei cuoricini.
/// Sono l'unica eccezione al "niente rosa" della palette (UX_UI_SPEC →
/// Palette): lì il divieto nasce da una foto con dominante calda, qui il rosa
/// è la battuta — un 88 rosso non si legge come una tetta.
const Color kFleshPink = Color(0xFFEFA79B);
const Color kHeartPink = Color(0xFFE86A8A);

/// Altezza della bandierina olandese in fondo allo schermo. Tre strisce: sotto
/// una certa altezza, da dietro il bancone, non si vedono proprio.
const double kDutchFlagHeight = 12;

// ---------------------------------------------------------------------------
// Tipografia
// ---------------------------------------------------------------------------

/// Font del numerone e dei testi celebrativi (lettering brush, come il poster).
const String kDisplayFont = 'Creepster';

/// Alternativa più morbida, già nel pacchetto: da validare sul tablet vero.
const String kDisplayFontAlt = 'Knewave';

/// Font del logo HoMD: "HOUSE OF MAD DOGS" e la tagline. È il font vero,
/// preso dal vettoriale ufficiale del committente (Sottobicchiere HoMD
/// 93x93.pdf, font incorporato Oswald-Bold), non un sans generico a caso.
const String kBrandFont = 'Oswald';

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

/// La parola che sbatte in alto quando la palla colpisce.
const String kStrikeText = 'STRIKE!';

/// Corpo della parola: più grande dei testi combo, è il momento più epico.
const double kStrikeTextSize = 88;

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

/// Quanto rosso di fondo prende TUTTO lo schermo al culmine della combo:
/// il bagliore non si ferma alle zone di tap, tinge anche la fascia -1.
const double kComboGlowBaseAlpha = 0.10;

/// Raggio del nucleo caldo attorno al numerone, in frazione del lato corto.
/// Oltre 1 perché deve arrivare fino agli angoli, non spegnersi a metà.
const double kComboGlowRadius = 1.2;

/// Durata della dissolvenza a fine combo.
/// «Gli effetti sfumano dolcemente» (ANIMATIONS_SPEC → Fine combo).
const Duration kComboFadeDuration = Duration(milliseconds: 450);

/// Durata della salita di un timbro di Ciommo.
const Duration kComboStampDuration = Duration(milliseconds: 260);

/// Durata della discesa con cui il timbro esce di scena.
const Duration kComboStampExitDuration = Duration(milliseconds: 320);

/// Quanto aspetta `ComboOverlay`, dopo che la combo finisce, prima di
/// smontarsi del tutto (torna a `SizedBox.shrink()`). Deve coprire sia la
/// dissolvenza di bagliore/testo ([kComboFadeDuration]) sia l'uscita dei
/// timbri ([kComboStampExitDuration]), con un margine: se fosse uguale al
/// piu' lento dei due, lo smontaggio rischierebbe di tagliarlo a meta'.
const Duration kComboDismissDelay = Duration(milliseconds: 600);

/// Altezza di un timbro "Ciommo Approved". Grosso di proposito: è la firma
/// della combo, si deve vedere dall'altra parte del bancone.
const double kComboStampHeight = 288;

/// Proporzioni dell'asset del timbro (924×1316 px).
///
/// Lo slot del timbro si dimensiona da qui invece di lasciarlo dedurre
/// all'immagine: così il layout è identico prima e dopo che il PNG si è
/// decodificato, e resta sano anche se l'asset non si carica affatto — un
/// figlio a larghezza zero manderebbe in NaN la scala del `FittedBox` che lo
/// contiene.
const double kComboStampAspect = 924 / 1316;

/// Larghezza dello slot di un timbro, derivata dalle sue proporzioni.
const double kComboStampWidth = kComboStampHeight * kComboStampAspect;

/// Quanto resta sollevato dal bordo basso, per non finire sulla bandierina.
const double kComboStampBottom = kDutchFlagHeight + 6;

/// Distanza dal bordo alto del blocco combo (moltiplicatore + testo), che in
/// alto al centro ci sta di casa.
const double kTopOverlayTop = 40;

// ---------------------------------------------------------------------------
// Combo — pioggia di bicchierini
// ---------------------------------------------------------------------------
// Sullo sfondo, dietro a moltiplicatore/testo e timbri Ciommo: sono loro
// l'evento, la pioggia è l'atmosfera attorno. Per questo restano pochi e mai
// a piena opacità — ma devono vedersi, non essere puntini.

/// Quanti bicchierini cadono in loop finché la combo resta viva.
const int kComboRainDropCount = 6;

/// Quanto impiega un bicchierino ad attraversare tutto lo schermo, dall'alto
/// in basso, prima di ricominciare dall'alto.
const Duration kComboRainCycleDuration = Duration(milliseconds: 2600);

/// Altezza di un bicchierino della pioggia. Triplicata rispetto ai 34
/// iniziali: da dietro il bancone non si vedevano proprio.
const double kComboRainDropSize = 102;

/// Trasparenza dei bicchierini della pioggia. Restano dietro ai timbri di
/// Ciommo, che sono l'evento vero della combo lunga.
const double kComboRainOpacity = 0.30;

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
// Marchio House of Mad Dogs
// ---------------------------------------------------------------------------

/// Altezza del solo bicchiere, dentro al marchio fisso in fondo alla
/// schermata (`HomdBrandMark`: bicchiere + "HOUSE OF MAD DOGS" + tagline,
/// come nel sottobicchiere ufficiale).
///
/// Raddoppiata rispetto ai 64 iniziali: il marchio era corretto ma si
/// leggeva appena da dietro il bancone.
const double kHomdMarkSize = 128;

/// Quanto sta sollevato dal bordo basso l'intero marchio (bicchiere, testo e
/// tagline insieme): sopra la bandierina, non a filo.
const double kHomdMarkBottom = kDutchFlagHeight + 8;

/// Spazio tra il bicchiere e "HOUSE OF MAD DOGS".
const double kHomdWordmarkGap = 4;

/// Corpo di "HOUSE OF MAD DOGS" sotto al bicchiere.
const double kHomdWordmarkSize = 30;

/// Spaziatura tra le lettere del wordmark, come nel sottobicchiere.
const double kHomdWordmarkTracking = 2;

/// Spazio tra "HOUSE OF MAD DOGS" e la tagline.
const double kHomdTaglineGap = 6;

/// Corpo della tagline "MAY CAUSE UNFORGETTABLE NIGHTS", più piccolo del
/// wordmark come nel sottobicchiere ufficiale.
const double kHomdTaglineSize = 15;

/// Spaziatura tra le lettere della tagline.
const double kHomdTaglineTracking = 1.2;

/// Quanta altezza dello schermo può occupare al massimo il marchio completo.
///
/// Sotto al numerone resta libero `(1 - kBigNumberHeightFraction) / 2` di
/// altezza, cioè 0,275: questo tetto sta sotto quella soglia col margine di
/// `kHomdMarkBottom`. Sul tablet di produzione non morde mai — il marchio a
/// grandezza piena ci sta comodo — ma su uno schermo basso lo rimpicciolisce
/// invece di lasciarlo salire fin sul numerone.
const double kHomdMarkMaxHeightFraction = 0.24;

/// Frazione della larghezza schermo riservata al marchio nella fila dei
/// timbri di Ciommo, che gli escono ai due lati senza mai passarci sopra.
///
/// È una frazione e non una misura fissa perché la stessa corsia governa
/// due cose che devono restare d'accordo: il marchio non la supera mai (si
/// rimpicciolisce se serve) e i timbri hanno sempre tutto il resto dello
/// schermo. Così su nessuna larghezza uno mangia lo spazio dell'altro.
/// Sul tablet di produzione la corsia è larga a sufficienza perché il
/// marchio ci stia a grandezza piena.
///
/// **La corsia vive fuori dal `FittedBox` che rimpicciolisce i timbri**: se
/// stesse dentro si rimpicciolirebbe con loro, e i timbri finirebbero
/// addosso al marchio.
const double kHomdMarkLaneFraction = 0.30;

/// Respiro tra il marchio e i timbri che gli passano ai lati.
const double kHomdMarkLaneMargin = 20;

// ---------------------------------------------------------------------------
// Numerone
// ---------------------------------------------------------------------------

/// Quante cifre mostra sempre il contatore, zeri davanti compresi: il
/// numerone del pub è un tabellone, non un numero che cresce (`000000`,
/// `000001`, …). Oltre questa larghezza il numero continua a crescere e basta.
const int kCounterDigits = 6;

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

/// Lato del quadrato in cui sta la faccina. Cresciuta del 15% rispetto ai
/// 320 iniziali: da dietro il bancone era piccolina.
const double kIdleFaceSize = 368;

/// Quanto scende dal bordo alto: la faccina sta in cima, nella stessa fascia
/// dei contatori della combo, non piantata in mezzo al numerone.
const double kIdleFaceTop = kTopOverlayTop;

/// Durata di un ciclo di respiro: sale, sospira, scende. Lento di proposito.
const Duration kIdleBreathDuration = Duration(milliseconds: 3600);

/// L'ambra della faccina. È l'oro celebrativo della palette: l'arancio del
/// riferimento non è un colore di brand, questo sì e gli somiglia.
const Color kIdleFaceColor = kCelebrationGold;

/// L'azzurro della lacrima. Il blu di brand pieno, su fondo scuro, spariva:
/// questo è lo stesso blu schiarito, resta di famiglia ma si vede.
const Color kIdleTearBlue = Color(0xFF7FB2FF);

/// Raggio della lacrima, in frazione dell'occhio. Raddoppiato: prima era una
/// puntina e il dispiacere non si leggeva.
const double kIdleTearRadiusFactor = 0.40;

/// Il riflesso pallido in fondo agli occhioni. Bianco sporco, mai puro.
const Color kIdleEyeSheen = kTextColor;

// ---------------------------------------------------------------------------
// Idle — le nuvole
// ---------------------------------------------------------------------------

/// Quante nuvole attraversano lo schermo durante l'idle.
const int kIdleCloudsCount = 3;

/// Quanto impiega una nuvola ad attraversare tutto lo schermo, in loop.
/// Lenta come il respiro della faccina: è atmosfera, non un evento.
const Duration kIdleCloudsCrossDuration = Duration(seconds: 14);

/// Larghezza della nuvola più grande; le altre sono via via più piccole
/// (profondità povera, ma basta a non farle sembrare un fila identica).
const double kIdleCloudsSize = 140;

/// Trasparenza delle nuvole: sono sfondo, dietro la faccina.
const double kIdleCloudsOpacity = 0.18;

/// Quanto stanno in alto: sopra la fascia della faccina, mai addosso a lei.
const double kIdleCloudsTop = 8;

// ---------------------------------------------------------------------------
// Backup giornaliero
// ---------------------------------------------------------------------------

/// Quanti file di backup tenere. Oltre, i più vecchi si cancellano.
const int kBackupRetentionDays = 7;

/// Chiave shared_preferences dell'ultimo giorno di cui esiste un backup,
/// in formato `YYYYMMDD`.
const String kPrefsLastBackupDay = 'last_backup_day';

/// Sottocartella dei backup nella storage esterna dell'app.
const String kBackupDirName = 'backups';

// ---------------------------------------------------------------------------
// Splash
// ---------------------------------------------------------------------------

/// Quanto resta pieno il logo prima di iniziare a svanire.
///
/// Il contatore sotto è già vivo e già tappabile: questo tempo non ritarda
/// nulla, decide solo quanto si vede il brand (FUNCTIONAL_SPEC → Avvio).
const Duration kSplashHold = Duration(milliseconds: 900);

/// Durata della dissolvenza del logo.
const Duration kSplashFade = Duration(milliseconds: 500);

/// Testi del logo House of Mad Dogs, come sul sottobicchiere ufficiale.
const String kBrandPub = 'THE DUTCH PUB · GAETA';
const String kBrandNameLine1 = 'HOUSE OF';
const String kBrandNameLine2 = 'MAD DOGS';
const String kBrandTagline = 'MAY CAUSE UNFORGETTABLE NIGHTS';
