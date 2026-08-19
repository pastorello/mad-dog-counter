# CLAUDE.md — Mad Dog Counter

Istruzioni operative per Claude Code su questo progetto. Leggere prima i documenti in `docs/` (PROJECT_BRIEF → ARCHITECTURE → FUNCTIONAL_SPEC → ANIMATIONS_SPEC → UX_UI_SPEC) e la mappa degli asset grafici in `design/README.md`.

## Regole d'oro

1. **Mai perdere il conteggio.** Il totale e ogni tap sono sacri. Ogni modifica al layer dati (scrittura del totale, log, migrazione, backup) richiede test prima del merge.
2. **Il conteggio non si blocca mai.** Nessuna animazione, errore di rete o effetto può impedire o ritardare un tap. Gli effetti sono sempre fire-and-forget rispetto al conteggio.
3. **Logica trigger pura e testata.** Tutte le condizioni easter egg (multipli, "finisce per 67", "8 adiacenti", stato combo) vivono in funzioni Dart pure, senza dipendenze da storage o widget, coperte da unit test. Regola madre: gli effetti scattano SOLO su incremento, mai su decremento (ANIMATIONS_SPEC → regola 0).
4. **Costanti in `config.dart`**, mai sparse nel codice: `INITIAL_COUNT` (0), finestra combo (2 s), soglie combo, durate animazioni, testi celebrativi, durata pressione lunga impostazioni (3 s). I valori regolabili dall'utente (audio on/off, minuti di idle) vivono invece in shared_preferences coi loro default.
5. **Un effetto = un modulo.** Ogni easter egg è un widget/controller autonomo registrato nel catalogo effetti. Aggiungere un effetto nuovo non deve toccare quelli esistenti.

## Tooling agenti

I plugin di Claude Code sono installati **globalmente** e accesi **per progetto**: `.claude/settings.json` (versionato) dice quali servono qui. Oggi: `agent-skills` acceso, `impeccable` spento — è una raccolta di design per il web e questo è un progetto Flutter con una palette già chiusa in UX_UI_SPEC. Non reinstallare le skill dentro al repo: ci starebbero due volte.

## Stack vincolato

- Flutter (ultima stable) + Dart, **Riverpod** per lo stato. Persistenza **locale**: shared_preferences (totale) + sqflite (log tap), dietro l'interfaccia `CounterRepository` (vedi ARCHITECTURE.md). Non introdurre Bloc, GetX, né backend online: la persistenza remota è fase 2 e arriverà come nuova implementazione del repository.
- Landscape bloccato, wakelock attivo, Android only.
- Device di produzione: Samsung Galaxy Tab A8 (SM-X200), Android 14 / API 34. Flutter ultima stable, `minSdkVersion 24` (vedi ARCHITECTURE.md → Target).

## Convenzioni di codice

- Dart standard: `dart format`, `flutter analyze` puliti prima di ogni commit.
- Nomi in inglese nel codice; i commenti possono essere in italiano.
- Niente numeri magici, niente stringhe UI hardcodate fuori da config.
- Commit piccoli e tematici (un effetto/una feature per commit).

## Testing

- Unit test obbligatori per: trigger easter egg, macchina a stati combo, ordinamento coda effetti (durata crescente), regola "il multiplo di 1000 assorbe il multiplo di 100", clamp a zero del contatore.
- Widget test per la schermata contatore (zone tap, roll delle cifre).
- Test manuali sul tablet vero per performance animazioni e audio.

## Cosa NON fare

- Non implementare la fase 2 (persistenza online, statistiche, sito pubblico): solo predisporre il log tap locale e l'interfaccia repository.
- Non aggiungere autenticazione utente né schermate extra oltre al pannello impostazioni specificato in FUNCTIONAL_SPEC (e non estendere il pannello oltre le voci MVP elencate lì).
- Non usare bianco puro né rosa nella UI (vedi UX_UI_SPEC → palette).
- Non chiedere conferma per il decremento: è un tap semplice per scelta di prodotto.

## Domande aperte (chiedere al committente quando bloccanti)

- Soglia esatta combo per far comparire Ciommo. **Implementata col valore provvisorio `kComboCiommoThreshold = 5`**: è un numero in `config.dart`, cambiarlo non tocca il codice. La variante alternativa ("più di 3 cicchetti in sessione") richiederebbe invece un contatore di sessione, che oggi non esiste.
- Testi celebrativi delle combo (lista dai baristi). Provvisori in `kComboTexts`, uno per soglia di `kComboThresholds`: un test verifica che le due liste restino della stessa lunghezza.
- Minuti esatti di idle prima della faccina annoiata (default 10).

## Decisioni prese

- **`INITIAL_COUNT = 0`.** L'app parte da zero; il valore del vecchio counter si imposta a mano dal pannello impostazioni il giorno dell'installazione. Nessuna costante storica cablata nel codice (vedi FUNCTIONAL_SPEC → Migrazione).
- **Suoni**: consegnati. Set completo di prima versione in `assets/sounds/`: 10 WAV mono 44.1 kHz 16-bit sintetizzati proceduralmente in stile arcade, senza campioni di terze parti e senza licenze da gestire. Mappa evento→file in `assets/sounds/README.md`, costanti `kSfx*` in `config.dart`. **I nomi dei file sono il contratto col codice**: per cambiare un suono si sostituisce il WAV mantenendo il nome, mai il contrario. Integrarli così come sono; sostituirli è una decisione del committente dopo averli sentiti nel pub. Non cercare né generare altri SFX in autonomia.
- **Il `SoundManager` deve tollerare l'assenza di un file.** Un asset mancante o un errore di riproduzione non deve mai essere un'eccezione che risale, né ritardare un tap (regola d'oro 2). L'audio è fire-and-forget come tutto il resto del layer effetti.
- **Vettoriali di brand**: la tipografia non li fornirà. Vanno ridisegnati internamente a partire dai raster in `design/raw/` (logo House of Mad Dogs per primo). Gli SVG già ricavati stanno in `design/processed/`.
