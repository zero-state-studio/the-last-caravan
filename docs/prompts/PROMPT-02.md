# Prompt della fase 2: Stile definitivo

Rileggi `CLAUDE.md`, `docs/fasi.md`, `docs/decisioni.md` e in particolare `docs/bibbia/08-arte.md` (46-54, 98-101), `docs/bibbia/03-personaggi.md` (19) e `docs/bibbia/06-dungeon.md` (83, i Carri-campo).

**Obiettivo della fase:** una scena che abbia l'aspetto del gioco finito. Diorama 3D denso, texture pixel art tutte alla stessa densità, Ottavia v1 integrata, luce di tramonto perenne con ombre fredde.

**Regola di lavoro:** esegui un passo alla volta e fermati alla fine di ognuno con il resoconto e le domande numerate. Non iniziare il passo successivo senza il mio ok.

## Regole valide per tutta la fase

- **Riferimenti.** Mai usare immagini di altri giochi come input, riferimento o materiale di addestramento, e mai citare altri giochi, studi o il termine "HD-2D" nei prompt dei servizi. Descrivi lo stile con parole nostre: "3D diorama, low-poly models with low-resolution pixel-art textures, nearest filtering, soft warm sunset light, cool blue-violet shadows".
- **Densità di pixel.** Tutte le texture del mondo hanno la stessa densità di pixel per metro dei personaggi (49). Il valore esatto va ricavato al passo 0 e scritto in `docs/tecnica.md`.
- **Viraggio dei colori.** Si calcola sulla posizione nel mondo, non sullo schermo. Ogni zona ha un valore di vicinanza alla Notte o al Giorno (16), e dentro la zona il viraggio cresce lungo l'asse ovest-est. Virano terreno, piante e modelli 3D; personaggi, creature e interfaccia no, ma ricevono la luce della scena. Il freddo viene soprattutto da ombre e luce ambientale blu-viola; intensità del viraggio ferma a 1.
- **Luce e orientamento.** Giorno fisso a ovest, cioè a sinistra dello schermo; sole da sinistra e leggermente dal lato della camera (100). Camera prospettica a 50°, 20 m, campo visivo 35° (50). Billboard pieno (99).
- **Budget massimo della fase:** Scenario 1.500 unità di calcolo, Meshy 400 crediti, PixelLab 60 generazioni, ElevenLabs niente. Soglie di conferma come in `CLAUDE.md`. Per l'addestramento del modello Scenario chiedimi sempre prima, con il costo stimato.

## Passo 0: Punto di partenza

1. Controlla lo stato del compito "Ottavia v1": direzioni, animazioni, file in `assets/sprites/ottavia/`. Se manca qualcosa, dimmelo prima di proseguire.
2. Misura i pixel per metro di Ottavia v1 (tela 64×64, altezza reale 1,6 m) e scrivili in `docs/tecnica.md` come costante del progetto.
3. Aggiungi in `docs/tecnica.md` una lista di controllo per ogni texture: densità di pixel, filtro nearest, mipmap, compressione, dimensioni.
4. **Materiale di prova: archivialo, non cancellarlo.** Sposta il foglio di prova di Ottavia (`assets/sprites/proto/ottavia_test_sheet.png`) e la scena di prova della fase 0 in `source-assets/archivio/`, che Godot non importa. Togli dal progetto ogni riferimento a quei file, aggiorna i percorsi citati in `docs/` e aggiungi la nota "archiviato" alle loro righe in `docs/asset-log.csv`.

## Passo 1: Guida di stile

Crea `docs/stile.md` con:
- **Palette di base** di 24-32 colori: una rampa calda per la luce, una fredda per le ombre, e le varianti per il centro del Crepuscolo, verso la Notte e verso il Giorno (51). Esportala anche come immagine e come palette per Aseprite, in `assets/palette/`.
- **Contorni:** personaggi e creature con contorno scuro; ambienti e modelli 3D senza contorno. Se proponi altro, spiegami perché.
- **Luce:** colore e angolo del sole, colore delle ombre, luce ambientale, valori della sfocatura ripresi dalla fase 1.
- **Materiali:** come devono essere fatti legno, pietra, foglie, stoffa e metallo alla nostra densità di pixel. Due o tre righe per materiale.

Mostrami la palette ingrandita accanto a Ottavia v1, e fermati.

## Passo 2: Immagini di riferimento nostre (52)

Con Scenario, usando i modelli di base e senza addestrare nulla, genera circa 30-40 immagini candidate che rispettino la guida di stile:
- texture tileabili di terreno del Crepuscolo, roccia, corteccia, foglie, stoffa rattoppata, legno dei carri, metallo dei Generatori;
- 3 o 4 vedute d'insieme di un diorama dei Carri-campo, con terrazze inclinate e piante storte piegate verso sinistra, cioè verso il Giorno.

