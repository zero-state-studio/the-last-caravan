# Fase 1: prototipo visivo

Stato al 27 settembre 2026. Serve a scegliere, guardando, camera (50), misure degli sprite (49) e palette di base (51). Non è grafica definitiva.

## Come si prova

- Avvio: `"$GODOT_PATH" --path .` (la scena principale è `scenes/proto/diorama.tscn`).
- Movimento: WASD o frecce, levetta sinistra o croce del gamepad.
- **F1** (gamepad: Back/Select) apre il pannello di regolazione. "Salva impostazioni e screenshot" scrive in `docs/screenshots/` una coppia `proto-<data-ora>.png` + `.json` e ricorda i valori per l'avvio successivo (`user://proto_settings.json`).
- Da riga di comando: `tools/screenshot.sh res://scenes/proto/diorama.tscn out.png 60 1280x800 settings=/percorso/assoluto.json [panel=1]`.

## La scena

- Diorama 30×30 m: terreno, terrazza e piattaforma a 3 m, scale di 9 gradini (rampa di collisione invisibile), ponte di legno a 3 m sotto cui si passa, muretti, rocce di sfondo per la sfocatura lontana. Verificato da `tests/test_proto_walk.gd`: si salgono le scale, si attraversa il ponte, si cade dal bordo.
- Texture: 5 tessere 64×64 di Retro Diffusion (Scenario), applicate con uno shader triplanare in coordinate mondo (una texture per le facce in alto, una per i fianchi), filtro nearest. Densità unica: **26 pixel per metro**, come lo sprite (42 px per 1,6 m).
- Ottavia provvisoria: `ottavia_test_sheet.png`, fotogrammi 40×56, alta circa 1,6 m (0,038 m per pixel). Diagonali con la vista cardinale più vicina; sulla diagonale esatta resta la vista attuale, se è una delle due. Attesa a 2 fotogrammi (0,5 s), camminata con gli stessi 2 fotogrammi più veloci (segnaposto).
- Modelli Meshy (54): cassa, roccia, albero storto; 350-669 triangoli, texture ridotte a 128 px e 24 colori con `tools/meshy_pixelize.py`. Non hanno collisioni.
- Primo piano (53): 3 piante PixelLab su quad rivolti alla camera fissa. Quando stanno tra la camera e Ottavia si aprono attorno a lei con un retino (dithering 4×4) nello spazio della texture: niente trasparenze da ordinare, la grana dei pixel resta.
- Luce (48): sole a 14° di altezza da ovest-sudovest, colore #FFB873, ombre lunghe, luce ambiente fredda (tono lilla-blu) per le ombre, bagliore, foschia volumetrica leggera, prospettiva aerea, SSAO.

## Le combinazioni consegnate

Stessi valori per tutte, cambia solo l'angolo della camera (e la proiezione nella quarta):

| Valore | Impostazione comune |
|---|---|
| Distanza camera | 20 m dal punto di fuoco (petto di Ottavia) |
| Campo visivo | 35° verticali |
| Sfocatura | vicina fino a 2 m prima del fuoco, lontana da 3 m dopo; intensità 0,2 |
| Sprite | 0,038 m per pixel, billboard con asse verticale fisso, non illuminato |
| Mondo | 26 pixel per metro |
| Sole | altezza 14°, direzione 300°, intensità 2, colore (1,0; 0,72; 0,45) |
| Foschia volumetrica | densità 0,008 |

| Combinazione | Screenshot | Valori |
|---|---|---|
| Camera a 40° | `screenshots/2026-09-27-fase1-camera-40.png` | `screenshots/2026-09-27-fase1-camera-40.json` |
| Camera a 50° | `screenshots/2026-09-27-fase1-camera-50.png` | `screenshots/2026-09-27-fase1-camera-50.json` |
| Camera a 60° | `screenshots/2026-09-27-fase1-camera-60.png` | `screenshots/2026-09-27-fase1-camera-60.json` |
| Extra: 50° ortografica | `screenshots/2026-09-27-fase1-camera-50-ortografica.png` | `screenshots/2026-09-27-fase1-camera-50-ortografica.json` |

Altri screenshot:
- `screenshots/2026-09-27-fase1-billboard-confronto.png`: billboard con asse verticale fisso contro billboard pieno, a 40° e 60°. Con l'asse fisso lo sprite si accorcia come il coseno dell'angolo (a 60° è alto la metà) e i pixel diventano rettangoli; il billboard pieno mantiene pixel quadrati.
- `screenshots/2026-09-27-fase1-pannello.png`: il pannello F1.
- `screenshots/2026-09-27-fase1-palette-50.png`: i 16 colori dominanti dello screenshot a 50°.

Osservazioni:
- A 40° si legge meglio l'altezza (pareti della terrazza, ponte, scale) e la sfocatura vicino/lontano dà l'effetto miniatura più forte. A 60° la pianta del livello è più chiara, ma le pareti si accorciano e la sfocatura si nota poco, perché le profondità in scena sono più uniformi.
- La sfocatura dipende dalla profondità, non dalla posizione sullo schermo: i valori buoni cambiano con angolo e distanza. Con la camera a 20 m le soglie devono essere strette (2-3 m) per vedersi.
- L'ortografica elimina la deformazione prospettica dei muri, ma perde senso di profondità.

## Prestazioni sul Mac mini (Apple M4 Pro, Metal, Forward+)

Misurate con `"$GODOT_PATH" --path . --resolution <LxA> res://scenes/proto/diorama.tscn -- settings=<json> perf=8` (vsync disattivato, 2 s di riscaldamento, 8 s di misura):

| Risoluzione | Camera | Media | FPS medi | 95° percentile |
|---|---|---|---|---|
| 1280×800 | 40° | 7,3 ms | 136 | 13,9 ms |
| 1280×800 | 60° | 6,9 ms | 145 | 14,0 ms |
| 1920×1080 | 40° | 10,3 ms | 97 | 15,4 ms |
| 1920×1080 | 60° | 8,5 ms | 118 | 14,1 ms |

C'è margine, ma lo Steam Deck ha una GPU molto più debole: le voci più costose da controllare lì sono foschia volumetrica, SSAO, sfocatura e ombre del sole a 80 m. La scena è piccola (circa 80 nodi), quindi questi numeri non valgono per un livello completo.

## Da decidere (per la bibbia)

- 50: angolo, distanza, campo visivo, prospettica o ortografica.
- 49: tela e altezza degli sprite, pixel per metro, billboard pieno o ad asse fisso.
- 51: palette di base.
- Da che lato sta il Giorno rispetto alla camera (direzione del sole).
