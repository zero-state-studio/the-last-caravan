# Registro delle decisioni

Cosa è stato deciso e quando. Le idee scartate restano qui per non riproporle. Aggiungi righe solo dopo l'approvazione dell'autore.

## 26 settembre 2026

- Genere: action RPG con combattimento in tempo reale, non a turni.
- Stile: come *The Adventures of Elliot*.
- Durata: da 2 a 4 ore.
- Concept scelto: *L'Ultima Carovana*, con Ottavia come protagonista.
- Il gioco è il prologo di un secondo capitolo con un protagonista più giovane.
- Scartati perché troppo convenzionali: pietre magiche che reggono il mondo, città che si rivela malvagia, cassa misteriosa, giovane guardia come protagonista.
- Titolo originale in inglese: *The Last Caravan*. In italiano: *L'Ultima Carovana*.
- Motore: Godot 4 con GDScript tipizzato.
- Piattaforme: PC su Steam, con l'obiettivo della verifica per Steam Deck.
- Lingue: italiano e inglese al lancio.
- La carovana è un comune in movimento, con carri-campo, camion-condominio e un Sindaco che governa quasi come un re.
- La carovana procede a tappe, regolate da una meridiana.
- I compagni di Ottavia sono quattro: tre adulti e un ragazzo che ha appena iniziato a imparare da lei.
- Il protagonista della saga è quel ragazzo. Nel secondo capitolo diventa discepolo di una figura misteriosa, la cui identità resta un segreto.
- Traccia della figura misteriosa: la lanterna che Anselmo non ha mai costruito.
- Enea sta sempre con Ottavia; le missioni in cui lei gli dice cosa fare fanno da tutorial.
- Oreste parla, con dialoghi da svitato per il troppo sole.
- Apertura: Ottavia si sveglia con l'ordine di marcia, narrazione del mondo, poi aiuta la gente a partire.
- Nella Notte non c'è niente per gli umani: solo freddo, buio, ombre di creature e rumori.
- Almeno dieci dungeon.
- Struttura della storia approvata: le dieci Tregue, la lanterna come avanzamento, il finale.
- La durata si decide dungeon per dungeon, da 10 a 40 minuti, invece che sul totale.
- Recupero degli attardati: prima senza limiti, poi a tempo, infine appena dentro la Notte.
- Difficoltà: facile, medio, difficile, con percorsi più lunghi e rami bonus a medio e difficile.
- Bestiario: almeno 30 creature del crepuscolo e 30 del Giorno, più forti man mano che ci si addentra.
- Salvataggi e accessibilità approvati.
- Ogni creatura può comparire in più dungeon, tranne i colossi.
- Bestiario, creature e boss dei dieci dungeon approvati.
- Ultimo gesto del gioco: spegnere la lanterna. Nel vicolo cieco è l'unica azione possibile, senza timer.
- Pilastri approvati; “nessun cattivo” significa nessun supercattivo, le bestie restano nemici.
- Lessico, fasce intermedie, carovana come base, musica approvati.
- Ottavia ha sessant'anni: grintosa, buona, dolce con Enea e rigida con gli altri; da bambina ha visto i genitori lasciati indietro.
- Progressione: Ottavia perde forza e fiato, ma con nuove abilità e colpi più potenti diventa nel complesso più forte.
- La Tregua è un timer ovunque, per esplorare i dintorni della carovana; al dungeon si passa con un'azione dedicata.
- Doppiaggio completo previsto fin dall'inizio, anche se arriverà dopo.
- Il Sindaco è Arold, il Capofila, salito al potere con la Lunga Rincorsa.
- Scartati i Nascosti, perché allungano il gioco senza servire la storia principale.
- Salvati approvati.
- I motori dei mezzi si chiamano Generatori.
- Aspetto di Ottavia approvato; la schiena molto più sbiadita del davanti è una scelta di stile.
- Ottavia va disegnata in tutte le direzioni, una per una: non si può specchiare, ma deve potersi girare ovunque.
- Finale: nella Notte arrivano nemici senza fine; Ottavia si ferma in un vicolo cieco, vede le stelle e aspetta la morte; lampi di luce la portano via, senza che se ne veda il salvatore.
- Stile precisato sull'immagine di riferimento di *Elliot*: mondo 3D esplorabile in tutte le direzioni e su più livelli di altezza, con texture in pixel art e tre piani di profondità. Sostituisce la formula “pixel art 2.5D”.

