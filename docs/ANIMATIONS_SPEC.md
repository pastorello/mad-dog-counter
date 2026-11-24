# Mad Dog Counter — Animazioni & Easter Egg

L'anima dell'app. Ogni evento ha: **trigger**, **effetto**, **durata indicativa**, **suono**. Le durate sono da tarare a mano sul tablet vero.

I suoni citati qui sotto esistono già come file: mappa evento→WAV in `assets/sounds/README.md`, costanti `kSfx*` in `lib/config.dart`.

## Regole del motore effetti

0. **REGOLA MADRE — solo su incremento**: nessuna animazione, easter egg o effetto celebrativo scatta MAI su un decremento. Il −1 produce solo il suo feedback base (pulsazione inversa blu + suono) e può *rimuovere* stati attivi (azzera la combo; se rompe una coppia di 8, le cifre tornano normali), mai attivarne. Tutte le condizioni trigger si valutano esclusivamente dopo un +1.
1. **Coda, non sovrapposizione**: se più eventi scattano sullo stesso tap (es. 239400 è multiplo di 100 e finisce la combo), gli effetti si **accodano in ordine di durata crescente** — prima i corti, per ultimo l'evento più epico che chiude in bellezza.
2. Il **feedback base del tap** (pulsazione + suono) non va mai in coda: è istantaneo e si somma a tutto.
3. Gli effetti **persistenti** (8 adiacenti → tette) non entrano in coda: sono uno stato del display, attivo finché la condizione è vera.
4. Durante un effetto in corso i tap **continuano a contare normalmente** — mai bloccare il conteggio per un'animazione.
5. Ogni effetto è un modulo autonomo (widget/controller dedicato) registrato in un catalogo, per aggiungerne di nuovi facilmente: i baristi produrranno altre idee, garantito.
6. **Kill switch**: il pulsante panico (vedi FUNCTIONAL_SPEC.md) svuota la coda, ferma animazioni e suoni, azzera combo e stati persistenti, mascherando tutto con un'esplosione di ~1 s. Ha priorità assoluta su qualsiasi effetto in corso. Il motore effetti deve esporre un metodo `killAll()` chiamabile in ogni istante.

## Catalogo effetti

### 1. Tap base (sempre)
- **Trigger**: ogni incremento.
- **Effetto**: il numerone pulsa (scale up→down, ~150 ms), scintille leggere attorno al numero, vibrazione breve.
- **Suono**: "pop"/clack corto.
- **Decremento**: pulsazione inversa con tinta blu (Pantone 2728C), suono più basso/triste.

### 2. Combo Candy Crush
- **Trigger**: tap di *incremento* consecutivi con **massimo 2 secondi** tra l'uno e l'altro. La combo si azzera se passano più di 2 s **oppure se arriva un decremento** (il −1 interrompe subito la combo, senza effetti celebrativi).
- **Effetto**: moltiplicatore visivo che sale (x2, x3, x5...), scritte celebrative sempre più esaltate che appaiono a schermo (es. «Bello!», «Fantastico!», «LEGGENDARIO!» — testi da definire coi baristi, tenerli in una lista in `config.dart`), l'ambiente attorno al numero si scalda: glow crescente, particelle più fitte.
- **Timbro Ciommo (v2, lo slam)**: a ogni **multiplo dell'intervallo** di tap di combo (5, 10, 15… col default; regolabile dal pannello, voce «Timbro Ciommo ogni N») UN timbro **"Ciommo Approved" gigante** piomba sul numerone: 85% dell'altezza, inclinato −14°, slam-in ~12% / hold / fade su 2,0 s (DECISIONS → 02). Copre il numerone un attimo — è la battuta, non un bug — e sotto si continua a contare (`IgnorePointer`). Suona il ta-daa (`combo_milestone.wav`) a ogni timbro; quando il multiplo coincide con una soglia dei testi, il ta-daa suona UNA volta. Non entra nella coda effetti: è un fatto della combo, in coda arriverebbe in ritardo.
- **Pioggia di bicchierini** (`lib/ui/effects/combo_rain.dart`): sullo sfondo, dietro a moltiplicatore/testo e ai timbri Ciommo, alcuni bicchierini piccoli e trasparenti (`ShotGlassPainter`, lo stesso disegno del marchio HoMD) cadono in loop finché la combo resta viva. È atmosfera, non l'evento: piccola, poca opacità, non compete coi timbri.
- **Suono**: pitch dei pop che sale con la combo; "voce"/effetto trionfale sulle soglie.
- **Fine combo**: gli effetti sfumano dolcemente, il moltiplicatore scompare.

