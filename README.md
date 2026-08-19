# Mad Dog Counter

App Android (Flutter) per il contatore dei cicchetti **Mad Dog** del pub **The Dutch** di Gaeta — brand del cicchetto **House of Mad Dogs**.

Sostituisce il vecchio counter del tablet a muro. Non è un gestionale: è un piccolo show da bancone, con animazioni, easter egg, combo e suoni.

Il contatore **parte da zero** (`INITIAL_COUNT = 0`): il valore storico del vecchio counter si imposta a mano dal pannello impostazioni al momento dell'installazione nel locale.

- **Device di produzione**: Samsung Galaxy Tab A8 (SM-X200), Android 14 / API 34, landscape bloccato, schermo sempre acceso.
- **Stack**: Flutter + Dart, Riverpod, persistenza locale (`shared_preferences` per il totale + `sqflite` per il log tap) dietro l'interfaccia `CounterRepository`.
- **Stato**: scheletro funzionante. Il contatore conta e persiste; effetti, audio e pannello impostazioni sono da fare.

## Struttura del repo

```
CLAUDE.md      istruzioni operative per gli agenti AI (regole d'oro, stack vincolato, testing)
docs/          le specifiche di progetto (vedi docs/README.md per l'ordine di lettura)
design/        materiale di brand: raw/ (sorgenti), processed/ (asset pronti), fonts/
lib/
  config.dart  TUTTE le costanti: valori, durate, palette, testi
  data/        CounterRepository (la porta verso la fase 2) + log tap sqflite
  state/       provider Riverpod + logica trigger pura degli easter egg
  ui/          schermata unica, widget, effetti
  audio/       gestione suoni
assets/        asset usati dall'app (font, immagini, suoni, lottie)
test/          unit test e widget test
.agents/       skill agent-skills, condivise fra i vari tool AI
```

`design/` è **materiale sorgente** e non va mai referenziato dal codice: gli asset usati dall'app vanno esportati e ottimizzati in `assets/` del progetto Flutter.

## Sviluppo

```bash
flutter pub get
flutter test
flutter analyze
flutter run
```

Prima di ogni commit: `dart format lib test` e `flutter analyze` puliti. La CI ricontrolla entrambi e pubblica un APK di debug come artifact, comodo per il sideload sul tablet senza SDK Android in locale.

## Cosa c'è e cosa manca

| | |
|---|---|
| ✅ Fatto | Contatore con persistenza, clamp a zero, log tap, zone di tap, landscape + wakelock, logica trigger pura, SoundManager, motore effetti con coda e kill switch, combo con Ciommo, pannello impostazioni, 102 test |
| ⬜ Da fare | I widget dei singoli easter egg (fuochi, strike, shake, tette), idle con la faccina, roll delle cifre, backup giornaliero, splash |

Ordine di implementazione consigliato in [docs/ANIMATIONS_SPEC.md](docs/ANIMATIONS_SPEC.md) → Priorità.

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
