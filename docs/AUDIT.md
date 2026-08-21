# Audit — solidità e prestazioni

Fotografia del progetto al 20 agosto 2026, `main` a `59e0652` (dopo PR #5 e #6).
Ogni voce ha una prova, non un'impressione. Priorità: 🔴 da fare, 🟡 quando
capita, ⚪️ pulizia.

Punto di partenza onesto: il progetto sta in piedi bene. 4.685 righe di `lib`,
2.609 di test, `flutter analyze` pulito, **177 test verdi, copertura 90,0%**
(1.176/1.306 righe). Le regole d'oro sono rispettate quasi ovunque: il totale
vive in memoria, la UI non aspetta mai lo storage, log e audio sono
fire-and-forget. Quello che segue è il margine che resta.

---

## Solidità

### 🔴 S1. Il sanity check di avvio non esiste

`TapLog.sumOfDeltas()` è dichiarato, implementato e documentato come «serve al
sanity check di avvio». **Nessuno lo chiama in `lib/`**: gli unici riferimenti
sono nei test e nei fake.

Significa che se una riga di log si perde — e può succedere, `SqfliteTapLog.record()`
inghiotte le eccezioni di proposito — la divergenza tra totale e somma dei delta
non se ne accorge nessuno, per sempre. È il tipo di errore che scopri anni dopo,
quando il log serve davvero.

**Da fare**: all'avvio confrontare `sumOfDeltas()` col totale salvato. Il totale
resta la verità (quello è sacro, il log è derivato), ma la discrepanza va
registrata — un record di riconciliazione nel log stesso, così le somme future
tornano, e un campo in `shared_preferences` con l'ultima discrepanza vista.
Collegato al `TODO(logging)` in `counter_repository.dart:179`.

### 🔴 S2. Il backup blocca l'isolate della UI, e il costo cresce col tempo

`BackupService._write()` fa `dumpAll()` (tutte le righe del log in memoria) e
`jsonEncode` di tutto, sull'isolate principale. Misurato su questo Mac:

| tap nel log | encode | encode + scrittura | file |
|---|---|---|---|
| 1.000 | 4 ms | 11 ms | 0,1 MB |
| 50.000 | 33 ms | 42 ms | 2,6 MB |
| 150.000 | 86 ms | 114 ms | 7,9 MB |
| 300.000 | 164 ms | 213 ms | 15,9 MB |

Il Galaxy Tab A8 ha un Unisoc T618: mettici 5-10 volte tanto. A 150.000 tap
— cinque anni di pub a ritmo tranquillo — il **primo tap della giornata** si
porta dietro mezzo secondo o più di isolate bloccato, cioè animazione a scatti
proprio mentre qualcuno sta guardando. Il tap non si perde (viene contato prima),
ma si vede.

**Da fare**: spostare `jsonEncode` fuori dall'isolate della UI (`Isolate.run`),
e valutare se il dump integrale quotidiano abbia senso o se convenga uno
snapshot completo settimanale più un incrementale giornaliero.

### 🟡 S3. `_persist` ritenta due volte di fila e poi si arrende

`LocalCounterRepository._persist()` prova, riprova subito, e se fallisce anche
la seconda volta tace. Non c'è ritardo tra i due tentativi (se lo storage è
occupato, lo è anche un microsecondo dopo) e non c'è un tentativo differito.
Il valore si risalva al tap successivo, quindi il buco si chiude da solo — ma
se l'app muore lì in mezzo, quel tap è perso.

**Da fare**: secondo tentativo con un piccolo ritardo, e un ritento differito
(qualche secondo) se fallisce anche quello. È la scrittura più importante
dell'app, merita più di due tentativi immediati.

### 🟡 S4. `SqfliteTapLog` è coperto al 21%

Il file che tiene lo storico del pub è testato solo attraverso il `NoopTapLog`:
schema, insert, somma, ordinamento e dump veri non li esercita nessuno. Basta
`sqflite_common_ffi` fra le dev_dependencies per farli girare in test veri.

### 🟡 S5. `AudioPlayersSoundManager` è coperto al 6,7%

