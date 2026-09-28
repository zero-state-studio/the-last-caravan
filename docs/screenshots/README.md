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

### `asset/personaggi/comparse-prologo/`: Comparse e personaggi del prologo (117-121, 21, 78, 81)

Stato: **da valutare** (fase 4a, passo 1).

- `01-viste-sud-con-altezze.png`: prima versione, superata dalla 02: viste sud di Ottavia e dei 12 personaggi, con l'altezza in pixel
- `02-personaggi-che-parlano-altezze-corrette.png`: i personaggi che parlano (117-120, Traslocante, Anselmo, Arold, Enea) con Zelinda, Ruggero, Mirco, Anselmo, Arold ed Enea rifatti alle altezze della bibbia; la riga gialla è la testa di Ottavia

### `asset/personaggi/folla-generici/`: Folla, otto tipi generici (121)

Stato: **da valutare** (fase 4a, passo 1).

- `01-otto-tipi-direzioni-di-marcia.png`: Ottavia e gli otto tipi, nelle direzioni della marcia verso ovest (sud, ovest, nord-ovest, sud-ovest), con l'altezza in pixel; la riga gialla è la testa di Ottavia
- `02-folla-accanto-al-mezzo-di-testa.png`: la folla accanto al mezzo di testa, alla distanza di gioco

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

- `capitoli/00-prologo/03-colonna-ruote-in-movimento.mp4`: **da valutare**. La colonna in marcia: ruote che girano, mezzi che ondeggiano, Generatori che battono (8 s)
- `capitoli/00-prologo/02-verdetto.mp4`: **da valutare**. Il verdetto, dalla catena delle voci al titolo (38 s)
- `capitoli/00-prologo/01-porta-e-narrazione.mp4`: **da valutare**. Dalla porta alla carovana intera, con la narrazione in sottotitoli, e il ritorno su Ottavia (50 s)
- `fasi/fase2-stile-definitivo/01-diorama-dimostrativo.mp4`: la scena dimostrativa della fase 2.
- `fasi/fase3-combattimento/01-capitolo-1-contro-9.mp4`: lo stesso combattimento al capitolo 1 e al 9 (fatto con il vecchio passo).
