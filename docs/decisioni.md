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
- Densità (54): prima di decidere tra 30 px/m per tutto e 60 px/m per le texture degli ambienti, prova delle due nel diorama con le texture esistenti (`docs/screenshots/fasi/fase2-stile-definitivo/0[1-4]-densita-*.png`). Scelta in attesa.
- Densità (54): confermati 30 px/m per tutto, anche per gli ambienti. La ricchezza viene da palette v2, micro-dettaglio, geometria e luce. Scartati 60 px/m (sotto il pixel dello schermo a 1280×800, sfarfallio) e la camera più vicina. Passo 4, primo giro approvato.
- Fase 2 approvata; fase corrente: 3.
- Luce di zona (51): il valore della zona sposta anche la luce (verso la Notte sole più freddo, debole e basso, cielo più blu; verso il Giorno sole più bianco e più alto), solo in base al valore della zona e mai alla camera. Scelta al posto di alzare l'intensità del viraggio.
- Limiti di triangoli (54) approvati per tipo di elemento; kit di vegetazione (101) Definito.
- Terreno: tinta ocra-oliva sulla faccia superiore di terreno e terrazza.

## Fase 3, passo 0 (27 settembre 2026)

- Bibbia aggiornata con i testi di `PROMPT-03.md`: 20 I compagni (azioni richiamabili di Anselmo, Tosca, Oreste), 33 Combattimento (sei azioni, fiato, contrattempo), 34 Progressione inversa (schermata di fine capitolo con due righe, niente albero delle abilità), 67 Controlli (In discussione, proposta gamepad), 81 Enea (non muore, impara le mosse dal giocatore), nuovi 104 Le toppe e 105 La sconfitta, 36 con le due regole di gioco (lato destro delle bestie del Giorno a danni doppi; la lanterna richiama le creature del crepuscolo).
- Fase corrente: 3.
- Bibbia: nuovi 102 Livelli a stanze (diorami chiusi collegati da passaggi del luogo; si torna nelle stanze del dungeon, non tra capitoli; rami e percorsi bonus come stanze che si aprono; la Notte resta continua) e 103 La carovana in marcia come mappa (mappa continua che avanza verso sinistra; interni dei mezzi come stanze; nota tecnica: carovana ferma e terreno che scorre a pezzi). Aggiornati 37 (base ferma nella Tregua, in marcia nella Rincorsa), 41 e 43 (dungeon a stanze, linea d'ombra e ombra della montagna che si spostano di stanza in stanza), 44 (tratto all'aperto sulla mappa in marcia, interni come stanze), 45 (spazio continuo).
- Controlli (67): mappatura di tastiera e mouse con la mano sinistra su WASD (clic sinistro Colpo, clic destro Parata, Spazio Passo, Q Uncino, E interagire, R Richiamo, F Lanterna, Esc opzioni); il mouse non mira; tutti i comandi rimappabili dal nuovo menu opzioni (96), salvati in `user://controls.cfg`.
- Combattimento (33), correzioni dopo la revisione: passo con 0,12 s di invulnerabilità; finestra di deviazione dal momento della pressione; la parata tenuta consuma fiato quando incassa, la deviazione non ne consuma (costo di pressione 0 e comunque restituito); l'uncino aggancia il nemico più vicino dentro il cono dell'aiuto alla mira davanti a Ottavia; aiuto alla mira di 35° disattivabile nelle opzioni; il fiato si ricarica camminando a metà velocità, mai in parata.
- Combattimento (33): primo ribilanciamento dopo la prova dell'autore (troppo difficile): Ottavia più forte e rapida, creature e boss circa un terzo più deboli; valori in `assets/combat/` e nel pannello F1, ancora da provare.
- Mira (33): con la levetta premuta, creatura più vicina nel cono di 60° (30° per lato) attorno alla levetta, altrimenti direzione della levetta; levetta ferma: Ottavia si gira verso la creatura più vicina a portata; il colpo spazza circa 90° e colpisce tutte le creature nell'arco; l'uncino usa lo stesso cono; al facile il cono passa a 90°; nessun tasto di aggancio, il 67 non cambia. Valori nel pannello F1 (`aim_cone_degrees`, `aim_cone_easy_degrees`, `strike_arc_degrees`).
- Progressione inversa (34), toppe (104) e difficoltà (40): proposta in `docs/progressione.md` (dieci capitoli, una perdita e una tecnica ciascuno, forza del colpo +15% a capitolo; quattro toppe di prova; facile/medio/difficile). In attesa di approvazione, bibbia invariata.
- Controlli e combattimento (33, 67): il passo è sostituito dal salto (barra spaziatrice, B sul gamepad), libero ovunque, che fa anche da schivata (breve invulnerabilità al decollo; in aria supera gli attacchi a terra: anelli del Raspagelo e del pestone, radici del Foglione, rotolate del Grappolo); nuova corsa tenuta (Shift, L3 sul gamepad) che consuma fiato e, a fiato vuoto, torna al cammino senza senza-respiro. Le stanze (102) vanno disegnate tenendo conto del salto. Tecnica del capitolo 5: salto sicuro al posto del passo sicuro. Valori di partenza: salto 0,6 m, 15 di fiato, invulnerabilità 0,12 s; corsa ×1,6, 15 di fiato al secondo.
- Fotogrammi di salto e corsa di Ottavia (19, 33): rimandati a un secondo momento; per ora in aria resta la posa del cammino e la corsa accelera i fotogrammi.
- Fase 3 approvata, prototipo di combattimento chiuso; fase corrente: 4. Restano aperte la tabella della progressione (proposta in `docs/progressione.md`), la crescita della forza nei capitoli avanzati e il colpo pesante con combinazione da 1.
- Bibbia, fase 4a (68, 106): aggiunti 14-capitoli (106 Prologo definito, rimanda a `docs/livelli/prologo.md`; 107-116 capitoli), 15-comparse (117-121), 16-mezzi (122-124) e 17-interfaccia-e-audio (125-127); rimandi 55→125, 57→126, 58→127 per il prologo; 68 definito: prima fetta in due tempi, prologo (fase 4a) poi Carri-campo (fase 4b). `docs/fasi.md`: fase 4 divisa in 4a e 4b, corrente la 4a. I prompt delle fasi stanno in `docs/prompts/`.
- Mezzi e folla (16, 121, 98): la carovana conta 20-25 mezzi; i tre tipi 122-124 sono quelli in cui si entra, gli altri sono generici e montati da un kit di moduli. La folla ha otto tipi generici (uomo giovane, adulto, anziano; donna giovane, adulta, anziana; bambino, bambina); aspetto proprio solo per chi parla o conta nella storia; mestiere riconoscibile da colore e segni dei vestiti; davanti leggermente sbiadito. La carovana va verso ovest (100, 103).
- Controlli (33, 67): arrampicata automatica (spingere contro una parete con appigli), salto sul suo tasto; porte e passaggi si attraversano camminando e portano a un'altra scena; il tasto Interagire (A sul gamepad, E sulla tastiera, già nel 67) serve per i personaggi.
- Proporzioni (49, 122): tutte le misure devono essere credibili; il camion-condominio è lungo 20 m e alto 12 m, anche se da vicino la camera non lo inquadra tutto.
- Fase 4a, passo 1: tetto di Meshy della fase alzato da 400 a circa 500 crediti; folla adulta alta 54-57 px accettata; colori dei mestieri come ricolorazioni al passo 4; Mirco, Enea e Ruggero rigenerati più piccoli; Anselmo (senza bastone e lanterna) e Arold (pallottoliere al fianco) corretti.
- Prologo, spazio 1 (106, 118, 127): il risveglio si sente e non si vede: la stanza resta buia finché Ottavia non apre la lanterna, e lei compare già in piedi; nel buio il cigolio della branda e un respiro (aggiunti al 127, riga nuova in `docs/livelli/prologo.md`). Primo suggerimento «Apri la lanterna», poi «Muoviti». Zelinda in una sola vista, con l'attesa mentre tesse in 6-8 fotogrammi (118).
- Fase 4a, passo 3: si rifanno le animazioni deboli di Ottavia (colpo subito e senza fiato a sud, parata a ovest, mano a ovest); la veduta d'insieme si sistema subito, con più dettagli; l'ambiente dell'accampamento si arricchisce: rocce, alberi radi, strade sterrate e ghiaia sul terreno, sfondo con edifici diroccati e montagne 3D.
- Prologo, passi 4 e 5 (106, 125): per svegliare Ruggero e legare Mirco il suggerimento è il nome dell'azione («Interagisci» col tasto); dopo il titolo «Ne restano dieci» lo schermo resta nero finché non c'è il capitolo 1 (fase 4b); durante il verdetto la colonna non si ferma: Ottavia, Mirco e Anselmo camminano con lei, e si fermano solo per la mano.
- Fase 4a, passo 6 (59): voci di prova approvate dopo l'ascolto: Ottavia Elettra (O1), Anselmo Dade M (A2), catena Nonno Ben, Valeria, Jorgos. I mezzi in marcia hanno ruote che girano, corpo che ondeggia e Generatore che batte (16, 77).
- Mezzi (77): il Generatore dei tre mezzi principali resta fermo (fuso nel modello); le Code serpeggiano mentre il mezzo avanza. Corretto l'orientamento delle Code del kit, che strisciavano di traverso invece che verso est.
- Fase 4a, passo 6 (126, 127): approvati i testi della musica M1-M4; generati musica, 27 effetti e 13 battute di voce di prova. Sotto la narrazione il tema resta basso; nel verdetto la musica tace e le quattro voci della catena si avvicinano (da -12 a 0 dB).
