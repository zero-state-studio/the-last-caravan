# Prompt della fase 3: Combattimento e progressione

Rileggi `CLAUDE.md`, `docs/fasi.md`, `docs/decisioni.md`, `docs/stile.md` e nella bibbia soprattutto: gameplay (33, 34, 38, 40, 82, 88, 95, 96, 102), personaggi (19, 20, 78-81), bestiario (36; B1, B5, B7, B31, B11, B33), dungeon (41, 83).

**Domanda della fase:** combattere con Ottavia è divertente, e perdere forza col passare dei capitoli non è frustrante?
**Uscita:** l'ho giocato io, sul mio Mac, con il gamepad, e mi ha convinto.

## Regole valide per tutta la fase

- **Animazioni provvisorie.** Niente animazioni di combattimento definitive con PixelLab. Usa Ottavia v1 (attesa e camminata) più effetti semplici: spostamenti dello sprite, lampi, scie, fermo immagine di qualche fotogramma all'impatto. Le animazioni vere si generano solo dopo che il combattimento avrà convinto.
- **Tutto regolabile.** Danni, vita, costi e ricarica del fiato, finestre di tempo di parata e contrattempo, velocità, tempi di ricarica dei compagni: tutto in un file di risorse modificabile e nel pannello di regolazione (F1). Sono valori da trovare provando.
- **Sensazione dei colpi.** Fermo immagine all'impatto, contraccolpo, lampo sul nemico colpito, suono. Tremolio dello schermo e lampi riducibili nelle opzioni (96).
- **Suoni provvisori con ElevenLabs:** al massimo 12 effetti (colpo di bastone, parata, deviazione, passo, sportello della lanterna, uncino, colpo subito, nemico colpito, nemico sconfitto, fiato esaurito, segnale di Enea, rampone di Tosca). Budget ElevenLabs della fase: 2.500 crediti.
- **Budget massimo della fase:** PixelLab 40 generazioni, Scenario 200 CU, Meshy 50 crediti, ElevenLabs 2.500 crediti.
- **Fermate:** dopo il passo 2, dopo il passo 5 e alla fine. Fermati anche per decisioni di design o spese oltre le soglie di `CLAUDE.md`. Commit alla fine di ogni passo.

## Passo 0: Aggiornare la bibbia

Aggiorna `docs/bibbia/` con questi testi, che sostituiscono quelli attuali o si aggiungono come nuovi elementi, e registra tutto in `docs/decisioni.md`:

