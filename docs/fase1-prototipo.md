# Fase 1: prototipo visivo

Stato al 27 settembre 2026. Serviva a scegliere, guardando, camera (50), misure degli sprite (49) e palette di base (51). Non è grafica definitiva. **Le scelte dell'autore sono in fondo e nella bibbia (48, 49, 50, 51, 54).**

## Come si prova

- Avvio: `"$GODOT_PATH" --path .` (la scena principale è `scenes/proto/diorama.tscn`).
- Movimento: WASD o frecce, levetta sinistra o croce del gamepad.
- **F1** (gamepad: Back/Select) apre il pannello di regolazione. "Salva impostazioni e screenshot" scrive in `docs/screenshots/` una coppia `proto-<data-ora>.png` + `.json` e ricorda i valori per l'avvio successivo (`user://proto_settings.json`).
- Da riga di comando: `tools/screenshot.sh res://scenes/proto/diorama.tscn out.png 60 1280x800 settings=/percorso/assoluto.json [panel=1]`.

## La scena

- Diorama 30×30 m: terreno, terrazza e piattaforma a 3 m, scale di 9 gradini (rampa di collisione invisibile), ponte di legno a 3 m sotto cui si passa, muretti, rocce di sfondo per la sfocatura lontana. Verificato da `tests/test_proto_walk.gd`: si salgono le scale, si attraversa il ponte, si cade dal bordo.
- Texture: 5 tessere 64×64 di Retro Diffusion (Scenario), applicate con uno shader triplanare in coordinate mondo (una texture per le facce in alto, una per i fianchi), filtro nearest. Densità unica: **30 pixel per metro**, ricavata da Ottavia v1 (48 px per 1,6 m); vale anche per piante e modelli.
- Ottavia: foglio v1 (`assets/sprites/ottavia/ottavia_v1_sheet.png`), celle 64×64, 8 direzioni vere, attesa e camminata da 8 fotogrammi (160 e 100 ms). Billboard pieno, con profondità di una sagoma verticale (non entra nei muri) e ombra proiettata da una copia verticale girata verso il sole. Le prime prove erano con `ottavia_test_sheet.png` (40×56, 4 direzioni).
- Modelli Meshy (54): cassa, roccia, albero storto; 350-669 triangoli, texture ridotte a 24 colori con `tools/meshy_pixelize.py --texels-per-meter 30` (124, 120 e 276 px, ricavati dalla superficie). Non hanno collisioni.
- Primo piano (53): 3 piante PixelLab su quad rivolti alla camera fissa. Quando stanno tra la camera e Ottavia si aprono attorno a lei con un retino (dithering 4×4) nello spazio della texture: niente trasparenze da ordinare, la grana dei pixel resta.
- Luce (48): sole a 14° di altezza da ovest-sudovest (il Giorno è a sinistra), colore #FFB873, ombre lunghe, luce ambiente fredda (tono lilla-blu) per le ombre, bagliore, foschia volumetrica leggera, prospettiva aerea, SSAO.
- Palette (51): `ZonePalette` (`scripts/world/zone_palette.gd`) dà alla zona un valore di vicinanza alla Notte o al Giorno (qui 0, centro del Crepuscolo) e un gradiente lungo l'asse ovest-est del mondo (un passo pieno a 15 m dal centro). Virano terreno, piante e modelli Meshy; Ottavia no, ma è illuminata dalla scena (luce e ombre calcolate in un solo punto, al petto, spostato verso il sole). Luce ambientale e cielo tendono al blu-viola, e da lì viene il freddo delle ombre.

## Le combinazioni consegnate

Rifatte dopo le scelte dell'autore. Valori comuni:

| Valore | Impostazione |
|---|---|
| Distanza camera | 20 m dal punto di fuoco (petto di Ottavia) |
| Campo visivo | 35° verticali, prospettica |
| Sfocatura | vicina fino a 2 m prima del fuoco, lontana da 3 m dopo; intensità 0,2 |
| Sprite | Ottavia v1, 1/30 m per pixel, billboard pieno con profondità verticale, illuminata dalla scena |
| Mondo | 30 pixel per metro |
| Sole | altezza 14°, direzione 300° (da ovest-sudovest), intensità 2, colore (1,0; 0,72; 0,45) |
| Foschia volumetrica | densità 0,008 |
| Viraggio Giorno/Notte | intensità 1 |

