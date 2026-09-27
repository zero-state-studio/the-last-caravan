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

## 49. Misure degli sprite  [Da definire]

Proposta dal primo test di Ottavia: tela di 40×56 pixel, personaggio alto circa 42 pixel, bastone compreso fino al bordo superiore. Da confermare nel prototipo visivo. Altezza dei personaggi in pixel, pixel per unità di mondo, fotogrammi per animazione. Senza questi numeri ogni asset generato esce con misure diverse. Il movimento libero richiede sprite in 8 direzioni: di solito se ne disegnano 5 e le altre 3 si ottengono specchiando. Ottavia però tiene il bastone in una mano e la lanterna nell'altra, e specchiandola le mani si scambierebbero. Per lei servono probabilmente tutte e 8.

## 50. Camera  [In discussione]

Proposta: camera alta che guarda la scena dall'alto, inclinata di circa 45-60 gradi, e segue il personaggio. L'orientamento resta fisso, perché gli sprite sono piatti: con una camera che ruota liberamente perderebbero credibilità.

**Resta da definire:** Angolo, distanza e campo visivo esatti, da fissare con un prototipo. Se concedere piccole rotazioni in punti precisi.

## 51. Palette ufficiale  [Da definire]

I colori di riferimento per personaggi, ambienti e interfaccia, da fornire a tutti gli strumenti di generazione.

## 52. Immagini di riferimento  [Da definire]

Una raccolta di 10-20 immagini approvate con cui addestrare un modello personalizzato su Scenario, così che tutte le generazioni seguano lo stesso stile. Devono essere immagini nostre: gli screenshot di Elliot servono come obiettivo da guardare, non come materiale di addestramento. Addestrare un modello su grafica altrui esporrebbe a problemi di copyright, e su Steam dobbiamo garantire che gli asset non violino diritti.

## 53. Oggetti in primo piano  [Da definire]

Quando la vegetazione vicina alla camera copre il personaggio, come nell'immagine di riferimento, deve diventare trasparente o lasciar vedere la sagoma di Ottavia. Altrimenti in combattimento la si perde di vista.

## 54. Regole per i modelli 3D  [Definito]

I modelli di Meshy vanno semplificati (low-poly) e ridipinti con texture in pixel art a bassa risoluzione, senza sfumature (filtro nearest), come le foglie nell'immagine di riferimento.

**Resta da definire:** Limite di poligoni e risoluzione delle texture.

## 55. Interfaccia  [Da definire]

Stile di menu e dialoghi, indicatori di vita e fiato.

## 56. Nome dello stile nel marketing  [Definito]

“HD-2D” è un marchio di Square Enix: sulla pagina Steam descriveremo lo stile come “3D pixel art”.
