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

- `asset/mezzi/`: i tre mezzi (122-124), partendo da 01 e 02 per la scala; poi il kit dei mezzi generici, da 09 a 12.
- `asset/personaggi/folla-generici/`: gli otto tipi della folla (121).
- `asset/personaggi/comparse-prologo/01-viste-sud-con-altezze.png`: i 12 personaggi del prologo.

## Indice

### `asset/mezzi/`: I tre mezzi della carovana (122-124)

Stato: **da valutare** (fase 4a, passo 1).

- `01-prova-di-scala-in-fila.png`: i tre mezzi in fila con i personaggi davanti, per la scala
- `02-prova-di-scala-camion-e-personaggi.png`: primo piano: camion-condominio e personaggi alla camera di gioco (20 m)
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

### `asset/personaggi/comparse-prologo/`: Comparse e personaggi del prologo (117-121, 21, 78, 81)

Stato: **da valutare** (fase 4a, passo 1).

- `01-viste-sud-con-altezze.png`: viste sud di Ottavia e dei 12 personaggi, ingrandite ×4, con l'altezza in pixel

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

### `asset/texture/`: Texture degli ambienti (54)

Stato: scelte in fase 2.

- `01-candidate-a-terreno-roccia.png`: candidate A: terreno e roccia
- `02-candidate-b-corteccia-foglie-stoffa.png`: candidate B: corteccia, foglie, stoffa
- `03-candidate-c-legno-metallo.png`: candidate C: legno e metallo
- `04-candidate-d-vedute.png`: candidate D: vedute
- `05-roccia-e-terra-in-scena.png`: roccia e terra nella scena
- `06-roccia-e-terra-in-scena-b.png`: roccia e terra nella scena, variante b

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

- `fasi/fase2-stile-definitivo/01-diorama-dimostrativo.mp4`: la scena dimostrativa della fase 2.
- `fasi/fase3-combattimento/01-capitolo-1-contro-9.mp4`: lo stesso combattimento al capitolo 1 e al 9 (fatto con il vecchio passo).
