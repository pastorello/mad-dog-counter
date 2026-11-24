# Mad Dog Counter — UX/UI

## Contesto visivo

Tablet a muro in un pub buio con luci calde e musica alta. La UI deve: leggersi da lontano, essere scura (niente pannello accecante a parete), urlare il brand House of Mad Dogs.

## Brand system (verificato sui file ufficiali)

Il locale è **The Dutch** (Gaeta, since 1980); il brand del cicchetto è **House of Mad Dogs** («May cause unforgettable nights»). I colori di stampa ufficiali, confermati dalla bozza tipografica (`design/raw/bozza_tshirt_specifiche_pantone.jpg`, dall'ordine di stampa Pubblicarrello n. 127461), sono **bianco / Pantone 186C / Pantone 2728C**.

### Palette

| Ruolo | Colore | Hex | Note |
|---|---|---|---|
| Sfondo | Nero-antracite | `#0E0E14` | Non nero puro: ha una punta di blu, come nei logo. |
| Primario | Rosso Pantone 186C | `#C8102E` | Il rosso del bicchiere HoMD. Nei JPEG campiona ~`#D03030`. |
| Accento | Blu Pantone 2728C | `#0047BB` | Nella bandierina appare come navy ~`#204070`: usare il navy per superfici, il blu pieno per accenti. |
| Testo/contrasto | Bianco sporco | `#F0F0F0` | Mai bianco puro. |
| Celebrativo | Oro/ambra | `#F0A830` (indicativo) | Solo per momenti epici (fuochi, glow combo), richiama la luce calda del pub. |

⚠️ Niente rosa **nella UI di brand**: la foto del poster nel locale ha una dominante calda che falsava i colori. Fanno fede i file vettoriali/di stampa.

**Unica eccezione, decisa dal committente**: l'easter egg degli 8 adiacenti usa il rosa carne (`#EFA79B`) e il rosa dei cuoricini (`#E86A8A`). In rosso di brand la battuta non si leggeva — un `88` rosso non sembra una tetta. Il rosa vive lì e solo lì.

### Motivo ricorrente

La **bandierina olandese** (striscia rosso/bianco/blu) è il separatore firma del brand: usarla come elemento orizzontale (es. sotto il numerone o come bordo inferiore dello schermo). In app è il bordo inferiore, alto `kDutchFlagHeight` (**40 dp dalla v2**, DECISIONS → 04: a 12 era corretta ma timida; il tetto del marchio è sceso a 0,23 per farle spazio).

## Layout (landscape)

```
┌──────────────────────────────────────────────┐
│         [x4 + testo combo]       [⛒ panico] │
│                                              │
│   ◄──── zona −1 ────►│◄──── zona +1 ────────►│
│   (~25% larghezza)   │   (~75% larghezza)    │
│                                              │
│              2 3 9 3 3 8                     │
│           (numerone centrale)                │
│                                              │
│  [timbro]   [logo HoMD]   [timbro]           │
│  ═══ bandierina olandese (separatore) ═══    │
│                                      [⚙ imp] │
└──────────────────────────────────────────────┘
```

- **In alto al centro** ci vanno il moltiplicatore della combo e i testi celebrativi: è l'area degli eventi. Dalla v2 ci abita anche l'**intestazione «MAD DOG COUNTER»** (Oswald Bold 44, tracking 6, ink all'80%), che però è un'ospite educata: **si dissolve** quando la fascia serve agli eventi (combo, effetti in coda, faccina) e torna a scena finita (DECISIONS → 01).
- **In alto a sinistra** (angolo opposto al panico) sta il **badge del record** `OGGI n · RECORD m` (v2): Oswald Bold 26, etichette in ink spento, numeri in oro, una riga sola, sempre a schermo. Primo giorno: `RECORD —`. Decorativo, non intercetta tap.
- **Marchio House of Mad Dogs**: in basso al centro, piccolo, sopra la bandierina. Sempre a video, anche durante gli effetti; decorativo, non intercetta tap. I timbri "Ciommo Approved" salgono dal bordo basso ai suoi due lati, senza mai coprirlo.
- **Pulsante panico**: angolo alto destro, icona piccola e discreta (es. una "X" in un cerchio sottile, opacità ridotta), con padding generoso che lo isola dalla zona +1: i suoi tap NON contano come incrementi. Comportamento in FUNCTIONAL_SPEC.md.
- **Ingranaggio impostazioni**: angolo basso destro, stessa discrezione del pulsante panico, isolato dalla zona +1 e dalla bandierina. Si apre SOLO con pressione lunga (2 s), con un anello rosso spesso che si riempie mentre si tiene premuto; pannello overlay scuro coerente con la palette, tipografia secondaria (non Creepster: nel pannello serve leggibilità, usare il sans condensed). Dettagli in FUNCTIONAL_SPEC.md.
- I due controlli di servizio stanno entrambi sul **bordo destro** (panico in alto, impostazioni in basso), lontani tra loro quanto basta da non confonderli, e la zona −1 a sinistra resta completamente pulita.

- **Numerone**: l'unico protagonista. Occupa la maggior parte dell'altezza, centrato, bianco sporco con glow rosso sottile. Deve leggersi dall'altro lato del bancone. **Sempre a sei cifre, zeri davanti compresi** (`000000`, `000001`, …): è un tabellone, e così non cambia larghezza a ogni passaggio di decina. Gli zeri si disegnano pieni come le altre cifre.
- Le **zone tap** sono invisibili (tutto lo schermo è touch); un hint discreto (chevron − a sinistra) suggerisce la zona di decremento. Le zone si illuminano leggermente al tocco.
- Nessun bottone, nessuna barra, nessun menu.

## Tipografia

- **Numerone (v2)**: cifre in **Passion One Bold** (`kCounterFont`, `assets/fonts/PassionOne-Bold.ttf`, OFL), scelto per confronto diretto nei mockup della Fase 0 (DECISIONS → 05) col mandato «meno Halloween, sempre da pub»: condensed caldo, le cifre più grandi del lotto. Lo slot fisso è ritarato sulla misura vera del font (`kDigitSlotRatio = 0.56`: la cifra più larga è il 4 a 0,548 em) — slot a larghezza fissa sempre, questi font non hanno cifre tabular e il numero ballerebbe.
- **Creepster** (`design/fonts/Creepster-Regular.ttf`, OFL) resta la voce **celebrativa**: testi combo, STRIKE!, APOTEOSI, NUOVO RECORD!, TILT. Era anche il font delle cifre fino alla v2; Knewave resta nel pacchetto come alternativa.
- **Testi celebrativi combo (v2)**: Creepster, rosso 186C con bordo scuro, **corpo 140** col **moltiplicatore a 160** (DECISIONS → 04): la fascia alta si prende tutto lo spazio fino al contatore, lieve invasione del glow accettata.
- **Testi secondari** (stato connessione, placeholder) e **logo HoMD** ("HOUSE OF MAD DOGS", tagline, "THE DUTCH PUB · GAETA"): **Oswald Bold** (`kBrandFont`), il font vero del logo — confermato dal font incorporato nel vettoriale ufficiale del committente (`design/raw/sottobicchiere_homd_93x93.pdf`, consegnato il 2026-08-22), non più un sans generico a occhio.

## Micro-interazioni

- Cambio cifra: le cifre **rollano** (slot machine verticale veloce) invece di cambiare a scatto.
- Pulsazione tap: scale 1.0 → 1.06 → 1.0 in ~150 ms, curva elastica.
- Decremento: pulsazione verso il basso + flash blu.
- Tutte le animazioni a 60 fps: testare sul tablet vero, che potrebbe essere datato — se arranca, ridurre le particelle, mai il frame rate.

## Asset

| Asset | File nel repo | Uso nell'app |
|---|---|---|
| Logo The Dutch | `design/raw/logo_the_dutch_sottobicchiere.jpg` (+ varianti `logo_the_dutch_*.jpg`) | Splash/credits, uso marginale. NON vettorizzare automaticamente (tratteggio inciso troppo fine): usare PNG ritagliato |
| Logo House of Mad Dogs | `design/raw/logo_house_of_mad_dogs_sottobicchiere.jpg` — vettoriale del bicchiere: `design/processed/homd_shot_glass.svg` (bozza da rifinire sul riferimento) | Logo principale in-app (in basso al centro) + splash |
| Ciommo Approved | `design/processed/ciommo_approved.svg` (vettoriale; per fondo scuro cambiare fill in `#F0F0F0`), alternative raster `ciommo_approved_white.png` / `ciommo_sticker_round.png` | Stamp delle combo lunghe |
| Bandierina olandese | `design/processed/dutch_flag_stripe.svg` | Separatore firma |
| Poster rituale | `design/raw/poster_come_bere_il_mad_dog.jpg` | Riferimento di stile per il lettering brush |
| Faccina annoiata | `design/raw/idle_faccina_riferimento.jpg` | Riferimento per l'animazione idle (da ridisegnare/animare) |
| Bozza di stampa | `design/raw/bozza_tshirt_specifiche_pantone.jpg` | Fonte dei Pantone ufficiali (186C / 2728C / bianco) |
| Foto counter attuale | `design/raw/foto_counter_attuale_239338.jpg` | Documentazione storica del vecchio counter (239338 al 28/07/2026) |

Mappa completa e note in `design/README.md`. La cartella `design/` è **materiale sorgente**: gli asset effettivamente usati dall'app vanno esportati/ottimizzati in `assets/` del progetto Flutter (PNG trasparenti ad alta risoluzione o SVG), mai referenziare `design/` dal codice.

## Accessibilità e robustezza d'uso

- Contrasto testo/sfondo sempre ≥ 7:1 per il numerone.
- Target touch: le due zone coprono l'intero schermo, impossibile mancare.
- Niente informazioni affidate solo al colore: il decremento ha anche direzione di animazione e suono diversi.
