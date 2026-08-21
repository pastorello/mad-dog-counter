# White label — appunti di prodotto (NON implementare)

> **Stato: idea raccolta, non approvata per lo sviluppo.**
> Questo documento registra l'intervista col committente del 20 agosto 2026 e
> serve a non perdere le decisioni già prese. **Non si scrive codice su questa
> base**: quando il white label entrerà davvero in lavorazione va rifatta
> l'intervista, perché nel frattempo il prodotto sarà cambiato — il Dutch
> continuerà a chiedere modifiche, e quelle vengono prima.
>
> Ordine dei lavori deciso dal committente: **test → prestazioni → pulizia del
> codice → white label**, e solo a lavori davvero chiusi.

## Da dove nasce

L'app è piaciuta ad altri gestori di bar che l'hanno vista. L'idea è poterla
dare anche a loro senza portarsi dietro l'identità di The Dutch.

## Le due modalità

La scelta vive nel **pannello impostazioni**, come voce di configurazione.

### Modalità Dutch

È l'app di oggi, invariata. Tiene tutti gli **elementi proprietari**:

- il logo House of Mad Dogs (splash e marchio in basso al centro);
- la bandierina olandese;
- il timbro "Ciommo Approved".

### Modalità Custom

Toglie **tutti** gli elementi proprietari del Dutch e in cambio offre una
configurazione semplice:

- **la palette**: il nero di fondo, il rosso primario, cioè i colori che l'app
  usa un po' ovunque;
- **un vettoriale sostitutivo al posto di Ciommo**.

Esempio fatto dal committente: l'**Enjoy bar** avrebbe un proprio vettoriale al
posto di Ciommo e la propria palette — verde, oro, e un terzo colore chiaro.
*(I colori esatti dell'Enjoy sono da riprendere: la telefonata era rumorosa e
il terzo colore non è stato registrato con certezza.)*

## Cosa gioca a favore

La palette è già interamente in `lib/config.dart` e nessun colore è cablato
dentro i widget: `kBackground`, `kPrimaryRed`, `kAccentBlue`, `kTextColor`,
`kCelebrationGold`, più i rosa dell'easter egg. Il lavoro tecnico sui colori è
sostituire le costanti con un tema letto a runtime; il resto dell'app non se ne
accorge.

Anche gli asset di brand sono già isolati: `HomdMark` e `DutchFlagDivider` sono
widget a sé, il timbro è un asset con la sua costante.

## Domande aperte per la prossima intervista

Nessuna di queste ha una risposta ovvia, e tutte cambiano la stima:

1. **Perimetro del proprietario.** Logo, bandierina e Ciommo sono dichiarati.
   E i **testi celebrativi** delle combo, i **suoni**, il font Creepster, il
   nome "Mad Dog"? Un altro bar conta i suoi cicchetti: come si chiamano?
2. **Cosa prende il posto di logo e bandierina** in modalità custom: niente
   (spazio vuoto), o asset del cliente?
3. **Da dove arrivano gli asset del cliente**: scelti da file sul tablet,
   messi in una cartella, o compilati dentro un APK per cliente?
4. **Quanti colori** sono configurabili: i due dichiarati (fondo e primario) o
   tutti e cinque i ruoli della palette? Chi garantisce il contrasto minimo
   quando il gestore sceglie giallo su bianco?
5. **Un APK per tutti o un APK per cliente.** Cambia licenze, aggiornamenti,
   firma e distribuzione.
6. **Gli easter egg restano?** Le tette rosa e i cuoricini sono neutri come
   brand, ma sono una scelta di tono che non è detto vada bene in ogni locale.
7. **Il cambio modalità** richiede riavvio? E soprattutto: **non deve toccare
   il conteggio** — vale la regola d'oro 1 anche qui.
8. **Modello commerciale**: decisione del committente, non tecnica, ma
   determina se serve una licenza per installazione, una scadenza, un blocco.

## Vincoli che restano validi comunque

- Il conteggio non si tocca: qualunque cosa faccia il tema, il totale e il log
  restano quelli (regola d'oro 1).
- Niente ritardi sul tap: il tema si legge all'avvio, non a ogni frame.
- Un tema mal configurato non deve poter rendere l'app illeggibile o
  inutilizzabile: serve un fallback ai colori di default.
