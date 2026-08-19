# design/ — Asset grafici Mad Dog Counter

Materiale di brand per l'app. Riferimenti d'uso in `docs/UX_UI_SPEC.md`.

⚠️ **Nota sui sorgenti**: tutti i file in `raw/` sono **render raster (JPEG)**, non vettoriali. I vettoriali originali sono stati richiesti alla tipografia Pubblicarrello (ordine n. 127461 del 21/09/2022) e **non arriveranno**: vanno ridisegnati internamente partendo dai raster. Gli asset in `processed/` sono sufficienti per lo sviluppo su tablet nel frattempo; il primo da rifare è il logo House of Mad Dogs, che è il logo principale dell'app.

## raw/ — materiale originale

| File | Cos'è | Uso |
|---|---|---|
| `logo_the_dutch_sottobicchiere.jpg` | Logo del locale The Dutch (gotico rosso, bandiera, "Since 1980", "Gaeta, Italy") su fondo nero, dal sottobicchiere 93×93 | Riferimento brand; splash/credits |
| `logo_house_of_mad_dogs_sottobicchiere.jpg` | Logo del brand del cicchetto: bicchiere shot rosso + "HOUSE OF MAD DOGS — May cause unforgettable nights" | **Logo principale dell'app**; riferimento per il ridisegno vettoriale |
| `ciommo_approved_lineart.jpg` | Logo personale del barista Ciommo, line-art nera su bianco | Sorgente dei PNG trasparenti in processed/ |
| `sticker_ciommo_screenshot.jpg` | Screenshot WhatsApp dello sticker rotondo "Ciommo Approved" stampato | Sorgente del ritaglio rotondo; riferimento versione "timbro" |
| `poster_come_bere_il_mad_dog.jpg` | Poster del rituale in 4 step (versione file) | **Riferimento di stile per il lettering brush/graffiti** del numerone |
| `logo_the_dutch_bandiera_gaeta.jpg` | Render logo The Dutch + striscia bandiera + "Gaeta - Italy" (dalla bozza di stampa) | Riferimento pulito del lettering gotico |
| `logo_the_dutch_piccolo_rosso.jpg` | Logo The Dutch piccolo rosso su nero | Riferimento |
| `logo_the_dutch_bandiera_verticale.jpg` | Variante verticale con bandiera | Riferimento |
| `logo_the_dutch_since_1980.jpg` | Logo grande "The Dutch — Since 1980" | Riferimento |
| `bozza_tshirt_specifiche_pantone.jpg` | Bozza tipografica t-shirt: riporta i **colori ufficiali BIANCO / PANTONE 186C / PANTONE 2728C** | Fonte autorevole della palette |
| `bozza_felpa_specifiche.jpg` | Bozza tipografica felpa baristi | Riferimento |
| `foto_counter_attuale_239338.jpg` | Foto del vecchio counter col valore **239338** | Documentazione storica. L'app parte da zero: il valore di subentro si imposta a mano dal pannello |
| `foto_poster_nel_locale.jpg` | Foto del poster appeso nel pub | Solo contesto (colori falsati dalla luce calda: NON usarla come riferimento colore) |
| `idle_faccina_riferimento.jpg` | Faccina gialla triste con occhioni | Riferimento per l'animazione idle (da ridisegnare/animare) |

## processed/ — asset pronti all'uso

| File | Cos'è | Uso in app |
|---|---|---|
| `ciommo_approved.svg` | **Vettoriale** della line-art di Ciommo (vettorizzazione automatica ad alta fedeltà, riempimento nero: cambiare `fill` in `#F0F0F0` per usarlo su fondo scuro) | Asset preferito per lo stamp "Ciommo Approved": scala all'infinito |
| `ciommo_approved_white.png` | Ciommo line-art **bianco sporco (#F0F0F0) su trasparente**, bordi morbidi | Alternativa raster dello stamp (fondo scuro) |
| `ciommo_approved_black.png` | Stessa line-art in nero su trasparente | Eventuali contesti chiari |
| `ciommo_sticker_round.png` | Sticker rotondo ritagliato dallo screenshot, fondo trasparente | Variante "timbro/badge" per gli stamp; nota: è una foto dello sticker stampato, qualità media |
| `homd_shot_glass.svg` | **Ridisegno vettoriale** del bicchiere shot HoMD in Pantone 186C | Logo/icona in-app, scalabile. Prima bozza fedele: rifinire se serve. L'onda del liquido è "scavata" con una forma color sfondo `#0E0E14`: adattarla se lo sfondo cambia |
| `dutch_flag_stripe.svg` | Striscia bandiera olandese (186C / #F0F0F0 / 2728C) | Separatore firma sotto il numerone / bordo schermo |

## fonts/ — tipografia scelta

| File | Cos'è | Uso |
|---|---|---|
| `Creepster-Regular.ttf` | **Font principale** (Google Fonts, licenza OFL inclusa): il match più vicino al lettering brush del poster | Numerone del contatore, titoli, testi celebrativi |
| `Knewave-Regular.ttf` | Alternativa a pennello più morbida (OFL) | Fallback se Creepster risulta troppo "horror" dal vivo |

Il lettering originale del poster è disegnato a mano/generato, non corrisponde a un font esistente: Creepster è la scelta ufficiale salvo ripensamenti guardandolo sul tablet. Copiare il TTF scelto in `assets/fonts/` del progetto Flutter e dichiararlo nel `pubspec.yaml`.

## Da produrre (non ancora esistenti)

- Grafica "tette" per l'easter egg degli 8 adiacenti (stile cartoon, rosso 186C)
- Faccina idle animata (rielaborazione del riferimento, meglio se Lottie o sprite sheet)
- Palla da bowling e cifre "spaccabili" per lo strike dei 1000
- Suoni: pop tap, wobble, fuochi, strike, boing, giubilo (nessun file audio ancora fornito)