- **20. I compagni** [Definito]. Quattro in tutto: Anselmo, Tosca, Oreste ed Enea (78-81). Enea, il più piccolo, sta sempre con Ottavia. Gli altri tre intervengono in combattimento con brevi azioni richiamabili, con un tempo di ricarica, solo quando sono presenti nel capitolo: Anselmo piazza una lanterna che acceca o attira le creature; Tosca aggancia un nemico con il rampone e lo trascina; Oreste lo abbaglia con un lampo dello specchio e ne mostra il lato debole.
- **33. Combattimento** [Definito]. Ottavia combatte con il lungo bastone a gancio: tanta portata, colpi lenti e precisi. Tutto si gioca su tempismo e posizione, non su schivate a ripetizione. Sei azioni. **Colpo:** attacco con il bastone. **Uncino:** il gancio tira a sé i nemici piccoli o strappa gli scudi; tenendo premuto, spinge via. **Parata:** tenendo premuto ci si difende; premendo al momento giusto si devia il colpo e il nemico resta sbilanciato. **Passo:** un breve scarto di lato, non una capriola, che costa fiato. **Lanterna:** apre e chiude lo sportello; tenendo premuto la alza e illumina più lontano. **Richiamo:** chiama il compagno presente nel capitolo. **Il fiato** è l'unica risorsa: passo e parata ne consumano molto, i colpi poco; si ricarica quando Ottavia non agisce; se si svuota, lei resta senza respiro per un istante ed è vulnerabile. **Il contrattempo:** colpire un nemico subito dopo un suo attacco, quando è scoperto, infligge un colpo critico. *Resta da definire:* Valori di danno, finestre di tempo e costi di fiato: si fissano provando, nella fase 3. Le animazioni definitive si generano solo dopo.
- **34. Progressione inversa** [Definito]. Capitolo dopo capitolo Ottavia perde forza, fiato, velocità e lunghezza delle combinazioni, ma impara nuove tecniche e ogni colpo diventa più potente: nel complesso diventa più forte. Alla fine di ogni capitolo una sola schermata mostra due righe, cosa perde e cosa impara, per esempio «La combinazione di colpi si accorcia da 3 a 2» e «Impara il contrattempo». Nessun albero delle abilità: è la vita di Ottavia che cambia. Intanto Enea cresce (81). *Resta da definire:* Quale tecnica si impara in quale capitolo, e il bilanciamento: da provare nella fase 3.
- **67. Controlli** [In discussione]. Pensati prima per il gamepad, come richiede la verifica Steam Deck. Proposta di partenza: A interagire, X Colpo, Y Uncino, B Passo, LB Parata, RB Lanterna, RT Richiamo (su PlayStation: croce, quadrato, triangolo, cerchio, L1, R1, R2). *Resta da definire:* La mappatura di tastiera e mouse, da proporre nella fase 3.
- **81. Enea, l'apprendista** [Definito]. Dodici giri. Figlio del Sindaco, ha scelto il mestiere più umile e pericoloso della carovana: camminare in fondo, dove nessuno vuole stare. Suo padre applica la legge dei Lasciati; lui sta imparando a riportare indietro chi resta. Ha appena cominciato e non sa quasi nulla. Diventerà il protagonista della saga. Impara guardando: le mosse che il giocatore esegue meglio con Ottavia diventano le sue, così mentre lei perde vigore lui cresce. Con il padre il rapporto è silenzioso: non lo disprezza, ma non condivide i suoi ragionamenti troppo duri, e ne soffre come se non pensarla come lui lo rendesse un cattivo figlio. Ha scelto l'unico posto della carovana dove suo padre non guarda mai. In combattimento non è mai una missione di scorta: non può morire, e se viene colpito cade e si rialza. All'inizio resta indietro; quando il giocatore esegue bene una mossa per un certo numero di volte, compare un segnale, per esempio «Enea ha imparato la parata», e da lì Enea la usa. Verso la fine del gioco combatte davvero. *Resta da definire:* Se le tecniche insegnate a Enea passano nel secondo capitolo.
- **104. Le toppe** [Definito]. L'equipaggiamento sono le toppe del cappotto, trovate durante la Tregua (39). Si cuciono in tre spazi, e ognuna dà un piccolo effetto: resistenza al freddo per i livelli verso la Notte, al caldo per quelli verso il Giorno, recupero del fiato, durata della lanterna. Nascono dal personaggio e non richiedono sprite nuovi. *Resta da definire:* L'elenco delle toppe.
- **105. La sconfitta** [Definito]. Se Ottavia cade, si riparte dall'ingresso della stanza con la vita piena; contro un boss, dall'inizio del combattimento. Nessuna penalità pesante: il gioco spinge a riprovare, non punisce. Nel finale (45) la sconfitta non esiste.
- **36.** Sostituisci la frase sulle due regole di gioco con: "Due regole di gioco. Le bestie del Giorno non voltano mai le spalle al sole, che arriva da sinistra (100): il loro lato in ombra è il destro, e colpite da lì subiscono danni doppi. Le creature del crepuscolo sono attratte da calore e luce: la lanterna le richiama, e chiuderne lo sportello fa perdere loro le tracce."

Segna la fase 3 come fase corrente in `docs/fasi.md`.

## Passo 1: Le stanze e la sconfitta (102, 105)

