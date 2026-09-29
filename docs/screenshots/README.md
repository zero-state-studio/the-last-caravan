# Screenshot e immagini di verifica

## Regola

Tre rami, secondo cosa mostra l'immagine:

- `asset/<tipo>/<nome>/`: l'aspetto di un asset preso da solo, fuori dal gioco (personaggi, mezzi, creature, texture, vegetazione, interfaccia). Ci finisce tutto ciò che serve per approvare un asset, di qualunque fase.
- `capitoli/<nn>-<nome>/`: il gioco vero, dentro un livello (`00-prologo`, `01-carri-campo`, ...). Si usa dalla fase 4a in poi.
- `fasi/fase<n>-<nome>/`: prove tecniche, prototipi, confronti di parametri: servono a decidere, non mostrano il gioco finito.
- `catture/`: le catture fatte dal pannello F1 del diorama, con data e ora nel nome. Vanno spostate e rinominate con questa regola prima del commit.

Nomi dei file: `NN-descrizione.png`, in italiano, minuscolo, parole separate da trattini. `NN` è l'ordine di lettura dentro la cartella (01, 02, ...). Niente data e niente fase nel nome: le dice la cartella, e la data sta in Git. Le varianti aggiungono `-a`, `-b`; un file di impostazioni ha lo stesso nome dell'immagine (`01-camera-40-gradi.json`).

Stato: ogni cartella qui sotto dice se è approvata, storica o **da valutare**. Quando l'autore approva, si aggiorna la riga. Ogni nuova immagine importante ha una riga in questo indice. I video seguono gli stessi rami in `docs/video/`.

## Da valutare adesso

- `asset/mezzi/`: i tre mezzi (122-124), partendo da 01 e 02 per la scala; poi il kit dei mezzi generici, da 09 a 12; da 13 i mezzi in movimento.
- `asset/personaggi/folla-generici/`: gli otto tipi della folla (121).
- `asset/ui/`: interfaccia (125): caratteri, elementi dell'HUD, menu.
- `asset/personaggi/ottavia-v1/14-animazioni-fase4a/tutte_griglia.gif` e `15-fotogrammi-animazioni-fase4a.png`: le animazioni di Ottavia del passo 2.
- `capitoli/00-prologo/` e i video `docs/video/capitoli/00-prologo/`: il prologo dei passi 3-5 (piano dei Tessibuio, porta e narrazione, accampamento, colonna, verdetto).
- `asset/personaggi/comparse-prologo/02-personaggi-che-parlano-altezze-corrette.png`: i personaggi del prologo, alle altezze giuste.

## Indice

### `capitoli/00-prologo/`: Prologo, spazi 1 e 2 (106)

Stato: **da valutare** (fase 4a, passi 3-5).

