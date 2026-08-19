# Mad Dog Counter — Architettura

## Filosofia MVP

**Local-first.** Il contatore vive nella memoria del tablet. Nessun backend, nessuna rete richiesta: l'app funziona sempre, punto. La persistenza online (Firebase o simili) è **fase 2**, e l'architettura la predispone tramite il pattern repository — quando arriverà, si aggiunge un'implementazione senza toccare UI né logica.

## Stack

| Layer | Scelta | Note |
|---|---|---|
| Framework | **Flutter** (Dart, ultima stable) | Il maintainer conosce Dart/Flutter. Una sola code base. |
| State management | **Riverpod** | Provider tipizzati, testabili. Niente Bloc. |
| Persistenza totale | **shared_preferences** (scrittura a ogni tap) | Un intero. Semplice, affidabile, sincrono di fatto. |
| Log dei tap | **sqflite** (tabella append-only) | Timestamp + delta per ogni tap. Alimenta le statistiche di fase 2 e l'eventuale migrazione online. |
| Animazioni | Animazioni native Flutter + pacchetto `confetti` + Lottie/sprite custom dove serve | Dettagli in ANIMATIONS_SPEC.md. |
| Audio | `audioplayers` (o `just_audio`) | Effetti sonori a tutto volume, low-latency. |
| Schermo sempre acceso | `wakelock_plus` | NO kiosk mode totale: solo wakelock. |

## Target

- **Android only**, orientamento **landscape bloccato** (`SystemChrome.setPreferredOrientations`).
- **Device di produzione: Samsung Galaxy Tab A8 (SM-X200)** — Android 14 (API 34), One UI 6.1, schermo 10.5" 1920×1200. Ampiamente dentro i requisiti di Flutter stable corrente: nessun vincolo di versione.
- **Flutter: ultima stable corrente**, plugin alle ultime versioni. `minSdkVersion 24` (il minimo di Flutter ≥ 3.35: non serve alzarlo, il device è a 34), `targetSdkVersion` all'ultima richiesta dalla toolchain.
- Hardware di fascia media (SoC Unisoc, non un flagship): le animazioni pesanti vanno comunque verificate sul device. Budget prestazioni (densità particelle, durata effetti) configurabile in `config.dart`, così la taratura è un numero da cambiare, non un refactoring.
- Nota storica: il tablet precedente (Asus TF300T, Android 5.1.1 / API 22) è stato scartato perché sotto il minimo supportato da Flutter ≥ 3.35. Non è più un target: nessun workaround per device datati nel codice.

## Modello dati (locale)

```
shared_preferences:
  counter_total : int      // fonte di verità. Inizializzato a 239338.
  sound_enabled : bool     // default true
  idle_minutes  : int      // default 10

sqflite — tabella taps:
  id INTEGER PRIMARY KEY AUTOINCREMENT
  ts INTEGER NOT NULL      // epoch ms
  delta INTEGER NOT NULL   // ±1 per i tap; delta arbitrario per gli adjust
  type TEXT NOT NULL DEFAULT 'tap'   // 'tap' | 'adjust' (impostazione manuale dal pannello)
```

- **`counter_total`** si scrive a ogni tap, immediatamente. È la verità mostrata a schermo.
- **`taps`** è un log append-only, scritto fire-and-forget: se una insert fallisce, il conteggio NON deve risentirne. Le modifiche manuali dal pannello impostazioni entrano come record `type='adjust'` col delta risultante: lo storico resta sommabile.
- All'avvio, sanity check facoltativo: se `counter_total` e la somma dei delta divergono, fa fede `counter_total` (loggare la discrepanza).

## Pattern repository (la porta verso la fase 2)

```dart
abstract class CounterRepository {
  Stream<int> watchTotal();
  Future<void> increment();
  Future<void> decrement();
}

class LocalCounterRepository implements CounterRepository { ... } // MVP
// fase 2: class SyncedCounterRepository implements CounterRepository
// (locale come cache + backend online, migrazione del log taps)
```

La UI e il motore effetti dipendono **solo** dall'interfaccia. Nessun `import` di storage fuori da `data/`.

## Migrazione / inizializzazione

Al primo avvio, se `counter_total` non esiste, inizializzarlo a **`INITIAL_COUNT = 239338`** (valore storico del vecchio counter, fotografato il 28/07/2026). Costante in `config.dart`.

## Rischio noto (accettato per l'MVP)

Se il tablet muore o l'app viene disinstallata, il conteggio locale va perso. Mitigazione minima ed economica: ogni giorno alla prima apertura/scrittura, salvare una copia di `counter_total` e un dump del log in un file nella storage esterna dell'app (`backup_YYYYMMDD.json`, tenere gli ultimi 7). Non è un backup vero, ma salva dal 90% dei disastri. La soluzione definitiva è la fase 2.

## Struttura progetto Flutter (indicativa)

```
lib/
  main.dart
  config.dart              // costanti: INITIAL_COUNT, soglie combo, durate
  data/
    counter_repository.dart // interfaccia + implementazione locale
    tap_log.dart            // sqflite append-only
  state/
    counter_provider.dart   // Riverpod: totale
    combo_provider.dart     // stato combo (finestra 2s, moltiplicatore)
    effects_provider.dart   // coda effetti/easter egg + kill switch
  ui/
    counter_screen.dart     // schermata unica
    widgets/                // numerone, aree tap, pulsante panico, overlay effetti
    effects/                // un widget/controller per easter egg
  audio/
    sound_manager.dart
assets/
  images/  fonts/  sounds/  lottie/   // asset ottimizzati usati dall'app
design/
  README.md  raw/  processed/         // materiale sorgente di brand (mai referenziato dal codice)
docs/
  *.md                                // le specifiche di questo pacchetto
```

## Qualità

- Unit test su: logica trigger easter egg (multipli, "finisce per 67", "8 adiacenti"), macchina a stati della combo, coda effetti con ordinamento per durata, kill switch (svuota coda e ferma tutto), clamp a zero, inizializzazione a INITIAL_COUNT.
- La logica dei trigger deve essere **pura** (funzioni Dart senza dipendenze da storage/UI) proprio per essere testabile.
