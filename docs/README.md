# docs/ — Specifiche Mad Dog Counter

Ordine di lettura consigliato: ogni documento assume quelli sopra di sé.

| # | Documento | Cosa contiene | Quando serve |
|---|---|---|---|
| 1 | [PROJECT_BRIEF.md](PROJECT_BRIEF.md) | Cos'è l'app, obiettivi, non-obiettivi, contesto d'uso, attori | Sempre per primo: inquadra il prodotto |
| 2 | [ARCHITECTURE.md](ARCHITECTURE.md) | Stack, struttura delle cartelle, `CounterRepository`, persistenza, target Android | Prima di scrivere codice o toccare il layer dati |
| 3 | [FUNCTIONAL_SPEC.md](FUNCTIONAL_SPEC.md) | Comportamento: zone di tap, incremento/decremento, migrazione del valore 239338, pannello impostazioni | Prima di implementare una feature |
| 4 | [ANIMATIONS_SPEC.md](ANIMATIONS_SPEC.md) | Catalogo effetti ed easter egg, condizioni di trigger, coda effetti, combo | Prima di implementare un effetto |
| 5 | [UX_UI_SPEC.md](UX_UI_SPEC.md) | Palette, tipografia, layout, asset, accessibilità | Prima di toccare la UI |

Mappa degli asset grafici: [../design/README.md](../design/README.md).
Regole operative vincolanti per gli agenti AI: [../CLAUDE.md](../CLAUDE.md).

## Convenzioni

- I documenti si citano tra loro per **nome file nudo** (`ARCHITECTURE.md`): sono tutti fratelli in questa cartella.
- I percorsi di asset e cartelle (`design/raw/...`, `assets/...`) sono invece **relativi alla radice del repo**.
- Le domande ancora aperte con il committente sono elencate in fondo a [../CLAUDE.md](../CLAUDE.md).
