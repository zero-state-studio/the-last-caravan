# Prompt della fase 4b: il Capitolo 1, I Carri-campo

Rileggi `CLAUDE.md`, `docs/fasi.md`, `docs/decisioni.md`, `docs/stile.md`, e soprattutto `docs/livelli/capitolo-01.md`, che descrive il capitolo stanza per stanza: luce, oggetti, creature con i loro valori, boss, battute in italiano e inglese, musica, suoni, asset e lista di controllo finale. Nella bibbia: 18-bisaccia (128-131), 14-capitoli (107), 15-comparse, 16-mezzi, 17-interfaccia-e-audio.

**Obiettivo:** il capitolo 1 completo, in qualità definitiva, dall'inizio della Tregua al titolo «Ne restano nove». Con il prologo forma la prima fetta giocabile (68).
**Uscita:** l'ho giocato io sul Mac con il gamepad, e mi convince.

## Regole valide per tutta la fase

- **Prerequisito:** la fase 4a deve essere approvata.
- **Il capitolo è già scritto.** Stanze, creature, valori, oggetti, battute e suggerimenti sono in `docs/livelli/capitolo-01.md`. Se manca un'informazione, chiedi e non inventare. I numeri sono valori di partenza: mettili in un file di risorse regolabile e nel pannello F1.
- **Prima la forma, poi la grafica.** Costruisci tutte le stanze con forme semplici e segnaposti, falle giocare a me, e solo dopo la mia approvazione passa alla grafica definitiva. Così, se una stanza non funziona, la cambiamo prima di spendere crediti.
- **Sistemi riusabili.** Bisaccia, pietre calde, ricordi, meridiana, piattaforme girevoli e scorciatoie dei Salvati torneranno in altri capitoli: costruiscili in modo generale, non solo per questo.
- **Risparmio sulle direzioni,** come indicato nella sezione 10 del documento.
- **Budget massimo della fase:** PixelLab 200 generazioni, Scenario 600 CU, Meshy 300 crediti, ElevenLabs 8.000 crediti. Prima di ogni gruppo di generazioni dimmi il costo stimato.
- **Fermate:** dopo i passi 2 e 3, e alla fine. Commit a ogni passo.

## Passo 0: Bibbia e piano

1. Aggiungi `docs/bibbia/18-bisaccia.md` e il nuovo `14-capitoli.md`, in cui il capitolo 1 (107) ora è definito, impara il passo a tempo invece della deviazione, e il capitolo 5 (111) impara il salto con il bastone. L'indice è già aggiornato.
2. Nei file esistenti:
   - al 104, la toppa "durata della lanterna" diventa "durata della lanterna alzata" (131);
   - al 37, "si migliora l'equipaggiamento" diventa "si cuciono e si scuciono le toppe (128)";
   - al 34, la deviazione è disponibile fin dal prologo, e il capitolo 1 insegna il passo a tempo.
3. In `docs/fasi.md` segna la 4b come fase corrente.
4. Registra tutto in `docs/decisioni.md`.

## Passo 1: I sistemi

Costruisci e prova nel diorama esistente, prima di toccare il capitolo:
- la bisaccia con le sue quattro pagine (128), le toppe da cucire e scucire, le pietre calde (129), i ricordi (130);
- la meridiana della Tregua (125), con l'avviso a un minuto, il blocco dentro il dungeon e l'arrivo di Iole a tempo scaduto;
- le piattaforme girevoli con la leva, che portano con sé oggetti e creature;
- la scorciatoia che si apre dopo un salvataggio, con il nodo che si aggiunge alla corda;
- il ritorno all'ingresso della stanza quando Ottavia cade (105).

## Passo 2: Il capitolo con i segnaposti

Tutta la Tregua e le sette stanze con forme semplici, alle misure del documento: leve, rampe, ponti, gabbia, arena con le quattro leve. Creature e boss con i comportamenti e i valori del documento, ma con sprite e modelli provvisori. Le tre difficoltà, con il ponte e il ramo bonus. Battute e suggerimenti già nel sistema di traduzione.

**Fermati qui**, e dammi il comando per giocarlo. Guarderò se le stanze funzionano, se le leve si capiscono e se il boss è giusto.

## Passo 3: L'aspetto

Prima di generare tutto, un foglio unico con:
- il modello di prova del carro-campo e della cima;
- le tre colture con le loro varianti;
- Iole e Pia, viste da sud;
- le sei creature del capitolo e il Pellegrino di feltro, viste da sud;
- una bozza del Foglione Radicato in 3D, accanto a Ottavia per la scala.

**Fermati qui** per la mia approvazione.

## Passo 4: Grafica, animazioni e scene

Genera e sostituisci tutto il definitivo: ambienti, colture, personaggi, creature, il boss con le foglie animate in Godot, le scene brevi (Ruggero che intreccia lo stoppino, il Foglione che rotola via, la consegna ad Anselmo). Luce e viraggio come nella sezione 1 del documento.

## Passo 5: Audio e interfaccia

Musica ed effetti della sezione 9, con le richieste per ElevenLabs da mostrarmi prima di generare; le icone degli oggetti, le pagine della bisaccia, la schermata di fine capitolo.

## Passo 6: Consegna

- Il prologo e il capitolo 1 giocabili di seguito, anche nella versione esportata per Mac.
- Un video del capitolo.
- La lista di controllo della sezione 11 del documento, voce per voce, con l'esito.
- Il riepilogo dei crediti e l'elenco degli asset in `docs/asset-log.csv`.
- La tua valutazione onesta: cosa funziona, cosa no, cosa cambieresti.

Poi fermati e chiedimi se la fase 4b è approvata.
