# Note tecniche

Compilato in fase 0 (27 settembre 2026). Le versioni qui sotto sono fissate: non cambiarle senza chiedere (60).

## Versioni

- Versione di Godot: **4.7.2.stable.official.ed1daf0bf** (rilevata il 2026-09-27)
- Versione di Aseprite: 1.3.18.6-arm64 (rilevata il 2026-09-27)
- Git LFS: 3.8.0, hook già installati nel repository
- Macchina di sviluppo: Mac mini, Apple M4 Pro; Godot usa Metal 4.0

## Verifica degli strumenti (2026-09-27)

| Strumento | Verifica | Risultato |
|---|---|---|
| Godot | `"$GODOT_PATH" --version` | 4.7.2.stable |
| Aseprite | `"$ASEPRITE_PATH" --version` | 1.3.18.6-arm64 |
| MCP pixellab, scenario, meshy, godot | `claude mcp list` | tutti connessi |
| ElevenLabs | `GET /v1/voices` con header `xi-api-key` | HTTP 200, 21 voci |

Note sui servizi:
- ElevenLabs: la chiave non può leggere l'abbonamento (`/v1/user/subscription` risponde 401, permesso non concesso, come previsto). Il costo di ogni generazione si legge dall'header `character-cost` della risposta.
- Scenario: un solo team ("Gianlucaricaldone's Organization", `team_boscukTE1AfcStGzcGfPCBSq`) con un solo progetto ("Nessuno", `proj_e3G6TyKNVH3TRmGEBhrB8Aym`). Gli strumenti di scrittura vogliono i due ID espliciti. Si usa questo progetto (decisione del 27 settembre).
- Meshy: `meshy_download_model` accetta `save_to` con percorso assoluto; senza, salva in `meshy_output/` nella radice (da evitare).

## Densità di pixel (costante del progetto)

**30 pixel per metro** (1 pixel = 3,33 cm), elementi 49 e 54. Ricavata da Ottavia v1: tela 64×64, corpo alto 48 px dalla testa ai piedi (media su tutti i 128 fotogrammi: 48,0; da 45 a 53 con passo e respiro), per un'altezza reale di 1,6 m: 48 / 1,6 = 30. Misurata il 27 settembre 2026.

Nel codice è `WorldScale.PIXELS_PER_METER` (`scripts/world/world_scale.gd`), e `WorldScale.METERS_PER_PIXEL` per il `pixel_size` di sprite e piante. Il valore globale degli shader `world_texels_per_meter` in `project.godot` deve coincidere: lo controlla `tests/run_tests.gd`.

## Lista di controllo per ogni texture

Prima di portare una texture in `assets/`:

1. **Densità: 30 px/m.**
   - Tessere per terreno e pareti: una tessera di N pixel copre N/30 metri (64 px = 2,13 m). La densità la applica lo shader triplanare con `world_texels_per_meter`; la tessera non va scalata a mano.
   - Sprite e piante piatte: `pixel_size = WorldScale.METERS_PER_PIXEL`, mai un valore scritto a mano.
   - Modelli 3D: `tools/meshy_pixelize.py --texels-per-meter 30`, che ricava la dimensione della texture dalla superficie del modello.
2. **Filtro nearest.** Nel materiale (`texture_filter = Nearest`) o nello shader (`filter_nearest`). Mai lineare. Per i GLB lo imposta il campionatore scritto da `meshy_pixelize.py`: verificare il materiale importato.
3. **Mipmap spente.** Nel file `.import`: `mipmaps/generate=false` (predefinito del progetto). Anche le texture estratte dai GLB (`<nome>_0.png.import`), dove Godot le accende: vanno spente a mano dopo il primo import, e il reimport le lascia spente. Il test `_test_texture_imports` in `tests/run_tests.gd` fallisce se una texture di `assets/` genera mipmap.
4. **Compressione lossless.** Nel file `.import`: `compress/mode=0` e `detect_3d/compress_to=0`. La compressione VRAM altera i colori della pixel art.
5. **Dimensioni.**
   - Tessere quadrate, 64 o 128 px, senza cuciture visibili: provarle in una griglia 2×2.
   - Sprite dei personaggi in celle 64×64.
   - Atlanti dei modelli con lato multiplo di 4, calcolato dalla densità.
