# Mad Dog Counter — Project Brief

## Cos'è

App Android (tablet dedicato, montato a muro) per contare i cicchetti **Mad Dog** venduti al pub **The Dutch** di Gaeta (brand del cicchetto: **House of Mad Dogs**). Il Mad Dog è uno shot a base di vodka, sciroppo di amarena e Tabasco, con un rituale collettivo di bevuta (vedi `design/raw/poster_come_bere_il_mad_dog.jpg`).

L'app sostituisce un counter Android esistente, molto basilare: tap a destra/centro incrementa, tap a sinistra decrementa. Il contatore parte da **zero** e il valore di subentro viene impostato a mano dal pannello impostazioni il giorno dell'installazione (vedi FUNCTIONAL_SPEC.md → Migrazione).

## Obiettivi

1. **Persistenza affidabile del conteggio**: il totale sopravvive a crash e riavvii. Nell'MVP vive nella memoria del tablet (con backup giornaliero su file); la persistenza online è predisposta per la fase 2 (vedi ARCHITECTURE.md → pattern repository).
2. **Esperienza spettacolare**: il counter deve essere un piccolo show. Animazioni, easter egg, suoni, combo. È un oggetto di intrattenimento del pub, non un gestionale.
3. **Robustezza da pub**: ambiente rumoroso, mani ubriache, Wi-Fi ballerino. L'app deve contare offline e sincronizzare da sola, non perdere mai un tap, non uscire mai per sbaglio dalla schermata.

## Non-obiettivi (per ora)

- Nessun sito web pubblico di consultazione (fase futura; il data layer lo predispone già).
- Nessuna autenticazione utente o multi-utente.
- Nessun conteggio per cicchetti diversi: **un solo contatore globale**, per il solo Mad Dog, su un tablet dedicato.
- Nessuna modalità kiosk totale (basta lo schermo sempre acceso).
- Nessun backend online nell'MVP: la persistenza remota (e con lei il vecchio requisito di consultabilità da remoto) slitta alla fase 2.

## Contesto d'uso

- Tablet Android montato a muro dietro/vicino al bancone, **orientamento landscape**, sempre acceso e sempre collegato alla corrente. Device: Samsung Galaxy Tab A8 (SM-X200), Android 14, schermo 10.5" 1920×1200.
- Lo usano i baristi (e occasionalmente i clienti) a ogni giro di Mad Dog.
- Ambiente: buio, luci calde, musica alta → UI scura ad alto contrasto, audio a tutto volume.

## Attori

- **Baristi**: tap di incremento/decremento. Ciommo, barista carismatico, ha un logo personale usato come easter egg.
- **Clienti**: guardano il numero, festeggiano i traguardi.

## Stack in sintesi

Flutter/Dart + Riverpod + persistenza locale (shared_preferences + sqflite), predisposta per il backend online in fase 2 (dettagli in ARCHITECTURE.md).

## Riferimenti asset

Tutti gli asset di brand sono descritti in UX_UI_SPEC.md → Asset. I file sorgente sono nella cartella di progetto.