## 27 settembre 2026

- Scenario: si usa il progetto esistente "Nessuno" (`proj_e3G6TyKNVH3TRmGEBhrB8Aym`).
- Git: solo commit locali, niente push su `origin` se non richiesto.
- Texture pixel art degli ambienti per la fase 1: Retro Diffusion Tile su Scenario (circa 10 CU a immagine).
- Camera (50): prospettica, inclinata di 50°, a 20 m, campo visivo 35°, per ora.
- Sprite (49): tela 64×64 di Ottavia v1, Ottavia alta 48 px, 30 pixel per metro; billboard pieno, con profondità e ombra da sagoma verticale.
- Densità di pixel unica per tutte le texture del mondo: terreno, rocce, piante e modelli (54).
- Palette (51): calda con accenti freddi legati al mondo; verso la Notte blu-viola, verso il Giorno bianco e ocra.
- Direzione (48): il Giorno è fisso a ovest, a sinistra dello schermo, la Notte a destra; sole da sinistra e un po' dal lato della camera. Eccezioni: Linea d'Ombra (41), Ombra della Montagna (43), interni dei mezzi.
- Scartati per la camera: 40° e 60° e la proiezione ortografica. Scartato per gli sprite: il billboard ad asse verticale fisso, perché schiaccia lo sprite e rende i pixel rettangolari.
- Palette (51): il freddo viene soprattutto dalla luce (ombre e luce ambientale del cielo verso il blu-viola); intensità del viraggio 1 per ora, da rivedere in fase 2.
- Viraggio della palette calcolato sulla posizione nel mondo: valore di vicinanza alla Notte o al Giorno per zona (16) più gradiente lungo l'asse ovest-est dentro la zona; niente cambia colore con la camera.
- Virano ambiente e modelli 3D; personaggi e creature tengono i colori disegnati ma ricevono la luce della scena, ombre fredde comprese; l'interfaccia non vira mai.
- Fase 1 approvata; fase corrente: 2.
- Nuovi elementi della bibbia, con i numeri della bibbia di riferimento: 99 Billboard degli sprite [Definito], 100 Il lato del Giorno [Definito], 101 Kit di vegetazione 3D [In discussione]. In 48 e 49 restano solo i rimandi.
- Ottavia (19): le diagonali sono fatte (v1); restano da definire le animazioni di combattimento (fase 3) e le durate definitive dei fotogrammi.
- Spritesheet di Ottavia v1: tela 64×64 definitiva, durate provvisorie fino alla fase 3.
- Immagini di riferimento (52), passo 2 della fase 2: scelte 12 texture (01, 05, 11, 12, 18, 19, 22, 23, 24, 25, 26, 27), in `source-assets/riferimenti/2026-09-27-texture/`. Le vedute V1-V4 (GPT Image) sono solo riferimento visivo, escluse dall'addestramento. Il modello personalizzato si addestra solo sulle texture approvate.
- Modello personalizzato (52): il v1 (`model_SU9gw4R9QvdxPcDtbd598gak`) è accettato per l'MVP. Un modello v2 più specifico, definitivo per tutto il gioco, è rimandato a una fase successiva (budget Scenario della fase 2 invariato).
- Immagini di altri giochi: l'autore può mostrarle come esempio della direzione voluta; si traducono solo in regole scritte e generiche (`docs/stile.md`), mai usate come input, riferimento nei prompt o addestramento.
- Palette (51): palette v2 per gli ambienti, 64 colori (la v1 più 25 toni intermedi e 7 varianti di tinta), in `assets/palette/palette_v2_env.*`, generata da `tools/palette_v2.py`. Personaggi, creature e interfaccia restano sulla v1.
- Densità (54): prima di decidere tra 30 px/m per tutto e 60 px/m per le texture degli ambienti, prova delle due nel diorama con le texture esistenti (`docs/screenshots/2026-09-27-fase2-densita-*.png`). Scelta in attesa.
