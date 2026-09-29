# Capitolo 1: la forma con i segnaposti (fase 4b, passo 2)

*Come è costruito il capitolo nella versione a forme semplici, da giocare prima della grafica. Il documento di livello resta `capitolo-01.md`; qui ci sono pianta, sequenza e le scelte che il documento non fissava, da confermare giocando.*

## Come si avvia

```
cd ~/Progetti/the-last-caravan && "$GODOT_PATH" --path . res://scenes/capitolo01/tregua.tscn
```

- Dal prologo si arriva da soli: dopo il titolo «Ne restano dieci» parte la Tregua.
- Singole stanze del dungeon: `"$GODOT_PATH" --path . res://scenes/capitolo01/carri_campo.tscn -- room=s4` (da `s1` a `s7`), con `difficulty=0` (facile), `1` o `2`.
- Tregua corta, per vedere l'avviso e l'arrivo di Iole: `-- truce_seconds=90`.
- F1 (o View sul gamepad): il pannello con i valori di Ottavia, delle creature, del boss e del capitolo, con i pulsanti per salvarli nei file.
- Esc o Menu: la pausa, con le pagine della bisaccia.

## Scene

| Scena | Cosa c'è |
|---|---|
| `scenes/capitolo01/tregua.tscn` | La Tregua: la pianura di 80 × 50 m intorno alla carovana ferma |
| `scenes/capitolo01/carri_campo.tscn` | Il dungeon: le sette stanze e il boss |
| `scenes/capitolo01/fine.tscn` | La fine: lo stoppino, la marcia, Anselmo, la schermata di fine capitolo e il titolo |

## La Tregua

- A sinistra (il Giorno) erba secca, pietre piatte crepate e arbusti bruciati; a destra (la Notte) la brina e lo stagno ghiacciato di 12 m. Al centro i mezzi del prologo: i tre carri-campo a sinistra della colonna, il camion-condominio, il mezzo di testa e alcuni mezzi generici. Il camion di Anselmo, in fondo a destra, per ora è un mezzo generico.
- All'inizio il Meridiano chiama la Tregua (con la tromba), poi parte la meridiana (7 minuti) con i due suggerimenti. C'è un salvataggio automatico.
- Ottavia parte senza pietre calde (decisione del 29 settembre).
- Oggetti:
  - la toppa di feltro vicino allo stagno, accanto al Pellegrino addormentato;
  - la toppa di tela da campo dietro i carri-campo, tra gli attrezzi;
  - tre pietre calde: alle bocchette, tra le pietre crepate e sul bordo dello stagno;
  - il seme nero sulla riva.
- Le tre comparse (Traslocante, Tessibuio, Brinaiolo) dicono la loro frase, in un fumetto, quando Ottavia passa vicino.
- Iole è vicino ai carri-campo, con il segnalino. Parlandole: tre battute, poi il dungeon. A un minuto dalla fine grida l'avviso un Voltacampi; a tempo scaduto è Iole a correre da Ottavia.

## Il dungeon: stanze-diorama

Ogni stanza è un diorama chiuso, alle misure del documento, in un suo punto del mondo; i passaggi sono dissolvenze (102). Una rampa o un ponte porta alla stanza vicina solo se la sua terrazza è girata nel verso giusto (decisione del 29 settembre). Le stanze 1 e 2 stanno insieme, perché nel carro si toccano davvero. Ogni leva gira la sua terrazza di 90° in senso orario in 1,5 s; la terrazza porta con sé piante, recinti, casse, creature e Ottavia.

| Stanza | Com'è costruita | Come si esce |
|---|---|---|
| 1. Il piede del primo carro (14 × 10) | Ruote, carter, sacchi, serbatoio, scala rotta, Iole. La prima leva, a terra, con «Usa la leva». | La terrazza bassa parte con la rampa verso sud: **una tirata** e la rampa scende nella stanza 1. |
| 2. La prima terrazza (20 × 9, a 2 m) | Spighe piegate, paletti. 5 Voltafaccia, 3 Cocci. La sua leva gira con lei. Suggerimento sulle bestie del Giorno. | **Altre due tirate**: la rampa punta a est e scende verso la stanza 3. A facile, nello stesso verso, il ponte alto porta alla stanza 4. |
| 3. L'erba alta (16 × 12) | Erba fino alla vita, tre radure. Uno sciame di Frinitori, 4 Raspageli nascosti. Suggerimento sull'erba alta. | Una scala a pioli, in fondo, sale alla stanza 4. |
| 4. La terrazza degli Specchietti (18 × 9, a 4,5 m) | Pietre piatte con 4 Specchietti al sole; una fila di cavoli a ventaglio sul lato sud. Ruggero sul bordo est. | **Prima tirata**: i cavoli si mettono a ovest delle pietre e le ombreggiano, così gli Specchietti si nascondono. **Seconda tirata**: la rampa (sul lato lungo) punta a sud e scende sulla stanza 5. |
| 4b. Ramo bonus (6 × 5), a medio e difficile | Dietro una siepe di tre steli da spezzare (3 colpi ciascuno): toppa di cuoio unto, pietra calda, paletto intagliato. A facile al posto della siepe c'è una parete. | Si torna dal pianerottolo. |
| 5. La terrazza bassa del secondo carro (20 × 9, a 2 m) | Cavoli, spighe, casse di raccolto; l'ombra del primo carro. 3 Foglioni, 3 Voltafaccia. | **Due tirate**: la terrazza torna allineata e il ponte basso si abbassa per sempre verso la stanza 6. |
| 6. La terrazza capovolta (16 × 9, a 2 m) | Inclinata, tuberi di brina, luce fredda. La leva è sotto una crosta di ghiaccio; Pia dorme nella gabbia di sei steli (3 colpi ciascuno). 2 Raspageli, 2 Cocci. | Rotta la crosta, **due tirate** girano la terrazza e la rimettono in piano: la sua apertura incontra la scala. Salvata Pia, la scala sale alla cima. |
| 7. La cima (16 m di diametro, a 5 m) | Il Foglione Radicato al centro; quattro leve sul bordo fisso; camera a 24 m. | Vinto il boss, la scena della fine. |

