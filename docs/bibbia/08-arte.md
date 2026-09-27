# Direzione artistica

*Le regole che rendono coerenti migliaia di asset generati da strumenti diversi.*

## 46. Stile  [Definito]

Come nell'immagine di riferimento da *The Adventures of Elliot*: un mondo 3D a diorama, dove piante, rocce ed edifici sono modellati in 3D ma rivestiti di texture in pixel art a bassa risoluzione, così che la grana dei pixel resti visibile anche sulle superfici tridimensionali. I personaggi sono sprite in pixel art. Luci morbide, bagliori, particelle e foschia completano l'effetto.

## 47. Piani di profondità  [Definito]

La sfocatura divide la scena in tre piani: il primo piano sfocato, con la vegetazione vicina alla camera; il piano di gioco nitido, dove si muove il personaggio; lo sfondo sfocato. È questo a dare l'effetto miniatura.

## 98. Vestiti scoloriti dal sole  [In discussione]

Proposta, regola per tutti i personaggi: il sole basso scolorisce il lato dei vestiti rivolto al Giorno. Chi cammina con la carovana ha il davanti sbiadito e la schiena più scura; la Serrafila, sempre voltata verso la Notte, il contrario. Nella realtà i vestiti si scolorirebbero un po' ovunque: per stile, il lato che guarda più a lungo il Giorno resta molto più sbiadito dell'altro. Dà coerenza al mondo e rende Ottavia riconoscibile a colpo d'occhio.

## 48. Tramonto perenne  [Definito]

Tutto il gioco è illuminato da una luce radente e calda, e la Notte finale è l'unica zona buia. È l'identità visiva del gioco, riconoscibile da un solo screenshot.

Orientamento: vedi 100.

## 100. Il lato del Giorno  [Definito]

Il Giorno è fisso a ovest, cioè a sinistra dello schermo, e la Notte a destra. Il sole arriva da sinistra e un po' dal lato della camera: ombre lunghe verso destra, visi illuminati. Il viaggio tra Giorno e Notte corre in orizzontale, dove lo schermo è più largo. Eccezioni solo dove la luce che si muove è la meccanica stessa: la Linea d'Ombra (41), l'Ombra della Montagna (43) e gli interni dei mezzi.

## 49. Misure degli sprite  [Definito]

Tela di **64×64 pixel**, quella di Ottavia v1. Ottavia è alta **48 pixel** dalla testa ai piedi (bastone escluso), pari a circa 1,6 metri: la densità del gioco è quindi **30 pixel per metro** (un pixel vale 3,3 cm). La stessa densità vale per tutte le texture del mondo (vedi 54).

Billboard: vedi 99.

Il movimento libero richiede sprite in 8 direzioni. Ottavia e i personaggi asimmetrici si disegnano in tutte e 8, una per una, senza specchiarli; le creature simmetriche possono usarne 5 più 3 specchiate (36).

**Resta da definire:** Fotogrammi per animazione. Ottavia v1 ne usa 8 per l'attesa e 8 per la camminata.

## 99. Billboard degli sprite  [Definito]

Billboard pieno: gli sprite guardano sempre la camera e i pixel restano quadrati a ogni angolo.

**Resta da definire:** Che gli sprite inclinati non entrino nei muri e che le ombre non siano quelle di sagome piatte inclinate (passo 5 della fase 2).

## 50. Camera  [Definito]

Camera prospettica che guarda la scena dall'alto e segue il personaggio. L'orientamento resta fisso, perché gli sprite sono piatti: con una camera che ruota liberamente perderebbero credibilità. Valori scelti con il prototipo visivo, per ora: **inclinazione 50°**, **distanza 20 metri** dal punto seguito, **campo visivo verticale 35°**.

**Resta da definire:** Se concedere piccole rotazioni in punti precisi.

## 51. Palette ufficiale  [Definito]

Palette calda, con accenti freddi voluti e legati al mondo: verso la Notte ombre e colori virano al blu-viola, verso il Giorno al bianco e all'ocra.

- Il freddo viene soprattutto dalla luce: il colore delle ombre e la luce ambientale del cielo tendono al blu-viola.
- Il viraggio dipende solo dalla posizione nel mondo, mai dalla camera. Ogni zona ha un valore di vicinanza alla Notte o al Giorno (vedi 16), e dentro la zona il viraggio cresce lungo l'asse ovest-est del mondo, con il Giorno a ovest (100). Nessun oggetto cambia colore quando la camera si muove.
- Virano l'ambiente e i suoi modelli 3D. Personaggi e creature mantengono i colori disegnati, per riconoscibilità e leggibilità in combattimento, ma ricevono la luce della scena, ombre fredde comprese. L'interfaccia non vira mai.

**Resta da definire:** I codici esatti dei colori di riferimento per personaggi, ambienti e interfaccia, da fornire a tutti gli strumenti di generazione. L'intensità del viraggio (per ora 1 nel prototipo), da rivedere nella fase 2 con le texture vere.

## 52. Immagini di riferimento  [Da definire]

Una raccolta di 10-20 immagini approvate con cui addestrare un modello personalizzato su Scenario, così che tutte le generazioni seguano lo stesso stile. Devono essere immagini nostre: gli screenshot di Elliot servono come obiettivo da guardare, non come materiale di addestramento. Addestrare un modello su grafica altrui esporrebbe a problemi di copyright, e su Steam dobbiamo garantire che gli asset non violino diritti.

## 53. Oggetti in primo piano  [Da definire]

Quando la vegetazione vicina alla camera copre il personaggio, come nell'immagine di riferimento, deve diventare trasparente o lasciar vedere la sagoma di Ottavia. Altrimenti in combattimento la si perde di vista.

## 54. Regole per i modelli 3D  [Definito]

I modelli di Meshy vanno semplificati (low-poly) e ridipinti con texture in pixel art a bassa risoluzione, senza sfumature (filtro nearest), come le foglie nell'immagine di riferimento. Tutte le texture del mondo, cioè terreno, rocce, piante e modelli, hanno la stessa densità di pixel dei personaggi: 30 pixel per metro (49). La risoluzione di ogni texture si ricava da questa densità e dalla superficie del modello.

**Resta da definire:** Limite di poligoni.

## 101. Kit di vegetazione 3D  [In discussione]

Vegetazione in vera geometria 3D con texture pixel art, fittissima e su più strati. Kit di 10-15 elementi (alberi, cespugli, felci, ciuffi d'erba, rocce), fatti con Meshy semplificato e con piani incrociati per l'erba, tutti alla stessa densità di pixel e distribuiti con MultiMesh. Le piante crescono piegate verso il Giorno, cioè verso ovest. Si costruisce al passo 4 della fase 2.

## 55. Interfaccia  [Da definire]

Stile di menu e dialoghi, indicatori di vita e fiato.

## 56. Nome dello stile nel marketing  [Definito]

“HD-2D” è un marchio di Square Enix: sulla pagina Steam descriveremo lo stile come “3D pixel art”.
