# Ottavia v1: spritesheet

Personaggio 19. Versione 1, generata con PixelLab il 2026-09-27 (vedi `docs/asset-log.csv`).

## File

| File | Contenuto |
|---|---|
| `ottavia_v1_sheet.png` | Spritesheet, 512×1024 px, RGBA, sfondo trasparente |
| `ottavia_v1_sheet.json` | Dati Aseprite (json-array): rettangolo e durata di ogni fotogramma, tag |
| `ottavia_v1_emission.png` | Maschera di emissione della lanterna, stessa griglia: bianco sui pixel del vetro, trasparente altrove |
| `ottavia_v1.aseprite` | Sorgente Aseprite: un livello, 128 fotogrammi, 16 tag, durate impostate |

## Griglia

- Cella: **64×64 px**, senza margini né spaziatura. Filtro nearest, niente mipmap.
- **8 colonne** (fotogrammi 0-7) × **16 righe** (una per animazione e direzione).
- Punto d'appoggio: i piedi di Ottavia stanno intorno a y = 59-61 nella cella (fondo del disegno a y = 60-62); il bastone arriva fino a y = 0-2.

| Riga | y (px) | Tag | Durata fotogramma |
|---|---|---|---|
| 0 | 0 | `idle_s` | 160 ms |
| 1 | 64 | `idle_se` | 160 ms |
| 2 | 128 | `idle_e` | 160 ms |
| 3 | 192 | `idle_ne` | 160 ms |
| 4 | 256 | `idle_n` | 160 ms |
| 5 | 320 | `idle_nw` | 160 ms |
| 6 | 384 | `idle_w` | 160 ms |
| 7 | 448 | `idle_sw` | 160 ms |
| 8 | 512 | `walk_s` | 100 ms |
| 9 | 576 | `walk_se` | 100 ms |
| 10 | 640 | `walk_e` | 100 ms |
| 11 | 704 | `walk_ne` | 100 ms |
| 12 | 768 | `walk_n` | 100 ms |
| 13 | 832 | `walk_nw` | 100 ms |
| 14 | 896 | `walk_w` | 100 ms |
| 15 | 960 | `walk_sw` | 100 ms |

Fotogramma `f` della riga `r`: `x = f × 64`, `y = r × 64`. Tutte le animazioni sono in loop, in avanti.

Direzioni: `s` verso la camera, `e` verso destra dello schermo, `n` di spalle, `w` verso sinistra. Nessuna direzione è specchiata (36): bastone sempre nella mano destra, specchio sulla spalla sinistra, corda al fianco sinistro.

## Note provvisorie

- La tela 64×64 è definitiva (49): Ottavia alta 48 px, 30 pixel per metro. Le durate (160 ms attesa, 100 ms camminata) restano provvisorie fino alla fase 3.
- Palette: 162 colori, tutti presi dalle rotazioni approvate. Contorno esterno uniformato a #1E1A33.

## Rigenerare

`tools/ottavia_v1_build.py` (pulizia, controlli, GIF) e poi `tools/ottavia_v1_aseprite.lua` (file .aseprite); comandi in testa ai due script.

## Lanterna (19)

`tools/lantern_mask.lua` (Aseprite in riga di comando) prepara la maschera di emissione e scrive in `ottavia_v1_sheet.json`, per ogni fotogramma, `"lantern": {"x": .., "y": ..}`: il centro del vetro in pixel della cella (origine in alto a sinistra, centri dei pixel a +0,5). Il vetro è il gruppo più in alto di pixel nei colori `#FEF88F` `#FCBC3C` `#FACC69` `#ECC04E` `#ED9D2B`: gli stessi gialli compaiono più in basso su fibbia e corda, quindi il colore da solo non basta. Lo script riscrive il JSON su una riga sola.

```
"$ASEPRITE_PATH" -b --script-param sheet=$PWD/assets/sprites/ottavia/ottavia_v1_sheet.png \
  --script-param data=$PWD/assets/sprites/ottavia/ottavia_v1_sheet.json \
  --script-param mask=$PWD/assets/sprites/ottavia/ottavia_v1_emission.png --script tools/lantern_mask.lua
```

Va rieseguito ogni volta che il foglio cambia.
