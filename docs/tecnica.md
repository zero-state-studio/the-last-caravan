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
- Scenario: un solo team ("Gianlucaricaldone's Organization", `team_boscukTE1AfcStGzcGfPCBSq`) con un solo progetto ("Nessuno", `proj_e3G6TyKNVH3TRmGEBhrB8Aym`). Gli strumenti di scrittura vogliono i due ID espliciti.
- Meshy: `meshy_download_model` accetta `save_to` con percorso assoluto; senza, salva in `meshy_output/` nella radice (da evitare).

## Comandi di verifica

- Comando per il controllo headless: **`tools/check.sh`**
  - `"$GODOT_PATH" --headless --path . --import` importa le risorse;
  - `"$GODOT_PATH" --headless --path . --script res://tests/run_tests.gd` esegue i test: impostazioni del progetto, mappa di input (tastiera e gamepad per ogni azione), traduzioni IT/EN, caricamento e compilazione di ogni scena e script in `scenes/`, `scripts/`, `tests/`;
  - fallisce (exit 1, stampa i log) se un comando esce con errore o se compaiono righe `SCRIPT ERROR`, `Parse Error`, `ERROR:`, `Failed to load`, `FAIL:`. Verificato con uno script rotto di prova.
- Comando per lo screenshot: **`tools/screenshot.sh <res://scena.tscn> <uscita.png> [fotogrammi=30] [LxA=1280x800]`**
  - esempio: `tools/screenshot.sh res://scenes/dev/smoke_test.tscn docs/screenshots/2026-09-27-fase0-smoke-test.png`
  - apre una finestra vera (il rendering serve la GPU, quindi niente `--headless`), attende i fotogrammi, salva il PNG con `scripts/dev/screenshot_runner.gd` e chiude. Fallisce se il file non viene scritto.

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
- Scena di prova: `scenes/dev/smoke_test.tscn` (scena principale provvisoria): cielo, sole, un cubo e l'etichetta tradotta. Screenshot: `docs/screenshots/2026-09-27-fase0-smoke-test.png`.
