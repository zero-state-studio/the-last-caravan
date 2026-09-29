# Fase 4a: consegna del prologo

*28 settembre 2026. PROMPT-04, passo 7.*

## Come si avvia

```
"$GODOT_PATH" --path . res://scenes/prologo/piano_tessibuio.tscn
```

Si gioca con tastiera e mouse o con il gamepad; Esc (Menu/Start) apre la pausa con le opzioni. Per una finestra grande come lo schermo di Steam Deck:

```
"$GODOT_PATH" --path . --resolution 1280x800 res://scenes/prologo/piano_tessibuio.tscn
```

Dal piano buio dei Tessibuio, alla porta, all'accampamento, alla coda della colonna, al verdetto, fino al titolo «Ne restano dieci.».

## Prova a 1280×800

- Tutto il prologo è stato giocato da un pilota automatico (`scripts/dev/prologue_autoplay.gd`, argomento `autoplay=1`), che preme le stesse azioni di un giocatore: movimento, corsa, salto, lanterna, colpo, interagisci. È arrivato al titolo senza errori.
- Il video è stato registrato in una finestra da 1280×800, a 30 fotogrammi al secondo.
- Fotogrammi al secondo in finestra 1280×800 sul Mac (M4 Pro): 75 fissi nell'accampamento e nella colonna, cioè il limite della sincronia verticale dello schermo. Sullo Steam Deck non è stato misurato.
- Test automatici: tutti verdi (`tools/check.sh`), compresi i 56 controlli del prologo e i 9 dell'interfaccia.

## Video dall'inizio al titolo

`docs/video/capitoli/00-prologo/11-prologo-intero-folla-guida-citta-morta.mp4`: 4 minuti e 2 secondi, con musica, effetti e voci, dopo le correzioni della prima revisione (la versione precedente è il video 10).

## Crediti spesi nella fase 4a

| Servizio | Speso | Tetto della fase | Come è misurato |
|---|---|---|---|
| PixelLab | 289 generazioni | 300 | somma del registro (264 alla prima consegna, più 24 per le camminate della folla e 1 per Ruggero che si addormenta); l'account segna le generazioni del ciclo del mese, fase 3 compresa |
| Scenario | 30 CU | 1.000 | confermato dall'account (3 texture) |
| Meshy | 459 crediti | circa 500 | somma del registro (387 alla prima consegna, più 72 per le quattro rovine della città morta) |
| ElevenLabs | 3.424 misurati, più la musica | 15.000 | effetti 663 e voci 380 dall'intestazione `character-cost`; i quattro brani (circa 4 minuti) non danno il costo e la chiave non legge il consumo: stima 3.000-8.000, totale stimato 4.000-9.000 |

## Asset

Tutti in `docs/asset-log.csv`: 166 righe con data 28 settembre 2026. In breve:

- **Mezzi (16, 122-124):** i tre mezzi in cui si entra (camion-condominio, carro-campo, mezzo di testa), il kit di 12 moduli e 22 ricette di mezzi generici; ruote che girano, corpo che ondeggia, Generatore che batte, Code che serpeggiano.
- **Scenario:** tre rovine (casa diroccata, torre spezzata, muro con arco), montagne in tre creste, texture di interni (tende, stoffa rattoppata, lamiere, legno dipinto) e di terreno (strada, ghiaia, prato secco).
- **Personaggi:** il nuovo foglio di Ottavia (76 righe di animazioni), le comparse che parlano (Zelinda, Ruggero, Gnomone, Traslocante, Mirco, Arold, Anselmo, Enea) con le loro animazioni, gli otto tipi della folla con camminata e i sei colori dei mestieri.
- **Audio:** 4 brani, 27 effetti, 15 battute di voce di prova in italiano (una archiviata).
- **Interfaccia:** carattere Jersey 10 (SIL OFL, `docs/licenze-terze-parti.md`), meridiana, corda, lanterna in dieci pezzi, tutto disegnato in codice.

## Valutazione onesta

**Cosa funziona**

- Il prologo si gioca tutto, dal buio al titolo, in circa quattro minuti, e ogni spazio di `docs/livelli/prologo.md` c'è: il risveglio sentito e non visto, la lanterna, Zelinda, la porta con il bagliore, la carovana intera con la narrazione, i compiti dell'accampamento, Mirco, la corda, il verdetto di voce in voce, Enea che si volta, la mano di Anselmo, la lanterna vuota, il titolo.
- Lo stile tiene: diorama 3D con texture pixel art, luce di tramonto bassa, ombre lunghe, montagne e rovine sullo sfondo, una carovana di 25 mezzi diversi che sembra un paese.
- Il suono dà molto: il battito attutito nel buio, il tema che si abbassa sotto la voce, il silenzio del verdetto con le voci che si avvicinano da sinistra.
- L'interfaccia è poca e leggibile a 1280×800, e il testo si ingrandisce.

**Cosa non funziona ancora bene**