**Salvati e scorciatoie.** Legato alla corda (tasto interagire), ognuno aggiunge un nodo e poi torna da solo.
- **Ruggero** cala una scala di corda dal pianerottolo della stanza 4: da lì si torna all'ingresso. Dall'alto si abbassa anche il ponte verso la stanza 2.
- **Pia** scende lungo una corda legata al palo della stanza 6: anche da lì si torna all'ingresso.
- La prima volta compare il suggerimento «Chi salvi apre la strada del ritorno».

**Salvataggi e cadute.** Salvataggio automatico all'ingresso del dungeon. Se Ottavia cade in combattimento riparte dall'ingresso della stanza con la vita piena; nel boss il combattimento ricomincia da capo. Se cade da una terrazza nel vuoto torna all'ingresso della stanza, senza danni.

## Il boss (valori nel pannello F1, gruppo «Foglione Radicato, capitolo 1»)

- Circa 30 colpi base; tutti i danni passano dal fianco (×2), quindi circa 15 colpi sul fianco.
- **Le foglie.** Fuori dalle finestre le foglie chiuse lo coprono tutto intorno e i colpi rimbalzano. Dopo ogni rotazione si rigira verso il sole in 3 s (fase 1), 2 s (fase 2) o 1,2 s a scatti (fase 3). Mentre si rigira, le foglie sui fianchi si sollevano e lì si colpisce.
- **Fase 1:**
  - frustata di foglie a 120° davanti, 0,7 s di preavviso, 15 danni;
  - raffica di semi in linea retta verso Ottavia, 0,6 s di preavviso, 10 danni.
- **Fase 2:**
  - un attacco su due sono le radici: tre linee a 120° dal centro al bordo, una verso Ottavia, crepe per 0,8 s, 20 danni; si saltano;
  - all'inizio della fase arrivano dal bordo 2 Voltafaccia, una volta sola.
- **Fase 3:**
  - ogni 20 s apre le foglie al sole per 3 s e, se nessun colpo sul fianco lo interrompe, recupera 5 colpi di resistenza;
  - due rotazioni a meno di 2 s l'una dall'altra allungano la finestra di 1,5 s.
- **La fine.** Sconfitto, si piega, rotola giù dal carro e sparisce (circa 5 s).

## La fine

1. Ruggero, con Iole e Pia accanto: «Cinquant'anni a raddrizzarle, e servono storte. Tieni.»
2. Il Meridiano, con la tromba: «L'ombra si allunga! Si riparte!»
3. La colonna parte verso ovest; Ottavia raggiunge il retro del camion di Anselmo (con il segnalino), che dice le sue due battute. La lanterna nel menu prende il primo pezzo.
4. La schermata di fine capitolo: «Perde: lo scatto lungo.» «Impara: il passo a tempo.» Dal capitolo 2 la corsa dura meno (per ora il 75%, valore da provare).
5. Il titolo «Ne restano nove.»

## Scelte fatte qui, da confermare

1. **Numero di tirate:**
   - stanza 1: una;
   - stanza 2: due, poi a facile il ponte;
   - stanza 4: due;
   - stanza 5: due;
   - stanza 6: due.
   Il documento dice «alla seconda rotazione» solo per le stanze 2, 4 e 5.
2. **Stanza 6:** la terrazza parte allineata e inclinata, così dal ponte ci si arriva. Il documento la dice «girata e inclinata»: se fosse girata di traverso, dal ponte non ci si arriverebbe.
3. **Frinitori:** vanno piano verso Ottavia entro 6 m; altrimenti restano intorno al loro posto, spostati verso ovest. Il documento non dice come si muovono (`TODO-DESIGN #107`).
4. **Pellegrino di feltro:** una volta provocato insegue Ottavia fino a 14 m; poi si riaddormenta.
5. **Siepe del ramo bonus e gabbia di Pia:** steli da 3 colpi base, come quelli della stanza 6.
6. **Obiettivi a schermo:** i testi «Parla con Iole, vicino ai carri-campo» e «Porta lo stoppino ad Anselmo, sul retro del suo camion» li ho scritti io, sul modello del prologo.
7. **Boss:** sono miei l'intervallo tra gli attacchi (2,6 s), la direzione delle radici, il momento in cui arrivano i Voltafaccia, la durata del bagno di sole (3 s) e la regola per cui fuori dalle finestre i colpi rimbalzano da ogni lato.
8. **Musica:** nella Tregua per ora c'è la musica dell'accampamento del prologo; nel dungeon non c'è musica. I suoni nuovi arrivano al passo 5.
