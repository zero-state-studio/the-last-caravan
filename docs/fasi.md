# Fasi di sviluppo

**Fase corrente: 4b**

Ogni fase finisce con un resoconto e con l'approvazione dell'autore. Non si passa alla fase successiva senza un ok esplicito. Quando una fase è approvata, aggiorna la riga "Fase corrente".

## Fase 0: Fondamenta
Verifica degli strumenti, progetto Godot vuoto con la struttura di cartelle, strumenti di verifica (controllo headless, screenshot), un test di connessione minimo per ogni servizio.
**Uscita:** tutto funziona, `docs/tecnica.md` compilato, primo commit.

## Fase 1: Prototipo visivo
Una piccola scena a diorama per trovare camera (50), misure degli sprite (49) e palette di base (51) guardando, non a tavolino. Sprite di prova di Ottavia, luce di tramonto perenne, sfocatura, pannello di regolazione.
**Uscita:** l'autore sceglie i valori, che vengono scritti nella bibbia.

## Fase 2: Stile definitivo
Immagini di riferimento nostre (52), modello personalizzato su Scenario, Ottavia definitiva in 8 direzioni con PixelLab, regole per i modelli 3D verificate (54), vegetazione in primo piano (53).
**Uscita:** una scena che ha l'aspetto del gioco finito.
**Stato (27 settembre 2026):** approvata. Scena dimostrativa: `scenes/proto/diorama.tscn`; screenshot `docs/screenshots/fasi/fase2-stile-definitivo/1[4-8]-demo-*.png`; video `docs/video/fasi/fase2-stile-definitivo/01-diorama-dimostrativo.mp4`.

## Fase 3: Prototipo di combattimento e progressione
Bastone, tempismo e posizione (33), progressione inversa (34), Enea che impara (81), lezioni di Ottavia (82), qualche creatura del Margine.
**Uscita:** il combattimento è divertente e la progressione inversa non frustra.
**Stato (28 settembre 2026):** approvata, prototipo chiuso. Diorama: `scenes/proto/diorama.tscn`; consegna `docs/fase3-consegna.md`; video `docs/video/fasi/fase3-combattimento/01-capitolo-1-contro-9.mp4`. Restano aperte: la tabella della progressione (`docs/progressione.md`, proposta), la crescita della forza nei capitoli avanzati e il colpo pesante con combinazione da 1.

## Fase 4: Prima fetta giocabile
In due tempi (68), con grafica, musica, effetti e testi IT/EN definitivi.

### Fase 4a: Il prologo
Il prologo completo (106, `docs/livelli/prologo.md`), dall'inizio al titolo «Ne restano dieci», per verificare la grafica e i comandi. Prompt: `docs/prompts/PROMPT-04.md`.
**Uscita:** l'autore l'ha giocato sul Mac con il gamepad, e lo convince.
**Stato (29 settembre 2026):** approvata. Avvio: `res://scenes/prologo/piano_tessibuio.tscn` (scena principale); consegna `docs/fase4a-consegna.md`; video `docs/video/capitoli/00-prologo/19-prologo-intero-collisioni.mp4`. Restano da fare in seguito: le frasi della folla (`TODO-DESIGN #121`), le voci inglesi, i salvataggi.

### Fase 4b: I Carri-campo
Il capitolo 1 (107, `docs/livelli/capitolo-01.md`), che verifica dungeon, la carovana come base (37), la Tregua a tempo (39), boss, Salvati e salvataggi (95), dall'inizio della Tregua al titolo «Ne restano nove». Prompt: `docs/prompts/PROMPT-05.md`.
**Uscita:** un pezzo di gioco che si potrebbe far provare a qualcuno; l'autore l'ha giocato sul Mac con il gamepad, e lo convince.
**Stato (29 settembre 2026):** in corso. Passi 0-4 fatti: bibbia, sistemi (banco nel diorama), capitolo con i segnaposti (`docs/livelli/capitolo-01-forma.md`), foglio dell'aspetto approvato con correzioni, grafica e animazioni definitive nel capitolo. Prossimo: passo 5, audio e interfaccia.

## Fase 5: Produzione
I capitoli da 2 a 10, uno alla volta, ciascuno con il suo dungeon, creature, boss e Salvati.

## Fase 6: Rifinitura e uscita
Doppiaggio (59), integrazione Steam (62), accessibilità (96), verifica Steam Deck, pagina Steam (72), dichiarazione AI (70).
