# Fase 3: consegna (passo 7)

Domanda della fase: combattere con Ottavia è divertente, e perdere forza di capitolo in capitolo non è frustrante? Risponde solo la prova dell'autore; qui ci sono gli strumenti e le misure.

## Avvio

```
cd ~/Progetti/the-last-caravan && "$GODOT_PATH" --path . res://scenes/proto/diorama.tscn
```

- F1 (o Select/Back del gamepad): pannello; sezioni combattimento, creature, capitolo (cursore dell'età e "Fine capitolo"), cappotto (tre spazi delle toppe). Esc o Start: opzioni (comandi, tremolio, lampi, aiuto alla mira, difficoltà).
- Stanze: prato (Voltafaccia, Raspagelo, fantoccio, Enea), terrazza (Brinacchio, Grappolo), piattaforma; a est il campo del Foglione Radicato, a ovest il lago del Vecchio Spartighiaccio.
- Nessun gamepad è stato provato fisicamente: nessuno era collegato. La mappatura segue 67.

## Video

`docs/video/2026-09-28-fase3-capitolo1-vs-9.mp4` (38 s): il branco di tre Voltafaccia e il Vecchio Spartighiaccio al capitolo 1, poi gli stessi al capitolo 9. Li gioca un bot (`autofight=`, vedi `docs/tecnica.md`) con errore di tempismo di ±0,25 s. È sotto i 60 s previsti perché gli scontri durano poco (vedi la valutazione).

## Misure del bot (medio)

| Scontro | Errore | Cap. 1 | Cap. 9 |
|---|---|---|---|
| Branco (3 Voltafaccia) | 0 | 4,0 s, nessun danno | 3,6 s, nessun danno |
| Spartighiaccio | 0 | 8,9 s, nessun danno | 7,0 s, nessun danno |
| Spartighiaccio | ±0,15 s | 8,5 s, −10 vita | 7,1 s, nessun danno |
| Spartighiaccio | ±0,25 s | 10,7 s, nessun danno | 7,2 s, nessun danno |

Dopo il cambio dal passo al salto (28 settembre), errore ±0,25 s: branco 3,6 s (cap. 1) e 4,0 s (cap. 9), nessun danno; Spartighiaccio 22,3 s con −10 vita (cap. 1) e 18,1 s con −15 (cap. 9). Il salto schiva le cariche meno bene del vecchio passo: gli scontri col boss si allungano. Il video è ancora quello girato col passo.

Capitoli 1-10 col passo, senza errore, Spartighiaccio: 8,9 · 8,6 · 6,7 · 7,1 · 7,1 · 5,7 · 5,5 · 7,0 · 7,0 · 6,4 s.

## Valori trovati

Valori di partenza dopo il ribilanciamento e la regola della mira, tutti nel pannello F1 (`scripts/combat/combat_tuning.gd`, `scripts/combat/creature_tuning.gd`).

| Ottavia | Valore |
|---|---|
| Vita / fiato | 150 / 100 |
| Passo | 3,0 m/s |
| Colpo | 14 danni, portata 2,3 m, arco 90°, 0,12 + 0,08 + 0,22 s |
| Combinazione | 3 colpi, l'ultimo ×1,8 |
| Contrattempo (creatura scoperta) | ×2 |
| Mira | cono di 60° (90° al facile), disattivabile |
| Uncino | portata 3,2 m, tenuto 0,35 s spinge |
| Parata | deviazione entro 0,25 s dalla pressione, gratis; parata tenuta −15 fiato a colpo; sbilancia 1,2 s |
| Salto (al posto del passo, 28 settembre) | 0,6 m, circa 0,5 s in aria, invulnerabile 0,12 s al decollo, in aria supera gli attacchi a terra, −15 fiato |
| Corsa | ×1,6, −15 fiato al secondo, senza fiato si cammina |
| Fiato | +55/s dopo 0,6 s fermi, metà camminando, mai in parata; senza fiato 1 s |
| Colpito | 0,25 s di stordimento |
| Sensazione | fermo immagine 0,06 s (critico 0,12), tremolio 0,08 m (0,16) |
| Enea / Tosca | impara dopo 3 mosse / ricarica 12 s, portata 8 m |

| Creatura | Vita | Attacco | Note |
|---|---|---|---|
| Voltafaccia (B31) | 24 | 7, carica 0,65 s | lato in ombra (nord) ×2; scoperto 0,8 s |
| Raspagelo (B5) | 20 | 8, preavviso 0,9 s | sotto terra non bersagliabile; placca ×0,5; fuori 1,2 s |
| Brinacchio (B1) | 6 | nessun danno | rallenta fino al 60%; sente la lanterna a 8 m |
| Grappolo (B7) | 6 × 6 pezzi | 9, rotolata con carica 0,9 s | guscio ×0,7; si ricompone in 3 s |
| Foglione Radicato (83) | 200 | radici 10, spazzata 11 | foglie ×0,2; si chiude dopo 60 danni |
| Vecchio Spartighiaccio (41) | 240 | carica 16, pestone 10, acqua 15 | scudo ×0,1; fermo 2 s (3 s sul bordo) |

Difficoltà: facile danni ×0,7, vita ×0,8, preavvisi ×1,3, deviazione ×1,3; difficile ×1,3, ×1,25, ×0,85, ×0,8.

## Progressione per capitolo

Proposta in `docs/progressione.md` (da approvare): fiato 100% → 76%, passo 100% → 88%, combinazione 3 → 1, forza del colpo ×1 → ×2,35, una tecnica nuova per capitolo.

## Crediti spesi nella fase 3

| Servizio | Speso | Budget |
|---|---|---|
| PixelLab | 12 generazioni | 40 |
| ElevenLabs | 103 crediti (12 suoni) | 2.500 |
| Scenario | 0 | 200 CU |
| Meshy | 0 | 50 |

## Valutazione onesta

- Funziona: sei azioni, fiato, deviazione e contrattempo, quattro creature con regole diverse, due boss con meccaniche di luogo (leva e sole, ghiaccio), Enea che impara, Tosca, sconfitta che riparte dalla stanza, progressione, toppe, difficoltà. tutti i 328 controlli automatici passano.
- Troppo facile per chi gioca bene? Il bot, con riflessi perfetti, vince senza essere colpito; anche con ±0,25 s di errore vince in 11 s. Il bot però non ha tempi di reazione e si mette sempre sul fianco giusto: sopravvaluta un giocatore vero. Dopo il ribilanciamento gli scontri potrebbero essere passati da "parecchio difficili" a "brevi". Lo dice solo la tua prova.
- La progressione inversa, contro le stesse creature, non fa perdere: al capitolo 9 si vince più in fretta (7,2 s contro 10,7). La forza del colpo (+120%) pesa più di fiato (−24%), passo (−12%) e combinazione (3 → 1). Si sente come un cambio di stile (pochi colpi pesanti, deviare e aspettare) più che come una perdita. Se le creature dei capitoli avanzati sono più forti, l'equilibrio cambia; per ora non è definito.
- Il colpo pesante (capitolo 4) sbilancia con l'ultimo colpo della combinazione: dal capitolo 8, con combinazione da 1, non si usa più. Difetto della mia proposta.
- Grafica provvisoria: sprite fermi e segnaposti per creature, Enea e Tosca; nessuna animazione di combattimento definitiva (come chiesto).
- Non provato: gamepad fisico, Steam Deck.
