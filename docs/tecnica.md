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
  - esempio: `tools/screenshot.sh res://scenes/proto/diorama.tscn docs/screenshots/catture/prova.png`
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
- Scena principale: `scenes/proto/diorama.tscn`. La scena di prova della fase 0 (cielo, sole, un cubo e l'etichetta tradotta) è archiviata in `source-assets/archivio/smoke_test.tscn`; screenshot in `docs/screenshots/fasi/fase0-fondamenta/01-scena-di-prova.png`.
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
- Billboard vicino ai muri: con la profondità del quad verticale (fase 1) lo sprite non entra in muri bassi, terrazza e fianchi; l'ombra viene dalla sagoma verticale rivolta al sole. Casi in `screenshots/fasi/fase2-stile-definitivo/05-billboard-muri.png` e `-ombre.png`.
- Lanterna (a): maschera di emissione `assets/sprites/ottavia/ottavia_v1_emission.png` (vedi `ottavia_v1_sheet.md`), letta dallo shader dello sprite (`emission_mask`, `emission_energy` = `lantern_glass_energy`, 2,5). Nella variante illuminata diventa EMISSION, nella variante senza luce moltiplica l'albedo.
- Lanterna (b): `OmniLight3D` `LanternLight` in `ottavia_proto.tscn` (colore `#FFC46B`, energia 1,5, raggio 5 m). A ogni fotogramma `OttaviaProto` la porta al punto della lanterna salvato nel JSON del foglio, sul piano verticale rivolto alla camera, all'altezza vera.
- Ombre della lanterna: spente di norma, accese dentro un `DarkArea` (`scripts/world/dark_area.gd`, Area3D; nel diorama `DarkUnderBridge`). Per le misure: argomento `lantern_shadows=0|1` del diorama.
- FPS a 1280×800, sole quasi spento, vicino ai barili: ombre della lanterna accese 133-137, spente 131-140 (tre prove ciascuno). Sul Mac mini la differenza è dentro il rumore; lo Steam Deck va misurato sul dispositivo.

## Scena dimostrativa (fase 2, passo 6)

- Il diorama (`scenes/proto/diorama.tscn`) è la scena dimostrativa: kit di vegetazione, texture nuove in `assets/textures/terrain/` (palette v2), Ottavia v1 con lanterna, viraggio ovest-est attivo.
- Ombra profonda: `DarkArea` con `deep_shadow = true` abbassa in 0,8 s sole, luce ambientale e nebbia al 4 % mentre Ottavia è dentro (nel diorama: `DarkUnderBridge`, il corridoio sotto il ponte). Un `ReflectionProbe` interno con luce ambientale scura non bastava: la nebbia volumetrica tra camera e terreno schiariva comunque la zona.
- Export tipizzati di nodi (`@export var sun: DirectionalLight3D`) con un NodePath scritto a mano nel `.tscn` non vengono risolti: usare `@export var ..._path: NodePath` e `get_node` in `_ready` (come in `DarkArea`).
- `ProtoSettings.zone_night_proximity` (anche nel pannello F1) sposta il valore della zona verso la Notte (16, 51).
- Video: `"$GODOT_PATH" --path . --resolution 1280x800 --write-movie <out.avi> --fixed-fps 30 --quit-after 600 res://scenes/proto/diorama.tscn -- settings=<json> autowalk=1` (Movie Maker, AVI MJPEG), poi MP4 con il binario di `imageio-ffmpeg` via `uv run --with imageio-ffmpeg` (ffmpeg non è installato nel sistema). `autowalk=1` fa percorrere a Ottavia le 8 direzioni.
- FPS finali a 1280×800, vista normale: 138-143.

## Stanze e sconfitta (fase 3, passo 1; 105)

- `Room` (`scripts/world/room.gd`): volume della stanza (box centrato sul nodo, per sapere dove si trova Ottavia), rettangolo X/Z entro cui resta il fuoco della camera (`camera_limits_rect`), entrata predefinita. `RoomEntry` (Marker3D): punto d'arrivo e di ripartenza. `RoomExit` (Area3D): passaggio verso `target_room`/`target_entry`; l'entrata d'arrivo deve stare fuori da ogni uscita della stanza di destinazione.
- `RoomManager` (`scripts/world/room_manager.gd`): dissolvenza al nero (0,25 s), spostamento all'entrata, limiti della camera (`FollowCameraRig.limits`); segue Ottavia senza dissolvenza quando lascia una stanza senza passaggio (caduta dalla piattaforma). Sconfitta (105): `OttaviaProto.defeated` → dissolvenza, ripartenza dall'entrata usata per entrare nella stanza, vita piena.
- Nel diorama: Prato (terreno e corridoio), Terrazza, Piattaforma. Passaggi: la scala (Prato ↔ Terrazza), il ponte (Terrazza ↔ Piattaforma), il varco tra i cespugli in cima alla rampa nuova (Piattaforma ↔ Prato). A 20 m di camera l'inquadratura copre circa ±10 m: nelle stanze alte la camera resta quasi ferma.
- Test: `tests/test_rooms.gd` (passaggi, caduta, limiti della camera, sconfitta).

## Combattimento (fase 3, passo 2; 33, 67)

- Valori: `CombatTuning` (`scripts/combat/combat_tuning.gd`), file `assets/combat/combat_tuning.tres`. Tutti nel pannello F1 (sezione "Combattimento"); il pulsante "Salva i valori del combattimento" riscrive il `.tres`.
- `OttaviaCombat` (`scripts/combat/ottavia_combat.gd`, nodo `Combat` di Ottavia): le sei azioni, il fiato, il contrattempo; `press`/`release` pilotabili da test e sequenze. `OttaviaProto` chiede a ogni fotogramma la velocità permessa e la spinta dell'azione (passo, affondo, contraccolpo).
- Nemici: `CombatEnemy` (`scripts/combat/combat_enemy.gd`), gruppo `combat_targets`: vita, lampo, contraccolpo, sbilanciamento dopo una deviazione, uncino (tira i piccoli, spinge, strappa gli scudi). `TrainingDummy`: fantoccio dei Voltacampi a ritmo regolabile (`scenes/combat/training_dummy.tscn`).
- Sensazione: `HitFeedback` (fermo immagine con `Engine.time_scale`, tremolio della camera), lampo nello shader dello sprite (`flash`, `flash_color`), `CombatEffects` (scia ad arco in pixel e scintilla, provvisorie), `SoundBank` (12 effetti ElevenLabs). Tremolio e lampi riducibili dal pannello (opzioni, 96).
- Misure a schermo: `CombatHud` (`scripts/ui/combat_hud.gd`), vita, fiato e segnali "Deviato!", "Contrattempo!", "Senza fiato".
- Mappatura: come in 67. Salto (`jump`): Spazio, K, pad B; corsa (`run`, tenuta): Shift, pad L3.
- Test: `tests/test_combat.gd`. Un suono ancora in riproduzione alla chiusura conta come risorsa trapelata: il test aspetta la fine dei suoni, `SoundBank` li ferma all'uscita.
- Diorama: `autocombat=1` esegue una sequenza fissa contro il fantoccio (per catture e video).

## Creature del Margine (fase 3, passo 3; 36)

- Valori: `CreatureTuning` (`scripts/combat/creature_tuning.gd`, file `assets/combat/creature_tuning.tres`), sezione "Creature" del pannello F1 con pulsante di salvataggio.
- `scripts/creatures/`: `Voltafaccia` (B31: sempre rivolto al Giorno, a ovest; lato destro, a nord, in ombra con danni doppi), `Raspagelo` (B5: sotto terra non bersagliabile e senza collisione, anello di preavviso sul terreno, scoperto dopo il morso, placca frontale), `Brinacchio` (B1: sente la lanterna aperta da lontano, perde le tracce a sportello chiuso, si attacca e rallenta, si stacca col passo o con un colpo, crosta di brina che para finché l'uncino non la strappa), `Grappolo` (B7: rotola, colpito si scompone in `GrappoloBit`, i superstiti si ricompongono più piccoli).
- Base comune `CombatEnemy`: `can_be_targeted`, `damage_multiplier`, `attack_player`, `reset_enemy`. Dopo una sconfitta il `RoomManager` riporta al punto di partenza le creature della stanza (105).
- Effetto `CombatEffects.ground_ring`: anello sul terreno sopra l'erba, per i preavvisi che la vegetazione fitta nasconderebbe.
- `screenshot_runner.gd` libera la scena e aspetta qualche fotogramma prima di chiudere: un suono ancora in riproduzione alla chiusura conta come risorsa trapelata e fa fallire lo screenshot.
- Test: `tests/test_creatures.gd`; i test di camminata, stanze e combattimento tolgono le creature all'avvio.

## Boss (fase 3, passo 4; 83, 41, 105)

- `BossEnemy` (`scripts/bosses/boss_enemy.gd`): nome e barra della vita nell'HUD mentre il combattimento è attivo (gruppo `active_boss`). `BossArena` (`scripts/bosses/boss_arena.gd`): sveglia il boss all'ingresso nella stanza, ripristina l'arena a schermo nero dopo una sconfitta (`RoomManager.room_restarted`), mostra la vittoria.
- Il Foglione Radicato (`FoglioneRadicato`, `FoglioneArena`): campo a est della Piattaforma (passaggio: il cancello sul bordo est), a x = 60. Foglie sul lato del sole (×0,15), leva (`FieldLever`, un `Interactable` usato con A o E) che sposta il sole a est e inclina il campo (`AnimatableBody3D` incernierato sul bordo est); il boss si gira a 40°/s e scopre il fianco ovest; radici con anello di preavviso, spazzata frontale, foglie chiuse dopo 60 danni.
- Il Vecchio Spartighiaccio (`VecchioSpartighiaccio`, `IceArena`): lago a ovest della Terrazza (passaggio: il sentiero sul bordo ovest), a x = −60. Carica con striscia di preavviso, scudo frontale (×0,1), lastre di ghiaccio 8×8 da 1,5 m: incrinate da una carica, spezzate da una carica successiva; carica verso un buco: fermo sul bordo e scoperto; caduta in acqua: danno e ritorno sull'ultimo punto sicuro (anche il bordo di pietra); pestone se Ottavia è troppo vicina.
- Durante dissolvenze e ripartenze tutte le creature restano ferme (`CombatEnemy` non agisce se Ottavia non ha i comandi).
- Interazione: `OttaviaProto.interact()` usa l'`Interactable` più vicino entro il suo raggio.
- Test: `tests/test_bosses.gd`. I test di combattimento, creature e boss liberano la scena prima di chiudere (suoni ancora in riproduzione = risorse trapelate).

## Enea, la lezione e Tosca (fase 3, passo 5; 81, 82, 20)

- `Enea` (`scripts/companions/enea.gd`, `scenes/companions/enea.tscn`): segue Ottavia, si tiene lontano dalle creature finché non sa attaccare, non muore (colpito cade per `enea_down_seconds`). Conta i segnali `OttaviaCombat.technique_done` (parry, counter, combo, step, hook); dopo `enea_learn_count` impara la mossa (messaggio "Enea ha imparato…", suono `segnale_enea`) e la usa: devia, schiva, colpisce le creature (scoperte, con il solo contrattempo). Non attacca il fantoccio.
- Le creature scelgono il combattente più vicino tra Ottavia ed Enea (`CombatEnemy.find_target`, gruppo `fighters`); i boss puntano solo Ottavia; `target_override` forza il bersaglio (la lezione).
- Lezione della parata (`LessonParry`, `scripts/companions/lesson_parry.gd`): si avvia parlando con Enea (`LessonTalk`, un `Interactable`); Ottavia spiega (battute `DLG_LESSON_PARRY_001`…`008`, ID univoci per il doppiaggio, 59), il giocatore guida Enea contro il fantoccio; due deviazioni e Enea impara la parata. Riquadro dei dialoghi: `DialogueBox` (`scripts/ui/dialogue_box.gd`). Argomento del diorama `lesson=1` per avviarla subito.
- `Tosca` (`scripts/companions/tosca.gd`): compagna del Richiamo, presente se `tosca_present` (pannello F1); aggancia la creatura più vicina davanti a Ottavia entro `tosca_range` e la trascina (i pesanti e i boss si sbilanciano soltanto), poi ricarica per `tosca_cooldown`; barra di ricarica nell'HUD.
- Sprite di Enea e Tosca: segnaposti a una vista (`TODO-DESIGN #81`, `TODO-DESIGN #79`), l'aspetto non è definito nella bibbia.
- Test: `tests/test_companions.gd`.
- Barra della vita delle creature: `EnemyHealthBar` (`scripts/combat/enemy_health_bar.gd`), Sprite3D in pixel da 24×4 px sopra la testa, aggiunta da `CombatEnemy` (non ai boss, che hanno la barra nell'HUD). Compare dal primo colpo, nascosta quando la creatura non è bersagliabile; non vira con la palette.

## Progressione, toppe e difficoltà (fase 3, passo 6; 34, 104, 40)

- `Progression` (`scripts/combat/progression.gd`): tabella per capitolo (fiato, passo, combinazione, perdita, tecnica), `power()`, `knows()`, `chapter_lines()`. Proposta in `docs/progressione.md`, da approvare.
- `OttaviaCombat` legge i valori effettivi solo tramite i getter (`max_stamina()`, `move_speed()`, `combo_length()`, `deflect_window()`, `step_invulnerable_seconds()`, `counter_multiplier()`, `hook_reach()`, `regen_delay()`, `aim_cone_degrees()`), che combinano taratura, capitolo, toppe e difficoltà. `set_chapter()` e `patches` si impostano dal diorama (`apply_settings`).
- `CoatPatches` (`scripts/combat/coat_patches.gd`): tre spazi, quattro toppe di prova. `Difficulty` (`scripts/combat/difficulty.gd`): moltiplicatori per livello, applicati in `CombatEnemy.attack_player`, alla vita in `reset_enemy` e ai preavvisi di creature e boss; il livello sta in `GameOptions.difficulty` (`user://options.cfg`).
- Schermata di fine capitolo: `ChapterScreen` (`scripts/ui/chapter_screen.gd`), mette in pausa e mostra le due righe; si apre con il pulsante del pannello F1 o l'argomento del diorama `chapter_end=1`.
- Lato del mondo delle creature (`world_side` in `CombatEnemy`), usato dalle toppe del freddo e del caldo.
- Test: `tests/test_progression.gd`. Screenshot: `docs/screenshots/fasi/fase3-combattimento/09-fine-capitolo.png`.
- Bot di prova (`AutoFighter`, `scripts/proto/auto_fighter.gd`, solo sviluppo): argomento del diorama `autofight=herd` (i tre Voltafaccia del prato) o `autofight=sparti` (il Vecchio Spartighiaccio), con `autofight_error=<s>` per un errore di tempismo umano (seme fisso). Legge solo lo stato pubblico delle creature (`attack_in`, `attack_deflectable`, `dodge_direction`, `weak_side`, `is_exposed`), stampa una riga `AUTOFIGHT` (tempo, vita rimasta, sconfitte) ed esce. Con `--write-movie` fa il video di confronto tra capitoli.

## Salto e corsa (33, 67)

- Salto: stato `JUMP` di `OttaviaCombat`; `take_jump_impulse()` dà a `OttaviaProto` la velocità verso l'alto (`sqrt(2 · gravità · jump_height)`); lo stato finisce all'atterraggio. Invulnerabilità al decollo (`jump_invulnerable_seconds`, salto sicuro al capitolo 5); in aria gli attacchi con `CombatAttack.ground` vanno a vuoto (`attack_player(..., ground = true)`: Raspagelo, rotolata del Grappolo, pestone dello Spartighiaccio, radici del Foglione). Il segnale `jumped` stacca i Brinacchio.
- Corsa: `run` tenuto, velocità × `run_speed_multiplier`, `run_stamina_per_second` di fiato; niente ricarica mentre si corre; a fiato vuoto si cammina. Un salto preso correndo conserva la velocità di corsa.
- Camera: segue `OttaviaProto.camera_anchor()`, che durante il salto resta all'altezza del terreno (niente sobbalzi; una caduta la porta giù).
- Animazione provvisoria: in aria resta la posa del cammino; la corsa accelera i fotogrammi. Argomento del diorama `autojump=1` per le catture. Screenshot: `docs/screenshots/fasi/fase3-combattimento/10-salto.png`.

## Mezzi e comparse (fase 4a, passo 1)

- `scripts/dev/scale_preview.gd`: mette in fila modelli GLB e sprite PNG (viste sud) su un terreno piatto, alla scala del mondo (30 px/m), e salva un'immagine. `"$GODOT_PATH" --path . --resolution 1280x800 --script res://scripts/dev/scale_preview.gd -- <out.png> <distanza_camera> <x_centro> models=<a.glb,...> sprites=<a.png,...>`. I modelli stanno in fila lungo x, con il davanti (le Ali) verso ovest.
- Meshy, mezzi complessi: text-to-3d meshy-5 non regge edifici a più piani (esce una scatola su ruote). Funziona la strada concetto → 3D: text-to-image nano-banana (3 crediti) e image-to-3d meshy-t2 smart-topology con texture (15 crediti), poi `mesh_simplify.py` e `meshy_pixelize.py`.
- PixelLab, personaggi da testo: `create_character_pro_flash` costa 6 generazioni (5 per la prima immagine, 1 per le 8 rotazioni); solo 1 se si parte da un'immagine già fatta. L'altezza scritta nella descrizione non viene rispettata: la figura riempie la tela (bambini a 46-58 px invece di 34-40). Il riferimento di stile può passare oggetti: con Ottavia come riferimento, Anselmo ha preso bastone e lanterna.
- Mezzi generici (16): `VehicleKit` (`scripts/world/vehicle_kit.gd`) monta un mezzo da una ricetta di `assets/models/vehicles/mezzi_generici.json`: pianale, pile di moduli sul piano da ovest a est (`nome@180` gira il modulo), Generatore sotto il piano, Ali davanti (ovest), Code dietro (est). I moduli (`assets/models/vehicles/moduli/`) non si scalano, così la densità resta 30 px/m. Anteprima: `scale_preview.gd ... kit=1`.
- PixelLab con tela personalizzata (60, 56, 52, 44): la figura occupa il 92-100 % dell'altezza della tela. Il riferimento di stile deve stare dentro la tela: ritagliarlo e ridurlo a 16 colori, così la base64 è corta (circa 1 KB) e non si tronca. I generici si riportano sulla tela 64×64 con i piedi alla riga 60, come Ottavia.
- `meshy_pixelize.py --turn-180`: gira il modello di mezzo giro attorno all'asse verticale (rotazione del nodo radice), per mettere il davanti di un mezzo a ovest. Per rispettare lunghezza e altezza della bibbia si sceglie `--height` in modo che la lunghezza torni (camion-condominio: 12,35 m → 20,0 m).
- Animazioni di Ottavia (fase 4a, passo 2): PixelLab consente 10 lavori insieme; lo zip del personaggio (`/mcp/characters/<id>/download`) risponde 423 finché ci sono lavori in corso, poi contiene `Idle/animations/<nome>/<direzione>/frame_NNN.png`. `tools/ottavia_anim_build.py <cartella zip> <cartella gif> anim:ms ...` pulisce con la pipeline v1 e fa le GIF in griglia. Il ritaglio a 64×64 taglia la punta del bastone in parte della combinazione e della parata.

- Mezzi in movimento (16, 77): `VehicleWheels.attach(mezzo)` (`scripts/world/vehicle_wheels.gd`) taglia le ruote dal modello unico di Meshy (isole di geometria basse, tonde e sottili, trovate unendo i vertici per posizione), le appende a un perno nel loro centro e le fa girare di distanza / raggio; il corpo ondeggia di 5 cm e il Generatore del kit (nodo `Generatore`) batte mentre il mezzo si muove. Le Code (nodo `Code`) serpeggiano con un'onda nel vertex shader di `model_palette.gdshader` (uniform di istanza `sway_*`, a zero per tutti gli altri modelli), che cresce dal punto dove pendono verso la punta. Il modello delle Code pende a -z e striscia verso +z, quindi nel kit si gira di PI/2 per mandarle verso est. Il taglio è in cache per mesh. Va chiamato prima di `ZonePalette.retint_models`. Ruote trovate: pianale lungo 6, pianale corto 4, camion-condominio 8, carro-campo 10, mezzo di testa 8.

## Prologo (fase 4a, passo 3)

- Avvio: `"$GODOT_PATH" --path . res://scenes/prologo/piano_tessibuio.tscn`. Dalla porta sul retro si passa a `scenes/prologo/accampamento.tscn` (`PrologueState.entered_from_door`).
- `scripts/prologue/tessibuio_floor.gd`: il piano dei Tessibuio costruito dal codice con `LevelBlocks` (scatole e cilindri col materiale triplanare, 30 px/m), flusso a passi (risveglio, apri la lanterna, muoviti, Zelinda, chiudi la lanterna, porta). Argomenti di sviluppo: `intro=0`, `lantern=1`, `start_x=<m>`, `step=walk`.
- `scripts/prologue/camp.gd`: l'accampamento (25 mezzi dal kit, tende, 46 persone della folla, brina verso est) e la sequenza della porta: bagliore (attenuato da `GameOptions.flash_strength`, 96), salita in verticale sopra Ottavia e poi in largo, sette righe di narrazione con la finestra dei dialoghi, ritorno. Argomenti: `intro=1`, `wide=1`, `line_seconds=<s>`.
- `HintBanner` (`scripts/ui/hint_banner.gd`): suggerimenti in basso al centro con il tasto del dispositivo usato per ultimo (`InputRemap.main_event` e `event_label`).
- `NpcSprite` (`scripts/world/npc_sprite.gd`): persone disegnate con lo stesso shader di Ottavia (`sprite_billboard_lit`, billboard pieno verso la camera e profondità del quad verticale), più una copia verticale rivolta al sole che proietta l'ombra. Un `Sprite3D` diritto con `BILLBOARD_FIXED_Y` visto a 50° si accorcia di circa un terzo: i personaggi sembravano tozzi accanto a Ottavia. Anche Ottavia nel prologo usa la variante illuminata (`set_shaded(true)`): al buio la mostra solo la lanterna. `NpcSprite.sun_azimuth_degrees` va impostato dalla scena prima di aggiungere le persone (NAN negli interni).
- Test: `tests/test_prologue.gd`.
- Scenario dell'accampamento: `CampScenery` (`scripts/prologue/camp_scenery.gd`). Terreno con `ground_blend.gdshader`: prato, seconda base a chiazze, strada, ghiaia e brina scelti texel per texel da una maschera dipinta dal codice (R strada, G ghiaia, B brina, 1 px per metro) con rumore sui bordi; niente sfumature, la pixel art resta netta. Montagne: tre strisce di heightfield (colline, cresta vicina, cresta lontana) a nord; la veduta d'insieme sta a 13° perché a 22° l'orizzonte usciva dall'inquadratura. Vegetazione: `VegetationScatter` per l'erba e i sassi, elementi del kit piazzati lontano da mezzi e strade.
- `meshy_pixelize.py --brightness <k>`: scala la luminosità della texture prima della palette (le rovine di pietra chiara uscivano quasi bianche).
- `NpcSprite.frame_count` e `frames_per_second`: attese in loop da una striscia orizzontale di celle 64×64 (Zelinda che tesse).
- Passo 4 (spazio 3): `CampTasks` (`scripts/prologue/camp_tasks.gd`) con i cinque compiti in ordine (scatto, salto sulle Code, arrampicata sul carro-campo di Ruggero, rottura delle croste attorno alla Coda, sciame di Brinacchi) e il secondo richiamo; `Breakable` (`scripts/world/breakable.gd`, un bersaglio del combattimento che non attacca), `ClimbSpot` (`scripts/world/climb_spot.gd`, arrampicata automatica spingendo contro la parete). Argomenti: `start_x`, `start_z`, `task=climb|break|fight`, `tasks=0`.
- Foglio di Ottavia v2: `tools/ottavia_sheet_v2.py`; `OttaviaProto` sceglie l'animazione dallo stato del combattimento (colpo: uno dei tre fendenti della combinazione; salto: dalla velocità verticale) e offre `climb_to()` e `play_scripted()` per le scene.
- Passo 5 (spazi 4 e 5): `scripts/prologue/column.gd` e `scenes/prologo/colonna.tscn`: la colonna che avanza verso ovest (1,2 m/s), Mirco da riprendere, due Brinacchi, la corda (`RopeCounter`), il ritorno con `OttaviaCombat.run_drain_multiplier` 2,2 oltre metà strada, il verdetto (catena delle voci, testa della colonna, Anselmo, `ChapterTitle` con la sagoma della lanterna e il titolo). Argomenti: `start_x`, `verdict=1`.
- `tools/strip_from_zip.py`: strisce 64×64 (piedi alla riga 60) dalle animazioni di uno zip di PixelLab; `NpcSprite` conta i fotogrammi dalla larghezza e cambia striscia con `set_strip()`.

## Audio (fase 4a, passo 6; 57, 58, 59, 126, 127)

- Bus in `default_bus_layout.tres`: Music, SFX, Voice, tutti verso Master.
- `GameAudio` (`scripts/audio/game_audio.gd`): nodo autoload `GameAudioNode`, usato solo dalle funzioni statiche (`GameAudio.play_music`, `play_loop`, `play_voice`...), che non fanno nulla dove l'autoload manca. Negli script `--script` l'identificatore di un autoload non compila, il `class_name` sì; l'autoload invece c'è anche lì. Musica con dissolvenza incrociata (continua da una scena all'altra), loop d'ambiente per nome, voce per ID di battuta. Contiene uno `SoundBank`, così ogni scena ha gli effetti.
- Voci (59): `assets/audio/voice/<lingua>/<ID>.ogg`, con l'italiano come riserva. `DialogueBox.show_line` suona la voce della battuta e ne ritorna la durata; `DialogueBox.line_wait` tiene la battuta almeno quanto la voce (sotto un secondo, cioè nei test, resta il tempo breve).
- Effetti: `SoundBank.VOLUMES` fa il missaggio (i file sono tutti normalizzati allo stesso picco). `CombatEnemy.hit_sound` e `defeat_sound` cambiano i suoni di creature e oggetti da rompere. Passi: `OttaviaProto.footstep_sound`, uno ogni 0,8 m (1,04 m di corsa).
- Generazione: `tools/elevenlabs_sfx.py <lista.json> <cartella>` (massimo 2 richieste in parallelo, il limite dell'account; costo dall'header `character-cost`). Musica: `POST /v1/music` con `music_length_ms`, `model_id music_v1`: nessun header di costo, e la chiave non ha `user_read`, quindi il costo non si legge. TTS: `POST /v1/text-to-speech/<voce>`, le voci della libreria condivisa funzionano senza aggiungerle all'account.
- Import: `uv run --with imageio-ffmpeg python tools/audio_import.py <cartella> [--peak dB] [--loop] [--keep-silence] <file.mp3>...`: Ogg Vorbis q5, silenzi tagliati (non nei loop), picco normalizzato (effetti -3, musica -1) o, con `--loudness`, loudness integrata (voci a -18 LUFS, così tutte le voci suonano forti uguali); sotto la narrazione il tema sta a -9 dB; con `--loop` scrive il `.import` con `loop=true`.
- Trasparenza di primo piano (53): il punto globale `player_position` lo aggiorna Ottavia (`OttaviaProto._process`) in ogni scena, non più solo il diorama; con la camera a più di 35 m (vedute d'insieme) il punto va fuori scena e la trasparenza si spegne.
- Voci nel mondo: `GameAudio.play_voice_at(ID, punto)` (AudioStreamPlayer3D, piena a 10 m, udibile fino a 150 m, l'ascoltatore è la camera). Ducking: mentre una voce parla il bus Music scende di 10 dB (40 dB/s) e risale a 16 dB/s; lo stato della voce è a tempo, quindi vale anche nei test. `SpeechBubble` (`scripts/ui/speech_bubble.gd`): riquadro sopra la testa di chi parla, tenuto sul bordo dello schermo se è fuori quadro.
- Titolo del capitolo: `ChapterTitle.show_title(chiave)` 1,5 + 4 + 1,5 s; `interact`, `attack` o `ui_accept` lo saltano alla dissolvenza; il segnale `title_leaving(secondi)` serve a far tacere la musica nello stesso tempo.
- Colori dei mestieri (121): `tools/crowd_garment_masks.py` scrive accanto a ogni sprite della folla `<nome>_mask.png` (bianco = vestiti, deciso per posizione: tra la fascia della testa e quella degli stivali, mani escluse). Lo shader degli sprite tinge la maschera lungo la rampa del mestiere (`CrowdTrades`), tenendo le ombre, poi sbiadisce il davanti (98). `NpcSprite.trade` sceglie il mestiere; la maschera segue la striscia in uso. Anteprima: `scripts/dev/trade_preview.gd -- <out.png> [vista]`. Limite noto: sacchi e fagotti portati sul corpo prendono il colore.
- Interfaccia (125): `UiStyle` (`scripts/ui/ui_style.gd`) tiene colori, pannello e carattere; `UiStyle.FONT_PATH` vuoto usa il carattere del motore, quando sarà scelto il carattere pixel basta impostarlo lì (senza antialiasing, hinting e subpixel). `UiStyle.text_size()` segue `GameOptions.text_scale` (1, 1,25, 1,5; opzione nel menu). `SundialGauge` (vita e fiato), `LanternEmblem` (10 pezzi, uno per dungeon) e `LanternProgress` (stato, solo in memoria finché non c'è il salvataggio). Il menu di pausa (`OptionsMenu`) c'è anche nelle scene del prologo. Argomenti di cattura dell'accampamento: `pause=1`, `lantern=<pezzi>`.
- Carattere (125): Jersey 10 (`assets/ui/fonts/jersey10.ttf`, licenza accanto), importato con antialiasing, hinting e subpixel spenti, niente fallback di sistema; è il carattere del tema di progetto (`assets/ui/ui_theme.tres`, `gui/theme/custom`). La sua griglia è di 28/3 px: a 28 e 56 px i pixel sono interi e regolari, sotto i 28 le lettere si staccano. Dimensioni del testo: 28, 37, 47 px.
- Pilota automatico del prologo (solo sviluppo): argomento `autoplay=1` su una scena del prologo; `PrologueAutoplay` resta sotto la radice tra un cambio di scena e l'altro e preme le azioni con `Input.action_press`, quindi gira tutto come per un giocatore. Video intero: `"$GODOT_PATH" --path . --resolution 1280x800 --write-movie <out.avi> --fixed-fps 30 --quit-after 30000 res://scenes/prologo/piano_tessibuio.tscn -- autoplay=1` (si chiude da solo dopo il titolo).
- Fotogrammi al secondo: `--print-fps`. Sul Mac (M4 Pro) a 1280×800: 75 fissi nell'accampamento e nella colonna (sincronia verticale).
- Folla che gira (121): `CrowdMember` (`scripts/world/crowd_member.gd`) alterna soste e brevi camminate verso punti liberi (il `blocked` della scena esclude mezzi e area dei compiti) e mostra la vista disegnata più vicina alla direzione (camminata: est, sud-est, sud-ovest, ovest, nord-est; ferma: sud, sud-ovest, ovest, nord-ovest). `CrowdBarks` fa dire una frase a chi è entro 4,5 m da Ottavia, uno alla volta, pause di 7 s e 40 s per persona. I contorni dei mezzi dell'accampamento sono in cache.
- Dove andare (106): `ObjectiveMarker` (`scripts/ui/objective_marker.gd`): luce e bagliore sul punto, freccia sul bordo dello schermo quando è fuori quadro; `HintBanner.show_goal()` scrive l'obiettivo sopra il suggerimento. Lo impostano i compiti dell'accampamento, il piano buio e la colonna.
- Città morta (`CampScenery._place_dead_city`): 32 rovine a isolati tra z -82 e -165, seme fisso, distanza minima 13 m, pesi per modello.