Prima dimmi il costo stimato. Poi mostrami le candidate in un foglio numerato, e fermati: sceglierò io le 10-20 che diventano le immagini di riferimento.

## Passo 3: Modello personalizzato su Scenario

Solo con le immagini che avrò approvato, prepara l'addestramento di un modello personalizzato. Dimmi il costo stimato e aspetta il mio ok. Dopo l'addestramento, provalo con 8 richieste (terreno, roccia, corteccia, foglie, parete, stoffa, metallo, texture di un oggetto) e mostrami i risultati accanto alle immagini di riferimento. Fermati.

## Passo 4: Kit di vegetazione 3D (101)

**Primo giro, per provare la catena:** solo 3 elementi, cioè un albero, un cespuglio e un ciuffo d'erba.
- Albero e cespuglio: Meshy, poi semplificazione low-poly. Proponimi un limite di triangoli per tipo di elemento, da scrivere nel punto 54.
- Erba: piani incrociati con texture pixel art.
- Texture rifatte con il modello personalizzato, o con PixelLab dove serve, alla densità di pixel del progetto e con filtro nearest.
- Le piante crescono piegate verso ovest, cioè verso il Giorno. Le variazioni casuali ruotano attorno all'asse verticale solo entro ±20°, per non perdere la direzione.

Mostrami i 3 elementi nel diorama, e fermati.

**Secondo giro, dopo il mio ok:** completa il kit fino a 12-15 elementi: 2 alberi (uno storto verso il Giorno e uno secco, bruciato dal Giorno), 3 cespugli, 2 felci, 3 ciuffi d'erba o fiori, 3 rocce di dimensioni diverse, 1 pianta coltivata storta per i Carri-campo. Aggiungi uno strumento di distribuzione basato su MultiMesh, con densità regolabile, per spargerli a centinaia. Misura gli fps sul Mac mini a 1280×800 con la scena piena, e fermati.

## Passo 5: Primo piano, billboard e lanterna (53, 99)

- Quando la vegetazione in primo piano copre Ottavia, deve sparire con una dissolvenza a retino di pixel invece che con una trasparenza morbida, per restare coerente con la pixel art. Se secondo te c'è una soluzione migliore, proponimela.
- Verifica che lo sprite inclinato non entri nei muri quando Ottavia ci passa vicino, e che la sua ombra non sia quella di una sagoma piatta inclinata. Mostrami i casi problematici e come li hai risolti.
- **La lanterna di Ottavia: opzioni (a) e (b) insieme.**
  - **(a)** Il vetro della lanterna emette luce propria: all'ombra resta acceso e produce il bagliore della scena. Usa una maschera di emissione per ogni fotogramma, preparata con Aseprite, che segni solo i pixel del vetro.
  - **(b)** Una piccola luce vera nella scena illumina l'intorno. Non è solo estetica: servirà nella Notte (45), dove sarà l'unica luce, per il Mangiaombre (B15), che si muove nelle ombre proiettate dalla lanterna, e per le creature del crepuscolo attratte dalla luce (36).
  - La luce deve seguire la lanterna. La sua posizione cambia nelle 8 direzioni e oscilla nell'animazione di attesa, quindi salva per ogni fotogramma il punto in cui si trova la lanterna, nei metadati dello spritesheet, e muovi la luce di conseguenza.
  - Prestazioni: le ombre della luce della lanterna vanno attivate nelle zone buie e disattivate di giorno, per restare leggeri anche su Steam Deck. Misura gli fps con le ombre accese e con le ombre spente.

Fermati.

## Passo 6: Scena dimostrativa

Ricostruisci il diorama della fase 1 con:
- il kit di vegetazione, fitto e su più strati, come un vero diorama;
- terreni e rocce con le nuove texture;
- Ottavia v1 in 8 direzioni, con attesa e camminata;
- la luce definitiva;
- il viraggio attivo lungo l'asse ovest-est, così che il lato sinistro tenda al Giorno e il destro alla Notte.

**Consegna:**
- 4 screenshot in `docs/screenshots/`: una veduta d'insieme, un primo piano con la vegetazione che copre Ottavia, la stessa scena con il valore della zona spostato verso la Notte, e un'inquadratura in una zona d'ombra profonda, in cui l'unica luce viene dalla lanterna.
- Un video di circa 20 secondi con Ottavia che cammina, usando la modalità di registrazione video di Godot se disponibile.
- Il riepilogo dei crediti spesi in tutta la fase.

Poi fermati e chiedimi se la fase 2 è approvata.