Ricava tre stanze collegate dalla scena della fase 2. I passaggi appartengono al luogo: una scala, un ponte, un varco tra le piante. Prepara il sistema generale per passare da una stanza all'altra: transizione, posizione d'ingresso, limiti della camera per stanza. Se Ottavia cade, si riparte dall'ingresso della stanza con la vita piena (105).

## Passo 2: Ottavia combatte (33)

- **Le sei azioni:** Colpo, Uncino, Parata con deviazione, Passo, Lanterna, Richiamo, più il fiato e il contrattempo, esattamente come descritti in 33.
- **Mappatura:** quella del punto 67 per il gamepad; proponimi tu quella per tastiera e mouse.
- **Il fantoccio:** per provare la parata e il contrattempo, un fantoccio di paglia dei Voltacampi che attacca con un ritmo regolabile.
- **Misure a schermo,** attivabili dal pannello: vita, fiato, e un segnale visivo quando una deviazione o un contrattempo riescono.

**Fermati qui.** Dammi il comando esatto per avviare il prototipo sul mio Mac, e dimmi quale gamepad è stato provato. La sensazione dei colpi devo sentirla io: da un video non si giudica.

## Passo 3: Le creature del Margine (36)

Implementa quattro creature con il loro comportamento: Voltafaccia (B31, in gruppo, rivolto al sole, debole sul lato destro), Raspagelo (B5, sbuca dal terreno), Brinacchio (B1, a sciami, attratto dalla lanterna, si attacca e rallenta), Grappolo (B7, palla che rotola, si scompone quando colpita e si ricompone). Sprite provvisori con PixelLab: una vista per creatura, specchiabile perché sono simmetriche, nello stile della fase 2.

## Passo 4: I due boss

- **Il Foglione Radicato (83):** tiene le foglie sempre rivolte al sole. Una leva inclina il terreno della stanza e sposta la luce, costringendolo a scoprire il fianco.
- **Il Vecchio Spartighiaccio (41):** carica in linea retta, si evita di lato e si colpisce ai fianchi. Le sue cariche spezzano parti del pavimento di ghiaccio.

Versioni semplici, ma complete dall'inizio alla fine.

## Passo 5: Enea e Tosca (81, 82, 20)

- **Enea:** segue Ottavia, non può morire, se colpito cade e si rialza. Conta le mosse eseguite bene dal giocatore; dopo un numero regolabile compare il segnale, per esempio «Enea ha imparato la parata», e da lì la usa.
- **Una lezione (82):** una breve sequenza in cui il giocatore guida Enea e Ottavia gli spiega la parata. Testi nel sistema di traduzione, provvisori.
- **Tosca, compagna richiamabile:** aggancia un nemico con il rampone e lo trascina, con tempo di ricarica.

**Fermati qui**, con lo stesso comando di avvio.

## Passo 6: Progressione inversa, toppe e difficoltà (34, 104, 40)

- **Cursore dell'età** nel pannello: simula Ottavia dal capitolo 1 al 10, riducendo fiato, velocità e lunghezza delle combinazioni e aumentando la potenza dei colpi. Proponimi una tabella capitolo per capitolo: cosa perde, cosa impara.
- **La schermata di fine capitolo,** con le due righe "perde" e "impara".
- **Tre spazi per le toppe,** e quattro toppe di prova: freddo, caldo, recupero del fiato, durata della lanterna.
- **Facile, medio e difficile:** cambiano forza dei nemici e tempi.

## Passo 7: Consegna

- **Il prototipo giocabile,** con il comando di avvio.
- **Un video di circa 60 secondi:** un combattimento al capitolo 1 e lo stesso al capitolo 9, per confrontare la progressione.
- **La tabella dei valori** trovati, e la tabella della progressione per capitolo.
- **Il riepilogo dei crediti** spesi.
- **La tua valutazione onesta:** cosa funziona, cosa no, cosa cambieresti.

Poi fermati e chiedimi se la fase 3 è approvata.