6. **Trasparenza netta.** Per sprite, piante e maschere solo alfa 0 o 255: sono ritagliati con alpha scissor, quindi i semitrasparenti fanno bordi sporchi.
7. **Colori.** Nessun retino (dithering) introdotto dalle riduzioni automatiche. Modelli ridotti a un numero limitato di colori (24 nel prototipo). La palette di riferimento arriva con `docs/stile.md`.
8. **Registro.** Una riga in `docs/asset-log.csv` con servizio, modello, prompt e costo.

Controllo rapido di tutti i file `.import` (funziona anche in zsh):

```
find assets -name "*.png.import" -print0 | xargs -0 command grep -L "mipmaps/generate=false"   # mipmap accese
find assets -name "*.png.import" -print0 | xargs -0 command grep -L "compress/mode=0"          # non lossless
```

Stato al 27 settembre 2026: tutte lossless e senza mipmap, comprese le texture estratte dai GLB (spente il 27 settembre, screenshot identico al pixel).

## Comandi di verifica

- Comando per il controllo headless: **`tools/check.sh`**
  - `"$GODOT_PATH" --headless --path . --import` importa le risorse;
  - `"$GODOT_PATH" --headless --path . --script res://tests/run_tests.gd` esegue i test: impostazioni del progetto, mappa di input (tastiera e gamepad per ogni azione), traduzioni IT/EN, `Facing`, `ProtoSettings`, caricamento e compilazione di ogni scena e script in `scenes/`, `scripts/`, `tests/`;
  - poi esegue ogni `tests/test_*.gd` (per ora `test_proto_walk.gd`: scale, ponte e caduta nel diorama);
  - fallisce (exit 1, stampa i log) se un comando esce con errore o se compaiono righe `SCRIPT ERROR`, `Parse Error`, `ERROR:`, `Failed to load`, `FAIL:`. Verificato con uno script rotto di prova.
- Comando per lo screenshot: **`tools/screenshot.sh <res://scena.tscn> <uscita.png> [fotogrammi=30] [LxA=1280x800] [argomenti della scena...]`**
  - esempio: `tools/screenshot.sh res://scenes/proto/diorama.tscn docs/screenshots/prova.png`
  - gli argomenti extra arrivano alla scena (`OS.get_cmdline_user_args()`); il diorama accetta `settings=<json assoluto>`, `panel=1`, `perf=<secondi>`.
  - apre una finestra vera (il rendering serve la GPU, quindi niente `--headless`), attende i fotogrammi, salva il PNG con `scripts/dev/screenshot_runner.gd` e chiude. Fallisce se il file non viene scritto o se Godot stampa una riga `ERROR`.
  - **Attenzione:** in headless gli shader non vengono compilati, quindi `tools/check.sh` non vede i loro errori. Dopo ogni modifica a uno shader serve anche uno screenshot: è quello il controllo di compilazione.

## Progetto Godot

- Renderer scelto e motivo: **Forward+**. È l'unico renderer di Godot 4 con foschia volumetrica, SDFGI e l'insieme completo di effetti di post-processo (bagliore, sfocatura di profondità) che servono a 47 e 48. Mobile e Compatibility non hanno la foschia volumetrica. Steam Deck lo regge (Vulkan, GPU RDNA2); le prestazioni si misurano dal prototipo visivo in poi.
- Finestra di base 1280×800 (Steam Deck), ridimensionabile. Stretch `canvas_items` con aspetto `expand`: l'interfaccia scala con la finestra, il 3D mostra più campo sui formati più larghi.
- Filtro texture: `rendering/textures/canvas_textures/default_texture_filter = Nearest` per il 2D. **Attenzione:** in 3D non esiste un'impostazione globale. Ogni `Sprite3D`, `StandardMaterial3D` o shader deve impostare `texture_filter` su *Nearest* (senza mipmap) esplicitamente.
- Import delle texture (`[importer_defaults]` in `project.godot`): compressione lossless, niente mipmap, niente conversione automatica "detect 3D" (che attiverebbe mipmap e compressione VRAM sfocando la pixel art). Verificato sul file `.import` dello spritesheet di Ottavia.
- Mappa di input, movimento in 8 direzioni con `Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")`:

| Azione | Tastiera | Gamepad |
|---|---|---|
| `move_left` | A, freccia sinistra | levetta sinistra X−, croce sinistra |
| `move_right` | D, freccia destra | levetta sinistra X+, croce destra |
| `move_up` | W, freccia su | levetta sinistra Y−, croce su |
| `move_down` | S, freccia giù | levetta sinistra Y+, croce giù |

  Zona morta 0,2. Tasti fisici (`physical_keycode`), così WASD resta nella stessa posizione anche su tastiere AZERTY. La mappatura completa dei tasti resta da definire (67).
- Traduzioni: `localization/translations.csv` (colonne `keys,en,it`, chiavi in inglese), importato da Godot in `translations.en.translation` e `translations.it.translation`, che si versionano perché senza di essi il primo avvio segnala errori. Lingua di riserva: inglese. Chiave di prova: `UI_TEST_GREETING`. Un `Label` con testo uguale a una chiave si traduce da solo; nel codice si usa `tr()`.
- Scena principale: `scenes/proto/diorama.tscn`. La scena di prova della fase 0 (cielo, sole, un cubo e l'etichetta tradotta) è archiviata in `source-assets/archivio/smoke_test.tscn`; screenshot in `docs/screenshots/2026-09-27-fase0-smoke-test.png`.
- Uniform globali degli shader (`[shader_globals]` in `project.godot`): `world_texels_per_meter` (densità dei pixel del mondo, 30), `player_position` (aggiornata ogni fotogramma, usata dalla dissolvenza del primo piano), `palette_day_tint`, `palette_night_tint`, `palette_zone_proximity`, `palette_zone_center_x`, `palette_gradient_width`, `palette_strength` (viraggio Giorno/Notte, 51), impostate da un nodo `ZonePalette` in ogni zona. `ZonePalette.retint_models(nodo)` passa i modelli importati allo shader con viraggio, tenendo la loro texture.
- Nelle funzioni di un `.gdshaderinc` le variabili locali non devono avere il nome di una uniform dello shader che le include: Godot le risolve come la uniform e la compilazione fallisce.
- Sprite dei personaggi (49, 99): `Sprite3D` con `material_override` di `scenes/proto/materials/sprite_billboard_*.gdshader`. Il quad si disegna rivolto alla camera, ma in `DEPTH` si scrive la profondità di un quad verticale sul punto d'appoggio; l'ombra la proietta un secondo `Sprite3D` verticale (`ShadowProxy`, solo ombra) ruotato verso il sole. Nella variante illuminata `VERTEX` è un punto unico (petto, 40 cm verso il sole): tutto lo sprite prende la stessa luce e la stessa ombra, e l'ombra della copia non lo taglia a metà.
- Il riferimento a un nodo esportato (`@export var target: Node3D`) scritto a mano nel `.tscn` come `NodePath` non veniva risolto: si assegna dal codice.

## Strumenti

- `tools/meshy_pixelize.py` (Pillow via `uv run --with pillow`): prende un GLB texturizzato di Meshy, riduce la texture (per esempio 128 px, 24 colori, senza retino), la incorpora in PNG con filtro nearest e scala il modello a un'altezza in metri con la base a terra (54).
- Import dei GLB: Godot estrae le texture (`<nome>_0.png`) accendendo le mipmap: spegnerle nel `.import` (vedi la lista di controllo sopra). Il campionatore nearest scritto da `meshy_pixelize.py` diventa `texture_filter = Nearest` nel materiale (verificato).
- Pillow non è installato nel Python di sistema: usare `uv run --quiet --with pillow python3 ...`.
- Misura delle prestazioni: `"$GODOT_PATH" --path . --resolution 1280x800 res://scenes/proto/diorama.tscn -- settings=<json> perf=8` stampa una riga `PERF` (media, FPS, 95° percentile) con vsync disattivato. Risultati della fase 1 in `docs/fase1-prototipo.md`.

## Vegetazione (101)

- Kit: ogni elemento è un `VegetationEntry` (`scripts/world/vegetation_entry.gd`) salvato in `assets/vegetation_kit/<nome>.tres`: un modello GLB oppure una texture per i piani incrociati, con peso, raggio di ingombro, scala e ombra.
- Distribuzione: `VegetationScatter` (`scripts/world/vegetation_scatter.gd`, @tool) sparge gli elementi su un'ellisse (`extents`), con `density` istanze per m², bordo che si dirada, distanza minima data dagli ingombri, rotazione entro ±20° (le piante restano piegate verso ovest, 100). Una MultiMesh per elemento, figli interni che non finiscono nel file della scena. Le istanze stanno sul piano XZ del nodo: un nodo per livello del terreno.
- Headless: il renderer finto non conserva le trasformazioni delle MultiMesh (`get_instance_transform` dà l'identità, `get_aabb` è vuoto). Il test `tests/test_vegetation_scatter.gd` controlla quindi i piazzamenti calcolati e la mesh sorgente.
- Prestazioni del diorama a 1280×800 con la vegetazione del primo giro (circa 500 ciuffi, albero, cespuglio): 151 FPS medi, 95° percentile 13,7 ms (Mac mini M4 Pro, vsync spento).
- Con il kit completo (15 elementi: 1893 carte e 36 modelli, più 9 modelli piazzati a mano): 135-145 FPS nella vista normale, 119-143 nella veduta d'insieme (camera a 42 m). Prova di carico con densità ×4 (5176 carte): 124-146 FPS. Sul Mac mini la vegetazione non è il collo di bottiglia; il tempo GPU su Metal non si legge, quindi lo Steam Deck va misurato sul dispositivo.
- Limiti di triangoli usati nel kit (proposta per il 54): albero 1000, alberello 600, cespuglio 600, cespuglio secco circa 1000, tronco caduto 1000, ceppo 400, roccia grande 600, gruppo di sassi 400, carta di piani incrociati 4.

## Primo piano, billboard e lanterna (53, 99, 19)

- Dissolvenza in primo piano: `scenes/proto/materials/foreground_fade.gdshaderinc`, usata dalle carte della vegetazione (`foreground_fade.gdshader`) e dai modelli (`model_palette.gdshader`). Retino di Bayer 4×4 nello spazio della texture, entro 1,4 m da Ottavia sullo schermo, solo per i frammenti più vicini alla camera di lei. Nei modelli non vale nel passaggio delle ombre (`IN_SHADOW_PASS`, disponibile nel fragment di Godot 4.7): l'ombra dell'albero resta intera. Limite: un occlusore che cade nella sfocatura vicina ammorbidisce il retino.
- Billboard vicino ai muri: con la profondità del quad verticale (fase 1) lo sprite non entra in muri bassi, terrazza e fianchi; l'ombra viene dalla sagoma verticale rivolta al sole. Casi in `screenshots/2026-09-27-fase2-billboard-muri.png` e `-ombre.png`.
- Lanterna (a): maschera di emissione `assets/sprites/ottavia/ottavia_v1_emission.png` (vedi `ottavia_v1_sheet.md`), letta dallo shader dello sprite (`emission_mask`, `emission_energy` = `lantern_glass_energy`, 2,5). Nella variante illuminata diventa EMISSION, nella variante senza luce moltiplica l'albedo.
- Lanterna (b): `OmniLight3D` `LanternLight` in `ottavia_proto.tscn` (colore `#FFC46B`, energia 1,5, raggio 5 m). A ogni fotogramma `OttaviaProto` la porta al punto della lanterna salvato nel JSON del foglio, sul piano verticale rivolto alla camera, all'altezza vera.
- Ombre della lanterna: spente di norma, accese dentro un `DarkArea` (`scripts/world/dark_area.gd`, Area3D; nel diorama `DarkUnderBridge`). Per le misure: argomento `lantern_shadows=0|1` del diorama.
- FPS a 1280×800, sole quasi spento, vicino ai barili: ombre della lanterna accese 133-137, spente 131-140 (tre prove ciascuno). Sul Mac mini la differenza è dentro il rumore; lo Steam Deck va misurato sul dispositivo.