- `01-piano-buio-risveglio.png`: il risveglio al buio, con il primo suggerimento («Apri la lanterna»)
- `02-piano-lanterna-aperta.png`: la lanterna aperta sul piano dei Tessibuio, con il suggerimento «Muoviti»
- `03-zelinda-chiudi-la-lanterna.png`: Zelinda tesse al buio e chiede di chiudere la lanterna
- `04-porta-sul-retro.png`: in fondo al piano, la scala e la luce che filtra dalla porta sul retro
- `05-uscita-bagliore.png`: fuori dalla porta, il bagliore del tramonto (attenuato dall'opzione dei lampi, 96)
- `06-salita-sulla-carovana.png`: la camera sale sopra Ottavia
- `07-carovana-intera-narrazione.png`: la carovana intera mentre Ottavia racconta il mondo
- `08-ritorno-su-ottavia.png`: la camera torna su Ottavia e i comandi tornano al giocatore
- `09-code-da-saltare.png`: passo 4. Dopo il primo richiamo dello Gnomone, le file di Code nella brina da saltare («Salta»)
- `10-carro-campo-ruggero.png`: il carro-campo con la parete da scalare («Arrampicati») e Ruggero che dorme sulla terrazza
- `11-coda-piantata-traslocante.png`: la Coda piantata nel ghiaccio, le croste e i cespugli da rompere, il Traslocante
- `12-sciame-di-brinacchi.png`: lo sciame di Brinacchi (B1) dopo la Coda liberata («Colpisci», poi «Para al momento giusto»)
- `13-colonna-in-marcia.png`: passo 5. La carovana in marcia verso ovest, Ottavia in coda
- `14-mirco-nella-brina.png`: Mirco rimasto indietro nella brina, a guardare il buio
- `15-catena-delle-voci.png`: il verdetto arriva di voce in voce
- `16-testa-della-colonna.png`: la testa della colonna: Arold non si volta, Enea sì, lo Gnomone sulla meridiana
- `17-anselmo-la-mano.png`: Anselmo, l'ultima voce, chiede la mano per prenderle le misure
- `18-sagoma-della-lanterna.png`: la sagoma vuota della lanterna del congedo (88), disegno provvisorio
- `19-titolo-ne-restano-dieci.png`: il titolo su nero
- `20-buco-nel-telo-prima-e-dopo.png`: **da valutare**. Il telo della casa nella veduta d'insieme: prima (a sinistra) un buco retinato, la trasparenza di primo piano (53) ferma nell'origine del mondo; dopo (a destra) pieno
- `21-catena-sopra-chi-parla.png`: **da valutare**. Le cinque battute della catena, ognuna sopra chi la dice: le prime al bordo sinistro (chi parla è più avanti, verso la testa), l'ultima sopra Anselmo
- `22-veduta-carovana-e-citta-morta.png`: **da valutare**. La veduta d'insieme nuova: carovana più grande nel quadro, città morta sullo sfondo
- `23-segnale-e-obiettivo.png`: **da valutare**. Il bagliore sulle tende e l'obiettivo sopra il suggerimento
- `24-folla-che-gira.png`: **da valutare**. La folla che cammina nell'accampamento, quattro momenti a 5 s l'uno dall'altro
- `25-strada-verso-mirco-con-rocce.png`: **da valutare**. La strada verso Mirco: massi e un muro in rovina da aggirare, Brinacchi con il bagliore di brina (a sinistra), la freccia verso Mirco
- `26-vicino-a-mirco-cala-la-notte.png`: **da valutare**. Vicino a Mirco la luce cala, come se arrivasse la notte; Mirco con il bagliore dell'obiettivo
- `27-ballatoio-scala-e-ruggero.png`: **da valutare**. Il ballatoio sulla testata del carro-campo, accanto ai serbatoi, con la scala; Ruggero dorme seduto
- `28-croste-di-ghiaccio.png`: **da valutare**. Le croste da rompere, ora di ghiaccio bianco-azzurro
- `29-rocce-da-saltare.png`: **da valutare**. Le file di rocce basse da saltare, al posto delle Code
- `30-apertura-su-montagne-e-citta.png`: **da valutare**. L'apertura della narrazione: la camera guarda in alto, montagne vicine e ben visibili, città morta, carovana in basso; poi scende sulla carovana
- `31-veduta-citta-vicina.png`: **da valutare**. La veduta sulla carovana con la città morta vicina, senza la fascia vuota
- `32-campo-di-brina-vicino-a-mirco.png`: **da valutare**. La zona di Mirco non più piatta e uniforme: brina a chiazze con terra e ghiaia, massi, arbusti gelati, tronchi, cumuli di brina e schegge di ghiaccio
- `33-chiusura-campo-lungo-vestito.png`: **da valutare**. La chiusura: la camera si allarga sulla colonna in cammino, con la pianura vestita (erba, rocce, alberi secchi, ruderi) e il terreno mosso ai lati della strada; niente più sagoma della lanterna
- `34-lo-sguardo-arriva-a-mirco.png`: **da valutare**. Dopo il dialogo con la mamma la camera arriva fino a Mirco, ingrandito 2 volte


### `asset/mezzi/`: I tre mezzi della carovana (122-124)

Stato: approvato (fase 4a, passo 1).

- `01-prova-di-scala-in-fila.png`: i tre mezzi in fila con Ottavia, per la scala (camion-condominio da 20 m)
- `02-prova-di-scala-camion-e-personaggi.png`: primo piano del camion-condominio (20 × 12 m) con Ottavia
- `03-camion-condominio-quattro-lati.png`: camion-condominio da quattro lati (sud, est, nord, dall'alto)
- `04-carro-campo-quattro-lati.png`: carro-campo da quattro lati
- `05-mezzo-di-testa-quattro-lati.png`: mezzo di testa da quattro lati
- `06-camion-condominio-concetto.png`: concetto del camion-condominio (da cui è nato il 3D)
- `07-carro-campo-concetto.png`: concetto del carro-campo
- `08-mezzo-di-testa-concetto.png`: concetto del mezzo di testa
- `09-kit-i-25-mezzi.png`: i 25 mezzi della carovana: in basso a sinistra i tre tipi in cui si entra, poi i 22 generici montati dal kit
- `10-kit-da-vicino-con-ottavia.png`: alcuni mezzi generici alla distanza di gioco, con Ottavia
- `11-kit-concetti-dei-12-moduli.png`: i concetti dei 12 moduli (pianali, Generatore, Ali, Code, piani, terrazza, serbatoio, tenda, carico, casetta)
- `12-kit-moduli-quattro-lati.png`: i 12 moduli in 3D, da quattro lati
- `13-ruote-che-girano-a-un-secondo.png`: **da valutare**. Le ruote di un mezzo in marcia, a un secondo di distanza: i raggi hanno girato
- `15-raggi-che-girano.png`: **da valutare**. Le ruote di un mezzo in marcia a mezzo secondo l'una dall'altra: ora girano anche raggi e mozzo
- `14-code-che-serpeggiano.png`: **da valutare**. Le Code di un mezzo in marcia a mezzo secondo l'una dall'altra: pendono dal retro, strisciano verso est e serpeggiano

### `asset/personaggi/comparse-prologo/`: Comparse e personaggi del prologo (117-121, 21, 78, 81)

Stato: **da valutare** (fase 4a, passo 1).

- `01-viste-sud-con-altezze.png`: prima versione, superata dalla 02: viste sud di Ottavia e dei 12 personaggi, con l'altezza in pixel
- `03-ruggero-si-addormenta.png`: **da valutare**. L'animazione nuova di Ruggero: si siede e si addormenta (gli ultimi fotogrammi sono il sonno, al contrario il risveglio)
- `02-personaggi-che-parlano-altezze-corrette.png`: i personaggi che parlano (117-120, Traslocante, Anselmo, Arold, Enea) con Zelinda, Ruggero, Mirco, Anselmo, Arold ed Enea rifatti alle altezze della bibbia; la riga gialla è la testa di Ottavia

### `asset/personaggi/folla-generici/`: Folla, otto tipi generici (121)

Stato: **da valutare** (fase 4a, passo 1).

- `01-otto-tipi-direzioni-di-marcia.png`: Ottavia e gli otto tipi, nelle direzioni della marcia verso ovest (sud, ovest, nord-ovest, sud-ovest), con l'altezza in pixel; la riga gialla è la testa di Ottavia
- `02-folla-accanto-al-mezzo-di-testa.png`: la folla accanto al mezzo di testa, alla distanza di gioco
- `03-colori-dei-mestieri-sud.png`: **da valutare**. Gli otto tipi (colonne) nei sei mestieri (righe, dall'alto): senza tinta, Brinaioli, Tessibuio, Voltacampi, Traslocanti, Specchianti, Nodai; vista sud
- `04-colori-dei-mestieri-sud-ovest.png`: **da valutare**. Lo stesso nella vista sud-ovest della marcia
- `05-camminate-verso-est.png`: **da valutare**. Le camminate nuove: ovest (già fatta), est, nord-est, sud-est per tre tipi

### `asset/personaggi/ottavia-v1/`: Ottavia v1 (19, 36, 49)

Stato: approvata in fase 2.

- `01-vista-sud-quattro-varianti.png`: quattro varianti della vista sud
- `02-vista-sud-gancio-prova-a.png`: gancio del bastone, prova a
- `03-vista-sud-gancio-prova-b.png`: gancio del bastone, prova b
- `04-vista-sud-gancio-contorno-zoom.png`: contorno del gancio, ingrandito
- `05-vista-sud-definitiva.png`: vista sud definitiva
- `06-otto-direzioni-grezze.png`: 8 direzioni grezze di PixelLab
- `07-otto-direzioni.png`: 8 direzioni ritoccate
- `08-schiena-sbiadita.png`: schiena sbiadita dal sole (98)
- `09-fotogrammi-attesa.png`: fotogrammi di attesa
- `10-fotogrammi-camminata.png`: fotogrammi di camminata
- `11-spritesheet.png`: spritesheet finale
- `12-gif-attesa-e-camminata`: GIF di attesa e camminata, una per direzione più la griglia
- `13-palette-in-scena.png`: palette di Ottavia nella scena
- `14-animazioni-fase4a/`: **da valutare** (fase 4a, passo 2). GIF ingrandite ×4 delle nuove animazioni: `tutte_griglia.gif` (una riga per animazione, otto direzioni: scatto, salto, arrampicata, combinazione, parata, colpo subito, senza fiato, corda, mano) e una griglia per animazione (`run`, `jump`, `climb`, `combo`, `parry`, `hurt`, `breathless`, `tie_rope`, `give_hand`)
- `15-fotogrammi-animazioni-fase4a.png`: **da valutare**. I fotogrammi uno per uno, due direzioni per animazione

### `asset/vegetazione/`: Kit di vegetazione (101)

Stato: approvato in fase 2.

- `01-kit-concetti.png`: concetti
- `02-kit-modelli.png`: modelli
- `03-kit-carte-erba.png`: carte dell'erba
- `04-kit-vista-sud.png`: vista sud del kit
- `05-kit-vista-camera.png`: kit alla camera di gioco
- `06-kit-insieme.png`: kit nella scena
- `07-atlanti.png`: atlanti delle texture
- `08-primo-giro-prima.png`: primo giro, prima
- `09-primo-giro.png`: primo giro
- `10-primo-giro-zoom.png`: primo giro, ingrandito

### `asset/rovine/`: Rovine dello sfondo del prologo

Stato: **da valutare** (fase 4a, passo 3).

- `02-concetti-citta-morta.png`: **da valutare**. I concetti delle quattro rovine nuove: facciata, ciminiera, palazzo sventrato, ponte crollato
- `01-concetti-delle-rovine.png`: casa diroccata, torre spezzata, muro con arco (in scena: `capitoli/00-prologo/07`)

### `asset/texture/`: Texture degli ambienti (54)

Stato: scelte in fase 2.

- `01-candidate-a-terreno-roccia.png`: candidate A: terreno e roccia
- `02-candidate-b-corteccia-foglie-stoffa.png`: candidate B: corteccia, foglie, stoffa
- `03-candidate-c-legno-metallo.png`: candidate C: legno e metallo
- `04-candidate-d-vedute.png`: candidate D: vedute
- `05-roccia-e-terra-in-scena.png`: roccia e terra nella scena
- `06-roccia-e-terra-in-scena-b.png`: roccia e terra nella scena, variante b
- `07-strada-ghiaia-terra-crepata.png`: fase 4a, texture nuove del terreno ripetute 2×2 (strada sterrata e ghiaia usate; terra crepata scartata)

### `asset/modello-stile/`: Modello personalizzato di Scenario

Stato: fase 2.

- `01-immagini-di-addestramento.png`: immagini di addestramento (solo nostre)
- `02-confronto-epoche.png`: confronto tra epoche
- `03-confronto-pesi.png`: confronto tra pesi
- `04-prove.png`: prove
- `05-prove-1024.png`: prove a 1024 px
- `06-risultati-utili-con-palette.png`: risultati utili, riportati alla palette

### `fasi/fase0-fondamenta/`: Fase 0

Stato: approvata.

- `01-scena-di-prova.png`: scena di prova: cielo, sole, cubo, etichetta tradotta

### `fasi/fase1-prototipo-visivo/`: Fase 1

Stato: approvata (resoconto in `docs/fase1-prototipo.md`).

- `01-camera-40-gradi.png`: camera a 40° (con le impostazioni .json)
- `02-camera-50-gradi.png`: camera a 50° (scelta)
- `03-camera-60-gradi.png`: camera a 60°
- `04-billboard-confronto.png`: billboard a confronto
- `05-billboard-vicino-al-muro.png`: billboard vicino al muro
- `06-luce-su-ottavia.png`: luce su Ottavia
- `07-ombra.png`: ombra
- `08-viraggio-palette.png`: viraggio della palette
- `09-pannello-f1.png`: pannello F1

### `fasi/fase2-stile-definitivo/`: Fase 2

Stato: approvata.

- `01-densita-30.png`: densità 30 px/m
- `02-densita-60.png`: densità 60 px/m
- `03-densita-30-contro-60.png`: 30 contro 60 px/m (scelta: 30)
- `04-densita-30-contro-60-zoom.png`: 30 contro 60 px/m, ingrandito
- `05-billboard-muri.png`: billboard e muri
- `06-billboard-ombre.png`: billboard e ombre
- `07-dissolvenza-albero.png`: dissolvenza dell'albero in primo piano
- `08-dissolvenza-retino.png`: retino della dissolvenza
- `09-lanterna.png`: lanterna
- `10-lanterna-maschera.png`: maschera di emissione della lanterna
- `11-lanterna-ombre.png`: ombre della lanterna
- `12-luce-di-zona.png`: luce di zona
- `13-terreno-tinta.png`: tinta del terreno
- `14-demo-insieme.png`: scena dimostrativa, insieme
- `15-demo-primo-piano.png`: scena dimostrativa, primo piano
- `16-demo-verso-la-notte.png`: scena dimostrativa, verso la Notte
- `17-demo-verso-la-notte-intensita-2.png`: verso la Notte, intensità 2
- `18-demo-ombra-profonda.png`: ombra profonda

### `fasi/fase3-combattimento/`: Fase 3

Stato: approvata (resoconto in `docs/fase3-consegna.md`).

- `01-stanze.png`: stanze
- `02-combattimento.png`: combattimento
- `03-vita-e-fiato.png`: vita e fiato
- `04-lezione-della-parata.png`: lezione della parata
- `05-creature.png`: creature
- `06-raspagelo.png`: Raspagelo
- `07-boss.png`: boss
- `08-barra-vita-nemici.png`: barra di vita dei nemici
- `09-fine-capitolo.png`: schermata di fine capitolo
- `10-salto.png`: salto

### `docs/video/`

- `capitoli/00-prologo/17-prologo-intero-meridiano.mp4`: **da valutare (con le cuffie)**. Il Meridiano al posto dello Gnomone, Zelinda con la voce nuova, lo sguardo che arriva fino a Mirco, la chiusura senza la sagoma della lanterna e con la frase sulla crudeltà, la pianura vestita nel campo lungo (6 min 56 s)
- `capitoli/00-prologo/16-prologo-intero-ultima-revisione.mp4`: superato da 17. Zelinda e Mirco con la voce, la mamma che chiama «Ottavia!», i due che continuano a camminare con la camera che si allarga, la chiusura veloce e ironica di Ottavia (6 min 38 s)
- `capitoli/00-prologo/15-prologo-intero-voci-nuove.mp4`: superato da 16. Come il 14, con le voci rifatte: «Serra fila» staccato, Anselmo con la voce nuova, la mamma di Mirco più agitata; la mamma che si unisce alla colonna e la folla che cammina al passo giusto (6 min 52 s)
- `capitoli/00-prologo/14-prologo-intero-revisione-3.mp4`: superato da 15. Terza revisione: motivi dei compiti a voce, Ruggero scorbutico, la mamma di Mirco, le frasi al ritorno, il verdetto nuovo di Anselmo e la chiusura sulle Tregue e la lanterna (6 min 51 s)
- `capitoli/00-prologo/13-prologo-intero-revisione-2.mp4`: superato da 14. Il prologo intero dopo la seconda revisione: sfondo, rocce, scala e Ruggero, Brinacchi battibili, strada lunga verso Mirco con la notte che cala, verdetto di Anselmo (5 min 21 s)
- `capitoli/00-prologo/11-prologo-intero-folla-guida-citta-morta.mp4`: superato da 13. Il prologo intero con la folla che gira, il segnale di dove andare e la città morta
- `capitoli/00-prologo/10-prologo-intero-dall-inizio-al-titolo.mp4`: **da valutare**. Tutto il prologo giocato dal pilota automatico, a 1280×800 con audio, dal risveglio al titolo (4 min 2 s)
- `capitoli/00-prologo/09-verdetto-cinque-voci-ed-enea.mp4`: **da valutare (con le cuffie)**. Il verdetto con la catena di cinque voci; Enea cammina accanto ad Arold, poi si ferma e si volta (60 s)
- `capitoli/00-prologo/08-porta-e-narrazione-senza-buco.mp4`: **da valutare**. Come 06, senza il buco nel telo della casa
- `capitoli/00-prologo/07-verdetto-con-audio.mp4`: superato da 09 (catena di quattro voci, Enea che scivola). Il verdetto: la musica tace, la catena di voci sempre più vicine, Anselmo, il titolo sulla prima frase del tema (50 s)
- `capitoli/00-prologo/06-porta-e-narrazione-con-audio.mp4`: superato da 08 (buco nel telo). Porta, tema di Ottavia, narrazione con la voce, poi la versione leggera dell'accampamento, folla e Generatori (58 s)
- `capitoli/00-prologo/05-risveglio-al-buio-con-audio.mp4`: **da valutare (con le cuffie)**. Il risveglio nel buio: cigolio della branda, respiro, battito attutito dei Generatori (11 s)
- `capitoli/00-prologo/04-colonna-code-che-serpeggiano.mp4`: **da valutare**. Le Code da vicino, mentre il mezzo avanza (4 s)
- `capitoli/00-prologo/03-colonna-ruote-in-movimento.mp4`: **da valutare**. La colonna in marcia: ruote che girano, mezzi che ondeggiano, Generatori che battono (8 s)
- `capitoli/00-prologo/02-verdetto.mp4`: **da valutare**. Il verdetto, dalla catena delle voci al titolo (38 s)
- `capitoli/00-prologo/01-porta-e-narrazione.mp4`: **da valutare**. Dalla porta alla carovana intera, con la narrazione in sottotitoli, e il ritorno su Ottavia (50 s)
- `fasi/fase2-stile-definitivo/01-diorama-dimostrativo.mp4`: la scena dimostrativa della fase 2.
- `fasi/fase3-combattimento/01-capitolo-1-contro-9.mp4`: lo stesso combattimento al capitolo 1 e al 9 (fatto con il vecchio passo).

### `asset/ui/`: Interfaccia (125)

- `01-caratteri-pixel-tre-finalisti.png`: **da valutare**. Pixelify Sans, Jersey 10 e VT323 (licenza SIL OFL) a 1280×800: dialogo, lettere accentate, suggerimento, titolo
- `02-caratteri-pixel-sette-provati.png`: tutti i sette caratteri provati, compresi gli scartati (Departure Mono, Tiny5, Press Start 2P, Silkscreen)
- `03-hud-meridiana-suggerimento-dialogo.png`: **da valutare**. L'interfaccia in gioco: meridiana di vita (arco esterno) e fiato (interno) in basso a sinistra, suggerimento con l'icona del tasto, dialogo con il nome
- `04-menu-di-pausa-con-la-lanterna.png`: **da valutare**. Il menu di pausa con la lanterna del congedo a 3 pezzi su 10 (per la prova), e la nuova opzione per la dimensione del testo
- `05-meridiana-ingrandita.png`: la meridiana ingrandita 4 volte, per vedere i pixel
- `06-corda-ingrandita.png`: la corda dei salvati ingrandita 4 volte
- `07-hud-con-jersey-10.png`: **da valutare**. L'interfaccia in gioco con il carattere scelto, Jersey 10 (28 px)
- `08-menu-di-pausa-con-jersey-10.png`: **da valutare**. Il menu di pausa con Jersey 10, allargato per il testo più grande
- `09-jersey-10-ingrandito.png`: il dialogo ingrandito 3 volte: pixel pieni e regolari
