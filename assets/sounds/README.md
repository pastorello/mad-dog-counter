# sounds/ — Set effetti sonori Mad Dog Counter (prima versione)

Suoni **sintetizzati proceduralmente** in stile arcade/8-bit: nessun campione di terze parti, nessuna licenza da gestire, uso libero. Pensati come set coerente e sostituibile: per cambiare un suono basta rimpiazzare il file WAV mantenendo il nome.

Formato: WAV mono 44.1 kHz 16-bit. Già in `assets/sounds/` e già dichiarati in `pubspec.yaml` (l'intera cartella è un asset bundle).

I nomi dei file **non vanno cambiati**: sono il contratto col codice, e sono referenziati dalle costanti `kSfx*` in `lib/config.dart`. Per sostituire un suono, rimpiazzare il WAV mantenendo il nome.

| File | Durata | Evento (rif. ANIMATIONS_SPEC.md) |
|---|---|---|
| `tap_pop.wav` | 0.07 s | Tap base incremento |
| `tap_down.wav` | 0.12 s | Tap decremento (blip discendente) |
| `combo_milestone.wav` | 0.32 s | Soglie della combo (ta-daa). Per il pitch crescente dei pop in combo, usare `tap_pop.wav` con playback rate variabile |
| `wobble_67.wav` | 1.0 s | Numero che finisce per 67 |
| `boing.wav` | 0.55 s | Trasformazione 8 adiacenti |
| `fireworks.wav` | 2.1 s | Multiplo di 100 |
| `bowling_roll.wav` | 1.8 s | Strike dei 1000: rotolamento (sincronizzare con l'ingresso della palla) |
| `bowling_strike.wav` | 1.3 s | Strike dei 1000: impatto + birilli + campanella |
| `panic_explosion.wav` | 1.0 s | Pulsante panico |
| `wake_jubilation.wav` | 0.52 s | Risveglio dopo idle (l'idle in sé è muto per specifica) |

Note: volumi già normalizzati tra loro ma da verificare sulle casse del tablet nel rumore del pub. Se un suono non convince, si sostituisce il singolo file — nomi e durate sono il contratto con il codice.