| Combinazione | Screenshot | Valori |
|---|---|---|
| Camera a 40° | `screenshots/2026-09-27-fase1-camera-40.png` | `screenshots/2026-09-27-fase1-camera-40.json` |
| **Camera a 50° (scelta)** | `screenshots/2026-09-27-fase1-camera-50.png` | `screenshots/2026-09-27-fase1-camera-50.json` |
| Camera a 60° | `screenshots/2026-09-27-fase1-camera-60.png` | `screenshots/2026-09-27-fase1-camera-60.json` |

Altri screenshot:
- `screenshots/2026-09-27-fase1-billboard-muro.png`: Ottavia appoggiata al muro della terrazza. Con la profondità del quad inclinato sparisce nel muro e restano solo i piedi; con la profondità verticale si vede intera.
- `screenshots/2026-09-27-fase1-luce-ottavia.png`: Ottavia al sole (toni caldi) e all'ombra del muro (tutta blu-viola, senza tagli).
- `screenshots/2026-09-27-fase1-ombra.png`: l'ombra di Ottavia al sole è la sua sagoma verticale, lunga verso est (la Notte), e si piega sul muretto.
- `screenshots/2026-09-27-fase1-billboard-confronto.png` (prima prova, foglio di prova): billboard ad asse verticale fisso contro billboard pieno a 40° e 60°.
- `screenshots/2026-09-27-fase1-pannello.png`: il pannello F1.
- `screenshots/2026-09-27-fase1-palette-50.png`: i 16 colori dominanti dello screenshot a 50°. Sono ancora quasi tutti bruni e oliva: il viraggio c'è ai bordi della scena, ma non cambia i colori che occupano più superficie.

Osservazioni dalla prima prova:
- A 40° si legge meglio l'altezza e la sfocatura dà l'effetto miniatura più forte. A 60° la pianta del livello è più chiara, ma le pareti si accorciano e la sfocatura si nota poco.
- La sfocatura dipende dalla profondità, non dalla posizione sullo schermo: i valori buoni cambiano con angolo e distanza. Con la camera a 20 m le soglie devono essere strette (2-3 m).
- L'ortografica elimina la deformazione prospettica dei muri, ma perde senso di profondità.

## Prestazioni sul Mac mini (Apple M4 Pro, Metal, Forward+)

Misurate con `"$GODOT_PATH" --path . --disable-vsync --resolution <LxA> res://scenes/proto/diorama.tscn -- settings=<json> perf=8` (2 s di riscaldamento, 8 s di misura).

Configurazione scelta (camera a 50°, Ottavia v1, profondità verticale e ombra separata, viraggio):

| Risoluzione | FPS medi (senza limite) | Tempo medio | CPU di rendering |
|---|---|---|---|
| 1280×800 | 131 | 7,6 ms | 0,3 ms |
| 1920×1080 | 157 | 6,4 ms | 0,4 ms |

- In circa metà delle esecuzioni macOS impone comunque la sincronizzazione a 75 Hz (frequenza dello schermo) e il risultato è 75,0 FPS esatti: `--disable-vsync` non scavalca il limite del driver. I numeri sopra vengono dalle esecuzioni senza limite; tra una prova e l'altra variano del 10-20 %.
- Su Metal Godot non misura il tempo GPU (risulta 0), quindi il costo della GPU si vede solo dagli FPS.
- Prima prova (foglio di prova, billboard ad asse fisso): 136-145 FPS a 1280×800, 97-118 a 1920×1080. La profondità scritta dallo sprite e la copia per l'ombra non hanno un costo visibile.
- Lo Steam Deck ha una GPU molto più debole: le voci da controllare lì sono foschia volumetrica, SSAO, sfocatura e ombre del sole a 80 m. La scena è piccola (circa 80 nodi), quindi questi numeri non valgono per un livello completo.

## Scelte dell'autore (27 settembre 2026)

1. Camera a 50°, distanza 20 m, campo visivo 35°, per ora (50).
2. Prospettica.
3. Billboard pieno; controllato che non entri nei muri e che l'ombra sia di una sagoma verticale.
4. Tela 64×64 di Ottavia v1; 30 pixel per metro per tutte le texture del mondo (49, 54).
5. Palette calda con accenti freddi legati al mondo: verso la Notte blu-viola, verso il Giorno bianco e ocra (51).
6. Il Giorno è fisso a ovest (sinistra dello schermo), la Notte a destra; sole da sinistra e un po' dal lato della camera. Eccezioni: 41, 43, interni dei mezzi (48).

Seconda risposta (27 settembre 2026): intensità del viraggio 1; freddo dalla luce (ombre e cielo blu-viola); viraggio per zona più gradiente ovest-est nel mondo; virano i modelli 3D, non personaggi, creature e interfaccia; fase 1 approvata.
