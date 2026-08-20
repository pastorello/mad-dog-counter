# FIXLIST — richieste dal test sul campo

Correzioni chieste dal committente durante i test sull'emulatore.
Stato: **fatto** = implementato, test verdi, verificato a schermo.

## 1. Contatore sempre a 6 cifre — fatto

`000000`, `000001`, … Zeri davanti pieni come le altre cifre (scelta del
committente), non smorzati.

- `kCounterDigits = 6` in `config.dart`; l'imbottitura vive in
  `lib/ui/widgets/big_number.dart`.
- Gli indici delle coppie di 8 arrivano dal trigger calcolati sul numero nudo
  e vengono traslati degli zeri di riempimento: l'easter egg delle tette
  continua a colpire le cifre giuste.
- Effetto collaterale voluto: il numerone non cambia più larghezza da 9 a 10 o
  da 99 a 100.

## 2. Ingranaggio impostazioni — fatto (non era un bug)

Serviva tenere premuto davvero. Ridotta la pressione lunga da 3 a 2 secondi
(`kSettingsLongPress`) e raddoppiato lo spessore dell'anello rosso che si
riempie (`kSettingsRingStroke = 4`), che prima si notava appena.
Aggiornati FUNCTIONAL_SPEC, UX_UI_SPEC e CLAUDE.md.

## 3. Timbri "Ciommo Approved" — fatto

- Altezza triplicata: 96 → `kComboStampHeight = 288`.
- Entrano salendo dal bordo basso ed escono riscendendo: non sfumano più
  insieme al resto della combo, per questo stanno fuori dalla dissolvenza
  dell'overlay.
- Si dispongono ai due lati del marchio HoMD (pari a sinistra, dispari a
  destra, i più recenti verso l'esterno) e non lo coprono mai.

## 4. Marchio House of Mad Dogs in basso al centro — fatto

In alto al centro restano moltiplicatore e testi della combo: quella è l'area
degli eventi. Il marchio sta in fondo, sopra la bandierina, sempre a video
anche durante gli effetti, e non intercetta tap.
UX_UI_SPEC aggiornato (lo schema lo dava in alto a sinistra).

## 5. Bagliore della combo su tutto lo sfondo — fatto

Il gradiente radiale si spegneva prima dei bordi e la fascia sinistra (zona −1)
restava fredda. Ora sotto al nucleo caldo c'è una tinta piatta che copre tutto
lo schermo (`kComboGlowBaseAlpha`) e il raggio arriva agli angoli
(`kComboGlowRadius`).

## 6. Tette rosa carne + cuoricini — fatto

- Riempimento `kFleshPink` (#EFA79B) al posto del rosso di brand, capezzolo
  `kHeartPink`: in rosso la battuta non si leggeva.
- Nuovo modulo `lib/ui/effects/hearts_burst.dart`: una salva di cuoricini che
  esplode quando la coppia di 8 si forma e ricade con la gravità, coriandoli a
  forma di cuore.
- **Deroga alla palette**: UX_UI_SPEC vieta il rosa. L'eccezione è ora scritta
  nella spec, limitata a questo easter egg.

## 7. Bandierina olandese alta il doppio — fatto

6 → `kDutchFlagHeight = 12`. Marchio e timbri si sollevano di conseguenza:
le loro quote derivano dall'altezza della bandierina, non sono numeri a parte.

## 8. "STRIKE!" durante la palla da bowling — fatto

La parola sbatte in alto al centro, nella fascia dei testi combo, all'istante
dell'impatto della palla (non prima): entra di schianto e sfuma sul finale.
`kStrikeText` e `kStrikeTextSize` in `config.dart`.

## 9. Faccina annoiata: più in alto, più grande, lacrima vera — fatto

- Non più al centro dello schermo ma in cima, nella fascia dei contatori della
  combo (`kIdleFaceTop`).
- Cresciuta del 15%: `kIdleFaceSize` 320 → 368.
- La lacrima era una puntina dal profilo storto — due archi accostati. Ora è
  una goccia vera (punta in alto, pancia tonda, fianchi simmetrici), raggio
  raddoppiato (`kIdleTearRadiusFactor`), azzurro schiarito `kIdleTearBlue` con
  bordo e riflesso: il blu di brand pieno, su fondo scuro, spariva.
