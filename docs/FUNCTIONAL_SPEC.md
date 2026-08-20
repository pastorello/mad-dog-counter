# Mad Dog Counter — Specifica funzionale

## Schermata unica

L'app è una sola schermata, landscape, sempre accesa (wakelock). Nessuna navigazione, nessun menu visibile.

## Interazioni base

| Gesto | Zona | Effetto |
|---|---|---|
| Tap | Zona destra + centrale (≈ 75% dello schermo) | **+1** al contatore |
| Tap | Zona sinistra (≈ 25% dello schermo) | **−1** al contatore (correzione errori) |
| Tap | **Pulsante panico** (angolo alto destro) | **Kill switch effetti** (vedi sotto). NON tocca il contatore. |
| **Pressione lunga (2 s)** | **Ingranaggio impostazioni** (angolo basso destro) | Apre il pannello impostazioni (vedi sotto). Il tap semplice non fa nulla. |

- Il decremento è un **tap semplice, senza conferma** (decisione esplicita del committente: ambiente informale, la semplicità vince).
- Le due zone devono essere enormi e a prova di mira ubriaca. Feedback visivo immediato su ogni tap (il numerone pulsa) + feedback aptico (vibrazione breve) se il tablet lo supporta + suono.
- Il decremento ha un feedback visivamente distinto (es. pulsazione "in giù", tinta blu) per far capire che si è tolto, non aggiunto. **Il decremento non attiva MAI animazioni/easter egg** (vedi ANIMATIONS_SPEC.md → regola 0).
- Il contatore non scende mai sotto 0.
- Il totale si mostra sempre su **sei cifre** con gli zeri davanti (`kCounterDigits`): sotto lo zero riempitivo il numero vero resta leggibile e il tabellone non balla.
- Anti-doppio-conteggio: debounce di ~80 ms sui tap per evitare doppi tocchi hardware, ma senza penalizzare il tapping veloce delle combo (vedi ANIMATIONS_SPEC.md → Combo).

## Pulsante panico (kill switch effetti)

Con tante animazioni concatenabili serve un freno d'emergenza utilizzabile in tempo reale dai baristi:

- **Posizione**: angolo alto destro, piccolo e discreto, con padding generoso che lo isola dalla zona +1 (non deve essere premuto per sbaglio, né rubare tap al contatore).
- **Comportamento**: al tap, parte una **esplosione a tutto schermo (~1 s)** che copre visivamente qualsiasi cosa stia succedendo; sotto la maschera vengono **svuotata la coda effetti, fermate tutte le animazioni in corso, fermati tutti i suoni, azzerata la combo e resettati gli stati persistenti** (es. tette). Quando l'esplosione svanisce, resta la schermata pulita col numerone.
- **Il contatore non viene toccato**: il kill switch agisce solo sul layer effetti.
- Deve funzionare **sempre**, anche nel mezzo dell'animazione più pesante: priorità assoluta, nessuna coda.

## Pannello impostazioni

Accessibile SOLO con pressione lunga di 2 secondi sull'icona ingranaggio (angolo basso destro, piccola, opacità ridotta): il tap semplice è ignorato, per essere a prova di dita ubriache. Si apre come overlay sopra la schermata; mentre è aperto i tap sul contatore sono disabilitati e gli effetti in corso vengono fermati (equivalente a un `killAll()` silenzioso, senza esplosione).

Contenuto MVP, volutamente minimale:

- **Imposta contatore**: campo numerico per scrivere a mano il valore del totale (es. per la migrazione iniziale o per correzioni grosse). Richiede conferma esplicita mostrando "vecchio → nuovo". La modifica viene registrata nel log come record di tipo `adjust` con il delta risultante, così lo storico resta coerente.
- **Audio**: interruttore on/off degli effetti sonori.
- **Minuti di idle**: dopo quanti minuti di inattività parte la faccina annoiata (default 10).
- **Chiudi**: unico modo per uscire; nessun altro elemento di navigazione.

Il pannello è pensato per crescere (fase 2: statistiche, export backup, gestione sync), ma nell'MVP non deve contenere altro.

## Persistenza (MVP: locale)

- Il totale vive in **shared_preferences**, scritto a ogni tap (vedi ARCHITECTURE.md).
- Ogni tap scrive anche un record `(timestamp, ±1)` nel log locale sqflite, fire-and-forget.
- Nessuna rete richiesta: l'app è completamente autonoma. Nessun indicatore di connessione.
- Backup giornaliero minimo su file (ultimi 7 giorni), vedi ARCHITECTURE.md → Rischio noto.

## Migrazione

- Primo avvio: se `counter_total` non esiste, inizializzarlo a **`INITIAL_COUNT = 0`**.
- **Subentro manuale.** Il valore del vecchio counter non viene cablato nel codice: il giorno dell'installazione si legge il numero sul tablet vecchio e lo si scrive dal pannello impostazioni → "Imposta contatore". La modifica entra nel log come record `type='adjust'`.
- Motivo: il vecchio counter resta in servizio fino allo switch e continua a salire, quindi una costante fissata oggi sarebbe già superata domani.
- Da qui in avanti il totale rappresenta la storia del pub: perderlo è il peggior bug possibile del progetto.

## Avvio

1. Splash minimale a tema (logo House of Mad Dogs su fondo scuro).
2. Lettura del totale da storage → mostra il numerone.
3. Pronto a contare in < 2 secondi dall'apertura.

## Suoni

- Audio **a tutto volume**: ogni tap ha un suono corto; gli easter egg hanno suoni dedicati (specifiche in ANIMATIONS_SPEC.md).
- Volume gestito dal sistema del tablet; l'app non abbassa mai l'audio da sola.

## Stati speciali

- **Inattività**: dopo un periodo senza tap parte l'animazione "faccina annoiata" (vedi ANIMATIONS_SPEC.md → Idle).
- **Errore di scrittura storage**: ritentare, loggare, mai bloccare l'UI né perdere il valore in memoria.

## Fase 2 (fuori scope, ma predisposta)

- **Persistenza online** (Firebase o simili) tramite una nuova implementazione di `CounterRepository`, con migrazione del totale e del log tap locali.
- Statistiche: conteggio "di stasera", record di cicchetti in una singola serata, ora di punta, grafici settimanali.
- Sito/pagina pubblica di consultazione del contatore.
- Il log locale dei tap con timestamp raccoglie i dati necessari **da subito**, così la fase 2 avrà storico retroattivo.
