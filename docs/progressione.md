# Progressione inversa: proposta (34, 104, 40)

**Stato: PROPOSTA della fase 3, passo 6, in attesa di approvazione dell'autore.** La bibbia (34) non è cambiata. Valori in `scripts/combat/progression.gd`, `scripts/combat/coat_patches.gd`, `scripts/combat/difficulty.gd`; il cursore del capitolo e le toppe sono nel pannello F1 (sezioni "chapter" e "coat").

## Capitoli

Ogni capitolo: una cosa persa e una tecnica imparata, mostrate nella schermata di fine capitolo. La forza di ogni colpo cresce del 15% del valore del capitolo 1 a ogni capitolo.

Valori di partenza del capitolo 1: fiato 100, passo 3,0 m/s (corsa ×1,6), colpo 14, combinazione di 3 colpi.

| Cap. | Fiato | Passo | Combinazione | Forza colpo | Perde | Impara |
|---|---|---|---|---|---|---|
| 1 | 100% | 100% | 3 | 1,00 | — | — |
| 2 | 94% | 100% | 3 | 1,15 | fiato | Colpo di ritorno: dopo una deviazione, il colpo successivo (entro 1,2 s) è critico |
| 3 | 94% | 96% | 3 | 1,30 | passo | Occhio esperto: finestra di deviazione +0,05 s |
| 4 | 94% | 96% | 2 | 1,45 | combinazione | Colpo pesante: l'ultimo colpo della combinazione sbilancia (0,8 s) |
| 5 | 88% | 96% | 2 | 1,60 | fiato | Salto sicuro: invulnerabilità del salto 0,2 s |
| 6 | 88% | 92% | 2 | 1,75 | passo | Lanterna che abbaglia: alzarla sbilancia le creature entro 3 m (1,2 s, ricarica 8 s) |
| 7 | 82% | 92% | 2 | 1,90 | fiato | Contrattempo profondo: critico ×2,5 |
| 8 | 82% | 92% | 1 | 2,05 | combinazione | Uncino lungo: +1 m di portata |
| 9 | 76% | 92% | 1 | 2,20 | fiato | Respiro della veterana: il fiato riparte dopo 0,3 s |
| 10 | 76% | 88% | 1 | 2,35 | passo | — |

L'idea: al capitolo 1 Ottavia vince con combinazioni e passi; al 9 vince aspettando il momento giusto (deviazione, colpo di ritorno, contrattempo profondo), con pochi colpi pesanti.

## Toppe del cappotto (104), quattro di prova

Tre spazi. L'elenco definitivo è `TODO-DESIGN #104`; freddo, caldo e lanterna sono provvisori finché temperature e combustibile non sono definiti.

| Toppa | Effetto |
|---|---|
| Freddo | danni dalle creature della Notte ×0,8; i parassiti del gelo rallentano la metà |
| Caldo | danni dalle bestie del Giorno ×0,8 |
| Fiato | ricarica del fiato ×1,2 |
| Lanterna | portata della luce ×1,25 (sta per "dura di più") |

## Difficoltà (40)

Il medio è il gioco tarato; gli altri lo scalano. Si sceglie nelle opzioni.

| | Facile | Medio | Difficile |
|---|---|---|---|
| Danni delle creature | ×0,7 | ×1 | ×1,3 |
| Vita delle creature | ×0,8 | ×1 | ×1,25 |
| Preavvisi (caricamenti, segnali a terra) | ×1,3 | ×1 | ×0,85 |
| Finestra di deviazione | ×1,3 | ×1 | ×0,8 |
| Cono della mira | 90° | 60° | 60° |
