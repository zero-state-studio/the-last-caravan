# Prompt della fase 4a: il Prologo in qualità definitiva

Rileggi `CLAUDE.md`, `docs/fasi.md`, `docs/decisioni.md`, `docs/stile.md`, e soprattutto `docs/livelli/prologo.md`, che descrive il livello stanza per stanza, battuta per battuta. Nella bibbia: 14-capitoli (106), 03-personaggi, 15-comparse, 16-mezzi, 17-interfaccia-e-audio, più 25, 33, 67, 88, 96, 103 e 105.

**Obiettivo:** il prologo completo, con grafica, animazioni, interfaccia, musica ed effetti definitivi, giocabile dall'inizio al titolo «Ne restano dieci». Serve a verificare che l'aspetto del gioco sia quello atteso, prima di costruire tutto il resto.
**Uscita:** l'ho giocato io sul Mac con il gamepad, e mi convince.

## Regole valide per tutta la fase

- **Prerequisito:** la fase 3 deve essere approvata. Se non lo è, fermati e dimmelo.
- **Il livello è già scritto.** Mappa, compiti, battute e suggerimenti sono in `docs/livelli/prologo.md`, in italiano e in inglese. Non inventarne altri: se manca qualcosa, chiedi.
- **Tutti i testi** passano dal sistema di traduzione, con un codice univoco per ogni battuta (59).
- **Voci:** solo per la narrazione di Ottavia e per la catena del verdetto, come prova provvisoria con voci già presenti nella libreria di ElevenLabs. Per Ottavia, e per l'ultima voce della catena, quella di Anselmo, proponimi tre voci ciascuno prima di generare. Tutte le altre battute restano solo testo.
- **Accessibilità:** il bagliore della porta rispetta l'opzione per ridurre lampi e bagliori (96).
- **Risparmio sulle direzioni.** Le animazioni che compaiono solo in una scena, come legare la corda o prendere le misure, bastano in una o due direzioni. Le comparse ferme ne hanno una o due. La folla ha solo quelle in cui si vede davvero (121).
- **Budget massimo della fase:** PixelLab 300 generazioni, Scenario 1.000 CU, Meshy 400 crediti, ElevenLabs 15.000 crediti. Prima di ogni gruppo di generazioni dimmi il costo stimato. Se il piano PixelLab del mese non basta, dimmelo prima di iniziare: valuteremo un mese al piano superiore.
- **Fermate:** dopo i passi 1, 3 e 5, e alla fine. Commit a ogni passo.

## Passo 0: Bibbia e piano

1. Aggiungi alla bibbia i file che ho messo in `docs/bibbia/`: 15-comparse, 16-mezzi e 17-interfaccia-e-audio, più il nuovo 14-capitoli, dove il prologo (106) ora è definito e rimanda a `docs/livelli/prologo.md`. L'indice è già aggiornato.
2. Nei file esistenti aggiungi solo dei rimandi: al 55 "vedi 125"; al 57 "vedi 126"; al 58 "per il prologo vedi 127".
3. Aggiorna il 68, Prima fetta giocabile: "In due tempi. Prima il prologo (fase 4a), che verifica la grafica e i comandi; poi i Carri-campo (fase 4b), che verificano dungeon, Tregua a tempo, boss e Salvati." Stato: Definito.
4. In `docs/fasi.md` dividi la fase 4 in 4a (il prologo) e 4b (i Carri-campo), e segna la 4a come fase corrente.
5. Registra tutto in `docs/decisioni.md`.

## Passo 1: L'aspetto di mezzi e personaggi

Prima di costruire, fammi vedere come saranno:
- **i tre mezzi (122-124):** un modello di prova per ciascuno, semplificato e con texture alla nostra densità, messo nel diorama accanto a Ottavia per giudicarne la scala;
- **le comparse del prologo:** lo Gnomone, Zelinda, Ruggero, Mirco, un Traslocante, le quattro varianti della folla, con la vista sud di ciascuno. Per Anselmo, Arold ed Enea usa le descrizioni di 03-personaggi.

Mostrami tutto in un foglio unico, e fermati.

## Passo 2: Animazioni di Ottavia

Sulla base di Ottavia v1 e dei valori approvati nella fase 3, in 8 direzioni: scatto, salto con atterraggio, arrampicata, colpo con la combinazione attuale, parata e deviazione, colpo subito, senza fiato. In una o due direzioni: legare la corda, porgere la mano ad Anselmo. Mostrami una GIF riassuntiva in griglia, come per la v1.

## Passo 3: Il piano dei Tessibuio e la porta (spazi 1 e 2)

Il piano buio con la sola luce della lanterna e l'incontro con Zelinda; la porta, il bagliore, la camera che si allontana sulla carovana intera, la narrazione. Fermati e dammi il comando per giocarlo.

## Passo 4: L'accampamento che smonta (spazio 3)

I cinque compiti nell'ordine di `docs/livelli/prologo.md`, uno per comando, con i suggerimenti a schermo; Ruggero sulla terrazza; la Coda da liberare; lo sciame di Brinacchi.

## Passo 5: La coda della colonna e il verdetto (spazi 4 e 5)

Il tratto breve di carovana in marcia (103), con tre o quattro mezzi visibili davanti; Mirco, la corda, il nodo che si aggiunge, il fiato che cala più in fretta nel ritorno; la catena delle voci, lo stacco su Arold ed Enea, Anselmo, la sagoma della lanterna nel menu, il titolo. Fermati e dammi il comando per giocare il prologo dall'inizio alla fine.

## Passo 6: Audio e interfaccia

La musica del prologo come descritta in 126, con il tema di Ottavia sulla ghironda; gli effetti sonori di 127; l'interfaccia di 125. Prima di generare la musica, proponimi i testi delle richieste per ElevenLabs.

## Passo 7: Consegna

- Il prologo completo, con il comando di avvio, provato anche in una finestra da 1280×800 come lo schermo di Steam Deck.
- Un video dall'inizio al titolo.
- Il riepilogo dei crediti spesi, e l'elenco degli asset in `docs/asset-log.csv`.
- La tua valutazione onesta: cosa funziona, cosa no, cosa cambieresti.

Poi fermati e chiedimi se la fase 4a è approvata.
