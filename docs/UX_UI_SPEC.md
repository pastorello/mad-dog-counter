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

⚠️ Niente rosa: la foto del poster nel locale ha una dominante calda che falsava i colori. Fanno fede i file vettoriali/di stampa.

### Motivo ricorrente

La **bandierina olandese** (striscia rosso/bianco/blu) è il separatore firma del brand: usarla come elemento orizzontale sottile (es. sotto il numerone o come bordo inferiore dello schermo).

## Layout (landscape)

```
┌──────────────────────────────────────────────┐
│ [logo HoMD piccolo]              [⛒ panico] │
│                                              │
│   ◄──── zona −1 ────►│◄──── zona +1 ────────►│
│   (~25% larghezza)   │   (~75% larghezza)    │
│                                              │
│              2 3 9 3 3 8                     │
│           (numerone centrale)                │
│                                              │
│  ═══ bandierina olandese (separatore) ═══    │
│  [stasera — fase 2, placeholder]     [⚙ imp] │
└──────────────────────────────────────────────┘
```

- **Pulsante panico**: angolo alto destro, icona piccola e discreta (es. una "X" in un cerchio sottile, opacità ridotta), con padding generoso che lo isola dalla zona +1: i suoi tap NON contano come incrementi. Comportamento in FUNCTIONAL_SPEC.md.
- **Ingranaggio impostazioni**: angolo basso destro, stessa discrezione del pulsante panico, isolato dalla zona +1 e dalla bandierina. Si apre SOLO con pressione lunga (3 s); pannello overlay scuro coerente con la palette, tipografia secondaria (non Creepster: nel pannello serve leggibilità, usare il sans condensed). Dettagli in FUNCTIONAL_SPEC.md.
- I due controlli di servizio stanno entrambi sul **bordo destro** (panico in alto, impostazioni in basso), lontani tra loro quanto basta da non confonderli, e la zona −1 a sinistra resta completamente pulita.

- **Numerone**: l'unico protagonista. Occupa la maggior parte dell'altezza, centrato, bianco sporco con glow rosso sottile. Deve leggersi dall'altro lato del bancone.
- Le **zone tap** sono invisibili (tutto lo schermo è touch); un hint discreto (chevron − a sinistra) suggerisce la zona di decremento. Le zone si illuminano leggermente al tocco.
- Nessun bottone, nessuna barra, nessun menu.

## Tipografia

- **Numerone**: stile **graffiti/pennellata** come il lettering del poster «Come bere il Mad Dog» (scelta esplicita del committente). Il lettering del poster è disegnato, non un font esistente: dopo un confronto visivo tra 8 candidati Google Fonts, la scelta è **Creepster** (`design/fonts/Creepster-Regular.ttf`, licenza OFL inclusa) — maiuscole compatte a bordi frastagliati fedelissime al poster, cifre distinguibili. Alternativa più morbida già nel pacchetto: **Knewave**. Validare la scelta guardandola sul tablet vero. Le cifre devono avere larghezza stabile (slot a larghezza fissa via layout, i font brush non hanno cifre tabular) per evitare che il numero balli a ogni cifra che cambia.
- **Testi celebrativi combo**: stesso font del numerone (Creepster), rosso 186C con bordo scuro.
- **Testi secondari** (stato connessione, placeholder): sans-serif bold condensed, come la tipografia del logo HoMD.

## Micro-interazioni

- Cambio cifra: le cifre **rollano** (slot machine verticale veloce) invece di cambiare a scatto.
- Pulsazione tap: scale 1.0 → 1.06 → 1.0 in ~150 ms, curva elastica.
- Decremento: pulsazione verso il basso + flash blu.
- Tutte le animazioni a 60 fps: testare sul tablet vero, che potrebbe essere datato — se arranca, ridurre le particelle, mai il frame rate.

## Asset

| Asset | File nel repo | Uso nell'app |
|---|---|---|
| Logo The Dutch | `design/raw/logo_the_dutch_sottobicchiere.jpg` (+ varianti `logo_the_dutch_*.jpg`) | Splash/credits, uso marginale. NON vettorizzare automaticamente (tratteggio inciso troppo fine): usare PNG ritagliato |
| Logo House of Mad Dogs | `design/raw/logo_house_of_mad_dogs_sottobicchiere.jpg` — vettoriale del bicchiere: `design/processed/homd_shot_glass.svg` (bozza da rifinire sul riferimento) | Logo principale in-app (angolo alto sx) + splash |
| Ciommo Approved | `design/processed/ciommo_approved.svg` (vettoriale; per fondo scuro cambiare fill in `#F0F0F0`), alternative raster `ciommo_approved_white.png` / `ciommo_sticker_round.png` | Stamp delle combo lunghe |
| Bandierina olandese | `design/processed/dutch_flag_stripe.svg` | Separatore firma |
| Poster rituale | `design/raw/poster_come_bere_il_mad_dog.jpg` | Riferimento di stile per il lettering brush |
| Faccina annoiata | `design/raw/idle_faccina_riferimento.jpg` | Riferimento per l'animazione idle (da ridisegnare/animare) |
| Bozza di stampa | `design/raw/bozza_tshirt_specifiche_pantone.jpg` | Fonte dei Pantone ufficiali (186C / 2728C / bianco) |
| Foto counter attuale | `design/raw/foto_counter_attuale_239338.jpg` | Documentazione: valore di migrazione 239338 |

Mappa completa e note in `design/README.md`. La cartella `design/` è **materiale sorgente**: gli asset effettivamente usati dall'app vanno esportati/ottimizzati in `assets/` del progetto Flutter (PNG trasparenti ad alta risoluzione o SVG), mai referenziare `design/` dal codice.

## Accessibilità e robustezza d'uso

- Contrasto testo/sfondo sempre ≥ 7:1 per il numerone.
- Target touch: le due zone coprono l'intero schermo, impossibile mancare.
- Niente informazioni affidate solo al colore: il decremento ha anche direzione di animazione e suono diversi.
