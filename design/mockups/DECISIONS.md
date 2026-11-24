# Fase 0 — Decisioni del committente (24/11/2026)

Esito delle prove di layout in questa cartella. Queste decisioni guidano le PR A–D
e vanno riversate in `docs/UX_UI_SPEC.md` (PR grafica) e nelle altre spec dove indicato.

## 01 · Intestazione e badge

- **Intestazione**: «MAD DOG COUNTER», **Oswald Bold 44**, tracking 6, al **bordo alto** (y 40,
  la fascia eventi). **Si dissolve** quando parte una combo, uno strike o l'idle, e torna dopo.
- **Badge giornaliero**: **alto a sinistra**, corpo **26**, una riga unica
  `OGGI 87 · RECORD 214` (numeri in oro); primo giorno `RECORD —`.
- Il giornaliero mostrato ha il **pavimento a zero** (mai negativo a video).
- **Celebrazione NUOVO RECORD anche il primissimo giorno**: il record parte da 0 e il primo
  mad dog lo batte già. Una sola celebrazione per finestra (mezzogiorno→mezzogiorno).

## 05 · Font del numerone

- **Passion One (peso 700)** al posto di Creepster **solo per le cifre** (`kCounterFont`).
  Creepster resta per testi combo e STRIKE!.
- `kDigitSlotRatio` da ritarare sulla misura della pagina 05 (slot più stretto ⇒ numerone più grande).
- In PR C: scaricare il TTF (Google Fonts, OFL) in `assets/fonts/` + licenza + voce pubspec.

## 04 · Bandierina e testi combo

- **Bandierina: 40 px** (da 12). Il marchio HoMD si alza di 28 px: **ridurre
  `kHomdMarkMaxHeightFraction`** perché non morda le cifre (~27 px di gioco residuo).
- **Testi combo: la fascia alta si prende tutto lo spazio fino al contatore**, lieve invasione
  del glow accettata: **testo celebrativo 140**, **moltiplicatore 160** (da 40/56).

## 02 · Ciommo slam

- Timbro gigante **85% dell'altezza**, inclinato **−14°**, ritmo **2,0 s** (slam ~12% / hold ~65% / fade).
- **Suono: riuso del ta-daa `kSfxComboMilestone` a ogni timbro** (niente WAV nuovi).
- Scatta a ogni **multiplo di N della combo**, N **configurabile dal pannello** (default 5).

## 03 · Milestone e record

- **Approvati tutti i visual**: 10.000 = **pioggia di Mad Dog** (bicchierini rossi a piena
  opacità, finale oro; 7 s; fuochi + campanella strike), 100.000 = **apoteosi** (mega-salva
  tricolore, cifre in aria, botto finale oro/ink; 9 s; fuochi + esplosione panico),
  **NUOVO RECORD!** in oro (4 s; giubilo `wake_jubilation`).
- Assorbimento generalizzato: vince il più raro. Il record NON è una milestone: si accoda.

## 06 · Stagioni (ridefinite rispetto al piano)

- Le «stagioni» sono **temi**: **Nessuna (default) / Halloween / Natale**, scelti **a mano
  dal pannello impostazioni** (voce «Stagione»), elenco pensato per crescere.
  **Niente automatismo per data** per ora.
- **Halloween**: cornice **#F07820** (arancio zucca) ai bordi + **pipistrelli e zucche** ai
  4 angoli, in background dietro al numerone.
- **Natale**: cornice **#1E7A3C** (verde abete) + **palline, pacchi regalo e bastoncini di
  zucchero** ai 4 angoli, più la **neve** che scende.
- Arancio e verde sono **accenti stagionali fuori dalla palette base**: scelta del committente,
  diventeranno token dedicati (`kSeasonFrame*`), il resto della UI non li usa.

## 07 · Tilt

- Look **sfocato** (velo 0,72 + blur 6), parola **TILT ~600 px** rossa con **vibrazione**
  leggera, **barra rossa** che si svuota col tempo residuo.
- Messaggio **60 px**, **personalizzabile dal pannello** (nuova impostazione testo),
  default: **«CALMA RAGAZZI, IL MAD DOG VA RISPETTATO»**.
- Soglia (default **100** mad dog in **2 ore** fisse) e durata scena (default **60 s**)
  regolabili dal pannello. **I tap passano sotto e contano sempre.**

## Impatti sul piano approvato

- **PR A**: `shouldCelebrateRecord` **senza** la condizione `best > 0`; si aggiunge la pref
  del **messaggio tilt** (testo). Il clamp a zero è solo di visualizzazione.
- **PR B**: slam col ta-daa a ogni timbro (non muto).
- **PR C**: font = Passion One 700 (TTF da scaricare); taglie come sopra.
- **PR D**: niente `seasonFor(DateTime)` automatico — `enum Season { none, halloween, christmas }`
  + pref `season` + voce pannello; cornice + decorazioni ai 4 angoli + neve (solo Natale).
- **Pannello impostazioni**, voci nuove approvate dal committente: soglia tilt, durata tilt,
  messaggio tilt, intervallo Ciommo, stagione.
