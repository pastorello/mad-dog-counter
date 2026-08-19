# Mad Dog Counter

App Android (Flutter) per il contatore dei cicchetti **Mad Dog** del pub **The Dutch** di Gaeta — brand del cicchetto **House of Mad Dogs**.

Sostituisce il vecchio counter del tablet a muro. Non è un gestionale: è un piccolo show da bancone, con animazioni, easter egg, combo e suoni.

Il contatore **parte da zero** (`INITIAL_COUNT = 0`): il valore storico del vecchio counter si imposta a mano dal pannello impostazioni al momento dell'installazione nel locale.

- **Device di produzione**: Samsung Galaxy Tab A8 (SM-X200), Android 14 / API 34, landscape bloccato, schermo sempre acceso.
- **Stack**: Flutter + Dart, Riverpod, persistenza locale (`shared_preferences` per il totale + `sqflite` per il log tap) dietro l'interfaccia `CounterRepository`.
- **Stato**: fase di specifica. Il codice Flutter non è ancora stato generato.

## Struttura del repo

```
CLAUDE.md      istruzioni operative per gli agenti AI (regole d'oro, stack vincolato, testing)
README.md      questo file
docs/          le specifiche di progetto (vedi docs/README.md per l'ordine di lettura)
design/        materiale di brand: raw/ (sorgenti), processed/ (asset pronti), fonts/
```

`design/` è **materiale sorgente** e non va mai referenziato dal codice: gli asset usati dall'app vanno esportati e ottimizzati in `assets/` del progetto Flutter.

## Da dove partire

1. Leggere [docs/PROJECT_BRIEF.md](docs/PROJECT_BRIEF.md), poi il resto nell'ordine indicato in [docs/README.md](docs/README.md).
2. Leggere [CLAUDE.md](CLAUDE.md) prima di toccare il codice: contiene le regole non negoziabili (mai perdere il conteggio, il conteggio non si blocca mai, costanti in `config.dart`).
3. La mappa degli asset grafici è in [design/README.md](design/README.md).

## Regole d'oro (sintesi)

1. **Mai perdere il conteggio.** Ogni modifica al layer dati richiede test prima del merge.
2. **Il conteggio non si blocca mai.** Gli effetti sono fire-and-forget rispetto al tap.
3. **Logica trigger pura e testata.** Gli effetti scattano solo su incremento, mai su decremento.
4. **Costanti in `config.dart`**, mai sparse nel codice.
5. **Un effetto = un modulo.** Aggiungere un easter egg non deve toccare quelli esistenti.

Versione estesa e vincolante in [CLAUDE.md](CLAUDE.md).