- **I mezzi da vicino.** I modelli Meshy hanno texture fangose e forme approssimative: da lontano reggono, a due metri no. Il Generatore dei tre mezzi principali è fuso nel modello e non batte.
- **Il ritmo della colonna.** L'andata e il ritorno da Mirco sono lunghi, su un campo quasi vuoto: nel video si vede un minuto di erba. Mancano cose da vedere lungo la strada, oppure la distanza è troppa.
- **La catena.** Le prime voci sono lontane e fuori quadro, quindi il loro riquadro sta sul bordo: si legge, ma "sempre più vicine" si sente più di quanto si veda.
- **La folla.** Cammina a velocità costante e senza evitarsi; i sacchi prendono il colore del mestiere; sullo scialle della donna anziana si vede il taglio della maschera.
- **Le icone dei tasti del mouse** mostrano il nome intero («Tasto sinistro del mouse»): troppo lungo per un'icona.
- **Il combattimento del prologo** è facile: il pilota automatico, che colpisce e basta, vince sempre. Per un prologo può andare, ma lo sciame non mette pressione.
- **Cose non verificate da me:** l'audio non l'ho ascoltato (ho misurato livelli e durate), il gamepad non l'ho tenuto in mano (i test simulano l'input), lo Steam Deck non l'ho provato. Il costo della musica non è misurabile con questa chiave.
- **Mancano per scelta di fase:** salvataggi (la lanterna è solo in memoria), voci inglesi (solo sottotitoli), ritratti nei dialoghi.

**Cosa cambierei**

1. Una passata sulle texture dei tre mezzi principali (ridipinte a pixel su un UV pulito), prima che servano come interni nella fase 4b.
2. Accorciare la strada fino a Mirco, o metterci lungo la via qualche segno della coda della carovana: carri rimasti indietro, oggetti caduti, la brina che avanza.
3. Per la catena, persone della folla messe apposta nel quadro, così le prime voci si vedono parlare.
4. Nomi brevi per i tasti del mouse nelle icone (per esempio «Clic S»).
5. Uno sciame un po' più aggressivo, che obblighi a usare la parata insegnata dal suggerimento.

## Dopo la prima revisione

- **Comparse vive:** la folla dell'accampamento gira tra tende e mezzi, con camminate in ogni direzione (24 generazioni PixelLab), e chi è vicino a Ottavia dice una frase. Le frasi sono segnaposti `TODO-DESIGN #121` (PRO_CROWD_01-08) in attesa dei testi dell'autore.
- **Dove andare:** bagliore caldo sul punto da raggiungere, freccia sul bordo dello schermo quando è fuori quadro, obiettivo scritto sopra il suggerimento, in ogni compito del piano buio, dell'accampamento e della colonna.
- **Veduta d'insieme:** camera a 18°, la carovana riempie la parte bassa e centrale; sullo sfondo una città morta di circa 35 rovine con 4 modelli nuovi (72 crediti Meshy).

## Dopo la seconda revisione

- **Sfondo:** città morta vicina, senza la fascia vuota; montagne più vicine e alte, foschia più leggera, e la narrazione si apre guardandole; avvallamenti nel terreno fuori dalla fascia di gioco.
- **Accampamento:** file di rocce basse da saltare al posto delle Code; ballatoio con scala sulla testata del carro-campo; Ruggero dorme seduto e si alza quando lo svegli (1 generazione PixelLab); croste di ghiaccio bianco-azzurre; fotogrammi del colpo di bastone sincronizzati con urto e suono, scia più visibile.
- **Colonna:** strada lunga fino a Mirco tra massi e muri da aggirare, notte che cala verso di lui, campo di brina vestito; Brinacchi all'andata e al ritorno, visibili (contorno, bagliore, ombra, scia) e battibili (il colpo spacca la crosta), che tolgono un po' di vita quando sono attaccati; raggi delle ruote che girano; Anselmo in coda dall'inizio; il verdetto è un dialogo tra lui e Ottavia (7 battute nuove, 106 crediti ElevenLabs); la colonna rallenta mentre Ottavia è via.
- **Video:** `docs/video/capitoli/00-prologo/13-prologo-intero-revisione-2.mp4`, 5 minuti e 21 secondi.

## Dopo la terza revisione

- Veduta iniziale meno alta (9°) e discesa verso la carovana più lenta; la narrazione finisce con «Ma ormai il mio tempo è passato...».
- Ogni compito ha un motivo detto a voce: una Voltacampi manda Ottavia da Ruggero, che dorme; Ruggero, svegliato e scorbutico, la manda dal Traslocante con la Coda bloccata.
- La mamma di Mirco corre da Ottavia a chiedere aiuto; al ritorno Ottavia parla a Mirco; la colonna si vede in lontananza quando Mirco è legato e la strada del ritorno passa a sud, tra massi e tronchi.
- Massi, tronchi, alberi (dal tronco) e rovine sono solidi; il muro ad arco sta lungo il bordo nord.
- Verdetto di Anselmo riscritto e affranto, poi una breve chiusura in cui Ottavia spiega le dieci Tregue e la lanterna del congedo.
- 25 battute nuove (834 crediti ElevenLabs, modello v3 per le voci più espressive).
- Video: `docs/video/capitoli/00-prologo/14-prologo-intero-revisione-3.mp4`, 6 minuti e 51 secondi.

## Ultima revisione

- Voci rifatte: «Serra fila» pronunciato staccato, Anselmo con la voce di Marco (riflessivo), la mamma di Mirco con quella di Roberta; Zelinda e Mirco con la voce.
- La mamma chiama «Ottavia! Ottavia!»; niente sosta per la mano: dopo il verdetto i due continuano a camminare e la camera si allarga e si allontana; la chiusura di Ottavia è veloce e ironica.
- Video: `docs/video/capitoli/00-prologo/16-prologo-intero-ultima-revisione.mp4`, 6 minuti e 38 secondi.

- Poi: lo Gnomone diventa il Meridiano (117); Zelinda con voce di vecchia scocciata; lo sguardo della camera arriva fino a Mirco; niente sagoma della lanterna nella chiusura, con la frase sulla crudeltà necessaria; pianura con avvallamenti e vestita ai lati della strada. Video: `docs/video/capitoli/00-prologo/17-prologo-intero-meridiano.mp4`, 6 minuti e 56 secondi.
