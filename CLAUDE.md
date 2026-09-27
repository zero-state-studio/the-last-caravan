# The Last Caravan: istruzioni per Claude Code

Leggi questo file all'inizio di ogni sessione. Rispondi sempre in italiano.

## Il progetto

Action RPG in un mondo 3D a diorama: ambienti 3D con texture in pixel art, personaggi sprite in pixel art, luci morbide, bagliori e sfocatura di profondità (lo stile che Square Enix chiama "HD-2D": non usare mai quel termine in testi pubblici, di' "3D pixel art"). Motore: Godot 4, GDScript tipizzato. Piattaforma: PC su Steam, con obiettivo verifica Steam Deck. Lingue: italiano e inglese.

- Il design è in `docs/bibbia/` ed è la fonte di verità. Ogni elemento ha un numero fisso (1-98, creature B1-B60): citalo nei commit, nei commenti di design e nelle domande.
- Lo stato del lavoro è in `docs/fasi.md`. Lavora solo sulla fase corrente e non anticipare quelle successive.
- Le decisioni prese sono in `docs/decisioni.md`.

## Regole di lavoro

1. Lavora a passi piccoli. Alla fine di ogni passo: verifica (vedi sotto), commit, resoconto breve.
2. Non prendere decisioni di design al posto dell'autore. Se la bibbia non copre qualcosa, fermati e chiedi, proponendo 2 o 3 opzioni numerate.
3. Elementi "Da definire": non inventarli in modo definitivo. Usa un segnaposto evidente e cercabile, `TODO-DESIGN #numero`.
4. Elementi "In discussione": puoi usarli in un prototipo, ma segnalalo nel resoconto.
5. Non modificare `docs/bibbia/` senza approvazione. Dopo un'approvazione, aggiorna il file giusto e aggiungi una riga a `docs/decisioni.md`.
6. Se una richiesta è ambigua o costosa, chiedi prima di agire.

## Tecnica

- Godot si avvia con `"$GODOT_PATH"`. Al primo avvio annota la versione in `docs/tecnica.md` e non cambiarla senza chiedere.
- Tipizzazione statica ovunque in GDScript. File e cartelle in `snake_case`, `class_name` in `PascalCase`, costanti in `UPPER_SNAKE_CASE`. Codice e commenti tecnici in inglese.
- Scene e risorse in formato testo (`.tscn`, `.tres`). Nessun plugin o addon senza chiedere.
- Nessuna stringa visibile al giocatore scritta nel codice: tutto passa dal sistema di traduzione di Godot, con chiavi in inglese e file per IT ed EN. Ogni battuta di dialogo ha un ID univoco, che servirà ad agganciare il doppiaggio (59).
- Ogni azione di gioco è mappata sia su gamepad sia su tastiera (Steam Deck, 7).
- Texture in pixel art sempre con filtro nearest e senza mipmap sfocate.

### Struttura delle cartelle

```
project.godot
scenes/        scene di gioco
scripts/       script GDScript non legati a una sola scena
assets/        asset approvati e pronti per il gioco
  sprites/ models/ textures/ ui/ audio/music/ audio/sfx/ audio/voice/
localization/  file di traduzione IT/EN
tests/         test automatici
tools/         script di supporto (screenshot, generazione, import). Ha .gdignore
source-assets/ output grezzi dei servizi di generazione. Ha .gdignore
docs/          bibbia, fasi, decisioni, tecnica, registro asset. Ha .gdignore
```

## Verifica

- Dopo ogni modifica al codice, esegui un controllo headless che segnali errori di parsing o di caricamento. Trova il comando giusto per la versione installata e scrivilo in `docs/tecnica.md`.
- Dopo ogni modifica visiva, cattura uno screenshot con lo strumento in `tools/`, guardalo, e solo allora considera il passo concluso. Salva gli screenshot importanti in `docs/screenshots/`.
- La logica di gioco (combattimento, timer della Tregua, salvataggi) va coperta da test automatici quando verrà scritta.

## Servizi di generazione

| Servizio | Accesso | Uso |
|---|---|---|
| PixelLab | MCP `pixellab` | personaggi e creature sprite, animazioni, oggetti, UI |
| Scenario | MCP `scenario` | texture degli ambienti, concept, illustrazioni; modello personalizzato quando pronto |
| Meshy | MCP `meshy` | modelli 3D di ambienti, oggetti e colossi |
| ElevenLabs | API REST con `$ELEVENLABS_API_KEY` (header `xi-api-key`) | musica, effetti sonori, voci |
| Aseprite | riga di comando `"$ASEPRITE_PATH" -b` | rifinitura, spritesheet, palette |
| Godot | MCP `godot` e riga di comando | avvio, scene, debug |

La chiave ElevenLabs ha solo questi permessi: Text to Speech, Effetti Sonori, Generazione Musicale, Voci in lettura. Se serve altro, chiedi.

### Regole per gli asset

- Output grezzi in `source-assets/<servizio>/<AAAA-MM-GG>-<nome>/`. Solo le versioni approvate e lavorate vanno in `assets/`.
- Ogni asset generato ha una riga in `docs/asset-log.csv`: file, servizio, modello, prompt, data, costo stimato, note. Serve per la dichiarazione AI su Steam (grafica, musica e voci generate vanno dichiarate) e per poter rigenerare.
- Mai usare immagini di altri giochi (per esempio The Adventures of Elliot) come input, riferimento o materiale di addestramento. Solo immagini nostre.
- Modelli Meshy: sempre semplificati (low-poly, remesh) e con texture pixel art a bassa risoluzione, filtro nearest (54).
- Ottavia e i personaggi asimmetrici si disegnano in 8 direzioni, una per una, mai specchiati. Le creature simmetriche possono usare 5 direzioni più 3 specchiate (36).
- Misure provvisorie degli sprite: tela 40×56 pixel, Ottavia alta circa 42 pixel, finché la fase 1 non le fissa (49).

### Budget

- Prima di ogni generazione stima il costo; dove esiste, usa la simulazione (per esempio `dryRun` su Scenario).
- Chiedi conferma se una singola richiesta o un gruppo di richieste supera: PixelLab 20 generazioni, Scenario 200 unità di calcolo, Meshy 50 crediti, ElevenLabs 5.000 crediti.
- Mai rigenerare in ciclo "finché viene bene": al massimo 3 tentativi, poi mostra i risultati e chiedi.
- In ogni resoconto indica i crediti spesi per servizio.

## Sicurezza

- Mai scrivere chiavi API in file, commit, log o messaggi. Mai stamparle a schermo.
- Mai acquistare nulla, cambiare piani o impostazioni degli account dei servizi.

## Git

- Un commit per ogni passo concluso, con messaggio chiaro e il numero dell'elemento, per esempio: `fase1: camera fissa con parametri regolabili (50)`.
- I file binari (immagini, audio, modelli) passano da Git LFS: le regole sono in `.gitattributes`.

## Resoconto di fine passo

Cosa è stato fatto; come è stato verificato (con il percorso degli screenshot); crediti spesi per servizio; domande aperte, numerate.
