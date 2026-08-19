# Mad Dog Counter — Animazioni & Easter Egg

L'anima dell'app. Ogni evento ha: **trigger**, **effetto**, **durata indicativa**, **suono**. Le durate sono da tarare a mano sul tablet vero.

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
- **Combo lunga** (soglia da tarare, es. ≥ 5): timbri **"Ciommo Approved"** (asset `design/processed/ciommo_approved.svg`, fill bianco sporco; variante badge: `ciommo_sticker_round.png`) che spuntano dai lati del display con effetto stamp (schiaffo di timbro + leggera rotazione random). Più la combo cresce, più Ciommo appare.
  - Variante segnata da valutare coi baristi: Ciommo compare quando i cicchetti della sessione superano 3.
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
- **Regola di assorbimento**: ogni multiplo di 1000 è anche multiplo di 100, ma i due effetti NON si accodano — lo strike **sostituisce** i fuochi. In generale: quando un trigger è un sovrainsieme di un altro, scatta solo l'evento più raro. La regola della coda (ordinamento per durata) vale solo per eventi *indipendenti* che scattano sullo stesso tap.

### 5. Finisce per 67
- **Trigger**: dopo un incremento, le ultime due cifre del totale sono `67`. Una sola volta per arrivo: restando fermi sul ...67 non si ripete. (Per la regola 0, arrivare a ...67 scendendo con un −1 non fa scattare nulla.)
- **Effetto**: il numerone **trema/traballa a destra e sinistra** (shake orizzontale, stile brivido) per ~1,5 s.
- **Suono**: wobble breve.

### 6. Otto adiacenti → tette (persistente)
- **Trigger**: dopo un incremento, il totale contiene **due `8` consecutivi** (es. 239**88**1). Per la regola 0 lo stato si *attiva* solo salendo; un decremento può però *romperlo* (le cifre tornano normali) o al massimo mantenerlo se la coppia resta intatta — mai crearlo.
- **Effetto**: le coppie di 8 adiacenti si **trasformano in due tette** e **rimangono così** finché gli 8 restano adiacenti nel numero. Quando il numero cambia e la coppia si rompe, le cifre tornano normali (con una piccola transizione morph, non uno stacco secco).
- Casi da gestire: `888` → una coppia trasformata + un 8 normale (scegliere: le prime due cifre della sequenza); più coppie disgiunte nel numero → tutte trasformate.
- **Suono**: "boing" solo al momento della trasformazione, non continuo.
- Grafica: due tette stilizzate coerenti col brand (rosso 186C su fondo scuro), in stile buffo da cartoon — è un pub, non un sito porno. Asset da produrre.

### 7. Idle — la faccina annoiata
- **Trigger**: nessun tap da N minuti (default suggerito: 10 min, costante in config).
- **Effetto**: compare la **faccina gialla triste con gli occhioni lucidi** (asset di riferimento: `design/raw/idle_faccina_riferimento.jpg`, da rielaborare in stile coerente) che guarda il contatore, sospira, magari bussa sul vetro dello schermo. Loop dolce finché non arriva un tap.
- **Al tap dopo l'idle**: la faccina esplode di gioia e sparisce (micro-animazione di ~1 s), poi tutto normale.
- **Suono**: nessuno durante l'idle (non deve disturbare il pub nei momenti calmi); giubilo al risveglio.

## Priorità di implementazione

1. Tap base + persistenza (senza questo non esiste il prodotto)
2. Combo (l'effetto usato più spesso in assoluto)
3. Multiplo di 100 e 1000
4. Finisce per 67 + otto adiacenti
5. Idle + Ciommo Approved

## Idee parcheggiate (backlog, non implementare ora)

- Pioggia di Mad Dog ai grandi traguardi (10.000? 250.000?)
- Testi combo personalizzati/dialettali proposti dai baristi
- Modalità festa per serate speciali