Del gestore audio si testa solo la variante silenziosa. Le parti che contano
— il pool in round-robin, `enabled` che spegne tutto, le eccezioni inghiottite —
non sono verificate. Servirebbe iniettare la factory del player invece di
istanziarlo nel costruttore: due righe di refactor, e diventa testabile.

---

## Prestazioni

### 🔴 P1. I timbri di Ciommo si decodificano a piena risoluzione

`Image.asset(kImgCiommoApproved, height: 288)` senza `cacheHeight`: Flutter
decodifica il PNG alla sua dimensione naturale, **924×1316 px ≈ 4,9 MB in RAM**,
per disegnarlo alto 288. Con `cacheHeight` scende a un quinto scarso, e anche la
prima comparsa diventa più rapida.

### 🔴 P2. Nessun `RepaintBoundary` in tutta l'app

Zero occorrenze in `lib/`. Il numerone ha un glow (ombre sfocate: raster
costoso) e rolla a ogni tap; senza confini di ripittura, ogni suo frame sporca
anche marchio, bandierina, bagliore e overlay. Tre `RepaintBoundary` — numerone,
marchio, faccina — isolano il lavoro senza cambiare una virgola di comportamento.

### 🟡 P3. L'overlay della combo resta montato per sempre

`ComboOverlay` tiene `_visible` all'ultimo stato attivo: finita la combo,
bagliore a opacità 0 e timbri traslati fuori schermo restano nell'albero fino
alla fine della sessione. Costo piccolo ma perpetuo, e tiene vive le immagini
dei timbri. Basta tornare a `SizedBox.shrink()` a dissolvenza finita.

### ⚪️ P4. `Opacity` nei builder animati

`strike_effect`, `idle_face` e `panic_button` avvolgono in `Opacity` dentro un
builder che gira a ogni frame: è un `saveLayer` per frame. Le versioni
`FadeTransition`/`AnimatedOpacity` costano meno. Impatto reale modesto, ma è la
strada giusta quando si tocca quel codice.

---

## Pulizia

### ⚪️ C1. Due costanti mai usate

`kDisplayFontAlt` (il font alternativo Knewave, che era «da validare sul tablet
vero») e `kImgCiommoSticker` (la variante rotonda del timbro). Su 104 costanti,
solo queste due sono morte. Il font resta però caricato in `pubspec.yaml`: se
Knewave non serve più, via anche da lì e l'APK cala.

### ⚪️ C2. La FIXLIST ha esaurito il suo compito

`docs/FIXLIST.md` è tutta chiusa. O la si archivia come diario della prima
sessione di test, o la si svuota tenendo il file come registro dei prossimi giri.

---

## Copertura, file per file

Le zone scoperte sono tre, e sono esattamente quelle sopra:

| file | copertura |
|---|---|
| `audio/sound_manager.dart` | 6,7% |
| `data/tap_log.dart` | 21,4% |
| `ui/effects/idle_face.dart` | 72,4% |
| `data/settings_repository.dart` | 78,6% |
| `state/counter_provider.dart` | 80,0% |
| tutto il resto | ≥ 90%, quasi tutto al 100% |

`main.dart` non è coperto affatto: l'inizializzazione (orientamento, wakelock,
apertura di log e audio con i loro fallback) non la esercita nessun test.
Estrarre la costruzione degli override in una funzione pura la renderebbe
verificabile — è lì che vivono le reti di sicurezza «se sqflite non si apre,
si conta lo stesso».

---

## Ordine dei lavori

Deciso dal committente il 20 agosto 2026:

1. **Prima i test** (S4, S5, e la copertura di `main.dart`). Si parte da qui
   proprio perché scrivendoli salteranno fuori dei bug: meglio trovarli con un
   test in mano che sul tablet del pub.
2. **Poi le prestazioni** (P1, P2, P3, e S2 che è insieme solidità e
   prestazioni).
3. **Poi la pulizia del codice** (C1, C2, P4, e S1/S3 se non sono già cadute
   lungo la strada).
4. **Solo a lavori davvero chiusi**, il white label — vedi WHITE_LABEL.md, che
   è appunti di prodotto e non un piano di sviluppo.
