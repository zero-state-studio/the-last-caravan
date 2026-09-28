# Primo prompt: fasi 0 e 1

Leggi `CLAUDE.md`, `docs/fasi.md`, `docs/decisioni.md` e tutti i file in `docs/bibbia/`. Poi esegui la **fase 0**. Alla fine fermati, mandami il resoconto e aspetta il mio ok prima di iniziare la fase 1.

## Fase 0: Fondamenta

1. **Strumenti.** Verifica `"$GODOT_PATH" --version` e `"$ASEPRITE_PATH" --version`, controlla che `claude mcp list` mostri pixellab, scenario, meshy e godot connessi, e che la chiave ElevenLabs risponda leggendo l'elenco delle voci. Annota versioni e risultati in `docs/tecnica.md`. Se qualcosa non funziona, fermati e dimmelo.
2. **Progetto Godot.** Crea `project.godot` nella radice del repository, con la struttura di cartelle di `CLAUDE.md`. Renderer Forward+, salvo motivi contrari da spiegarmi. Filtro texture predefinito nearest. Finestra di base 1280×800 (Steam Deck), ridimensionabile. Mappa di input per il movimento in 8 direzioni, sia con gamepad sia con tastiera. Sistema di traduzione predisposto per IT ed EN, con una chiave di prova.
3. **Strumenti di verifica.** In `tools/`: un comando per il controllo headless e uno che avvia una scena, salva uno screenshot e chiude. Provali entrambi e scrivi i comandi in `docs/tecnica.md`.
4. **Test di connessione.** Una generazione minima per servizio, per verificare che la catena funzioni fino ai file su disco: PixelLab, uno sprite 32×32 qualsiasi; Scenario, un'immagine al costo più basso, prima in simulazione; Meshy, un oggetto semplice a basso numero di poligoni; ElevenLabs, un effetto sonoro di 2 secondi. Salva tutto in `source-assets/test/`, registra ogni file in `docs/asset-log.csv` e dimmi quanto ha consumato ciascuno.
5. **Commit.** Inizializza Git LFS se serve, poi fai il commit.

## Fase 1: Prototipo visivo (solo dopo il mio ok)

**Scopo.** Trovare, guardando, i valori di camera (50), misure degli sprite (49) e palette di base (51). Non è ancora grafica definitiva.

- **La scena.** Un diorama di circa 30×30 metri con più livelli di altezza: una terrazza, delle scale, un ponte. Terreno e pareti con texture pixel art a bassa risoluzione, filtro nearest. Per gli oggetti usa soprattutto forme semplici; al massimo 3 oggetti Meshy semplificati e ritexturizzati, per provare la catena dei modelli 3D (54).
- **Ottavia provvisoria.** Usa `source-assets/test/ottavia_test_sheet.png`: fotogrammi da 40×56, in quest'ordine: sud 1, sud 2, est 1, est 2, nord 1, nord 2, ovest 1, ovest 2. Mostrala come sprite nel mondo 3D alto circa 1,6 metri, e prova sia il billboard completo sia quello con asse verticale fisso. Movimento in 8 direzioni: per le diagonali usa per ora la vista cardinale più vicina. Animazione di attesa a 2 fotogrammi.
- **Camera.** Segue Ottavia con orientamento fisso (50). Angolo regolabile tra 30 e 70 gradi, distanza, campo visivo, e un'opzione ortografica.
- **Luce di tramonto perenne (48).** Sole basso e caldo dal lato del Giorno, ombre lunghe, cielo sfumato, bagliore, foschia volumetrica, sfocatura vicina e lontana per l'effetto diorama (47).
- **Primo piano (53).** Qualche pianta in primo piano che copra Ottavia, per provare la dissolvenza.
- **Pannello di regolazione** (tasto F1): cursori per angolo, distanza e campo visivo della camera, sfocatura vicina e lontana, dimensione dei pixel degli sprite, angolo e colore della luce. Un pulsante salva le impostazioni e uno screenshot.
- **Consegna.** Tre combinazioni di impostazioni diverse, per esempio camera a 40, 50 e 60 gradi, ciascuna con screenshot in `docs/screenshots/` e i valori usati. Aggiungi una nota sulle prestazioni sul Mac mini.
- **Budget della fase 1:** al massimo 20 generazioni PixelLab, 200 unità Scenario, 60 crediti Meshy, niente ElevenLabs.

Alla fine fermati e chiedimi di scegliere.