### 3. Multiplo di 100
- **Trigger**: `total % 100 == 0`.
- **Effetto**: **fuochi d'artificio a tutto schermo** (pacchetto `confetti` o particelle custom), il numero brilla dorato per qualche secondo.
- **Durata**: ~3–4 s.
- **Suono**: fuochi d'artificio.

### 4. Multiplo di 1000 — Strike!
- **Trigger**: `total % 1000 == 0`.
- **Effetto**: una **palla da bowling** entra da un lato dello schermo, colpisce il numerone e **spacca le cifre per aria** come birilli (le cifre volano con fisica esagerata, rimbalzano, poi il contatore si ricompone tremolando).
- **Durata**: ~5–6 s.
- **Suono**: rotolamento + strike fragoroso + campanella.
- **Regola di assorbimento (generalizzata nella v2)**: la catena delle milestone è `100.000 → 10.000 → 1000 → 100` e **vince il più raro**: ogni milestone più grande è multiplo delle più piccole, quindi sullo stesso tap scatta solo lei (l'apoteosi assorbe tutto, la pioggia assorbe strike e fuochi, lo strike assorbe i fuochi). La regola della coda (ordinamento per durata) vale solo per eventi *indipendenti* che scattano sullo stesso tap (il 67, il record del giorno).

### 4b. Multiplo di 10.000 — Pioggia di Mad Dog (v2)

- **Trigger**: `total % 10000 == 0` (e non multiplo di 100.000). Assorbe strike e fuochi.
- **Effetto**: pioggia FITTA di bicchierini shot rossi a piena opacità (riuso di `ShotGlassPainter`, 20 bicchierini da 100–140 px a velocità diverse) — non l'atmosfera della `ComboRain`, l'evento vero — con le cifre dorate (`gildDigit`); sul finale (~78%) tutti i bicchierini virano in **oro**.
- **Durata**: ~7 s.
- **Suono**: fuochi, con la **campanella dello strike** sul finale. Nessun WAV nuovo.
- Era nel backlog («Pioggia di Mad Dog ai grandi traguardi»): promossa e approvata nei mockup (DECISIONS → 03).

### 4c. Multiplo di 100.000 — Apoteosi (v2)

- **Trigger**: `total % 100000 == 0`. Assorbe tutta la catena. Il momento più raro e più epico di tutti.
- **Effetto**: tre mega-salve di coriandoli nei colori della bandierina più l'oro (angoli bassi verso il centro + una dritta in alto), bagliore dorato che cresce, scritta **APOTEOSI** in oro (144 px, font display), cifre che volano come nello strike (`scatterDigit`), e sul ~75% il **lampo del botto** (radiale oro/ink, mai bianco puro).
- **Durata**: ~9 s.
- **Suono**: fuochi, con l'**esplosione del panico** come apice. Nessun WAV nuovo.

### 5. Finisce per 67
- **Trigger**: dopo un incremento, le ultime due cifre del totale sono `67`. Una sola volta per arrivo: restando fermi sul ...67 non si ripete. (Per la regola 0, arrivare a ...67 scendendo con un −1 non fa scattare nulla.)
- **Effetto**: il numerone **trema/traballa a destra e sinistra** (shake orizzontale, stile brivido) per ~1,5 s.
- **Suono**: wobble breve.

### 6. Otto adiacenti → tette (persistente)
- **Trigger**: dopo un incremento, il totale contiene **due `8` consecutivi** (es. 239**88**1). Per la regola 0 lo stato si *attiva* solo salendo; un decremento può però *romperlo* (le cifre tornano normali) o al massimo mantenerlo se la coppia resta intatta — mai crearlo.
- **Effetto**: le coppie di 8 adiacenti si **trasformano in due tette** e **rimangono così** finché gli 8 restano adiacenti nel numero. Quando il numero cambia e la coppia si rompe, le cifre tornano normali (con una piccola transizione morph, non uno stacco secco).
- Casi da gestire: `888` → una coppia trasformata + un 8 normale (scegliere: le prime due cifre della sequenza); più coppie disgiunte nel numero → tutte trasformate.
- **Suono**: "boing" solo al momento della trasformazione, non continuo.
- Grafica: due tette stilizzate in stile buffo da cartoon — è un pub, non un sito porno. **Rosa carne** (`kFleshPink`), unica deroga al divieto di rosa della palette: in rosso 186C la battuta non si leggeva (vedi UX_UI_SPEC → Palette).
- Insieme alla trasformazione parte una salva di **cuoricini** che esplode attorno alle cifre e ricade con la gravità (`lib/ui/effects/hearts_burst.dart`).

### 8. NUOVO RECORD! (v2)

- **Trigger**: con un incremento il giornaliero supera il record storico (mezzogiorno→mezzogiorno, vedi FUNCTIONAL_SPEC → Record del giorno). Una volta sola per finestra; il primissimo mad dog del primissimo giorno conta già.
- **Effetto**: scritta «NUOVO RECORD!» in oro nella fascia alta, alone caldo oro/rosso attorno al numerone, cifre indorate (riuso del `gildDigit` dei fuochi).
- **Durata**: ~4 s. In coda come gli altri effetti (peso 4000: tra fuochi e strike); NON partecipa all'assorbimento dei multipli — è un evento indipendente come il 67.
- **Suono**: riuso del giubilo `wake_jubilation.wav` (nessun WAV nuovo).

### 9. TILT (v2, stato persistente)

- **Trigger**: più di `tilt_threshold` incrementi (default 100, dal pannello) nella finestra mobile di 2 ore. La finestra si ricarica dal log all'avvio.
- **Effetto**: scena a tutto schermo — velo scuro (0,72) sfocato (blur 6), scritta TILT ~600 px rossa che vibra, messaggio personalizzabile (60 px, Oswald), barra rossa che si svuota nella durata. **È un `IgnorePointer`**: i tap la attraversano e contano (regola 4, regola d'oro 2). Panico e ingranaggio restano sopra la scena.
- **Durata**: `tilt_duration_seconds` (default 60 s, dal pannello). All'uscita la finestra di osservazione si svuota, altrimenti il tap successivo lo riaccenderebbe.
- **Stato persistente** (regola 3), non in coda: convive con combo ed effetti. Il `killAll()` (panico o apertura impostazioni) lo spegne e svuota la finestra; i DATI del record del giorno invece non vengono toccati dal kill.
- **Suono**: riuso del wobble `wobble_67.wav` all'ingresso; la scena in sé è muta.

### 7. Idle — la faccina annoiata
- **Trigger**: nessun tap da N minuti (default suggerito: 10 min, costante in config).
- **Posizione**: in alto al centro, nella stessa fascia dei contatori della combo (non in mezzo al numerone).
- **Effetto**: compare la **faccina gialla triste con gli occhioni lucidi** (asset di riferimento: `design/raw/idle_faccina_riferimento.jpg`, da rielaborare in stile coerente) che guarda il contatore, sospira, magari bussa sul vetro dello schermo. Loop dolce finché non arriva un tap.
- **Nuvole** (`lib/ui/effects/idle_clouds.dart`): dietro alla faccina, tre nuvole disegnate (nessun asset) attraversano lo schermo in loop, lente come il suo respiro. Vivono e muoiono con lei, ma spariscono un istante prima: al tap il cielo si schiarisce subito, mentre la faccina è ancora in scena a esplodere di gioia.
- **Al tap dopo l'idle**: la faccina esplode di gioia e sparisce (micro-animazione di ~1 s), poi tutto normale.
- **Suono**: nessuno durante l'idle (non deve disturbare il pub nei momenti calmi); giubilo al risveglio.

## Priorità di implementazione

1. Tap base + persistenza (senza questo non esiste il prodotto)
2. Combo (l'effetto usato più spesso in assoluto)
3. Multiplo di 100 e 1000
4. Finisce per 67 + otto adiacenti
5. Idle + Ciommo Approved

## Idee parcheggiate (backlog, non implementare ora)

- ~~Pioggia di Mad Dog ai grandi traguardi~~ → promossa: è la milestone dei 10.000 (v2, §4b)
- Testi combo personalizzati/dialettali proposti dai baristi
- Modalità festa per serate speciali
