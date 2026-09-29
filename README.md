# The Last Caravan

Action RPG in un mondo 3D a diorama, con ambienti 3D dalle texture in pixel art e personaggi sprite in pixel art. Motore: Godot 4. Lingue: italiano e inglese.

Il gioco è in sviluppo. Per ora si può giocare il **prologo**, dal risveglio di Ottavia fino al titolo «Ne restano dieci».

> Non esiste ancora una versione pronta da scaricare e avviare con un doppio clic. Per giocare bisogna scaricare il progetto e aprirlo con Godot, come spiegato qui sotto.

## Cosa serve

- **Accesso al repository** `zero-state-studio/the-last-caravan` su GitHub. È privato: chiedi di essere aggiunto all'organizzazione.
- **Git** e **Git LFS**. Immagini, modelli 3D, audio e video sono salvati con Git LFS: senza LFS il gioco si apre senza grafica né suoni.
- **Godot 4.7.2** (versione *standard*, non .NET). Serve proprio questa versione: con altre versioni il progetto può dare errori.
- Un computer con una scheda video che supporti Vulkan o Metal (il gioco usa il renderer Forward+). Sviluppato e provato su Mac con Apple Silicon.
- Consigliato: un **gamepad** (Xbox, PlayStation o simili). Si gioca anche con tastiera e mouse.

## 1. Installa Git LFS

Una volta sola per computer:

```sh
# macOS (con Homebrew)
brew install git-lfs

# Windows: Git LFS è già incluso in "Git for Windows"
# Linux (Debian/Ubuntu)
sudo apt install git-lfs
```

Poi attivalo:

```sh
git lfs install
```

## 2. Scarica il progetto

```sh
git clone https://github.com/zero-state-studio/the-last-caravan.git
cd the-last-caravan
git lfs pull
```

Il download pesa più di 1 GB. Per controllare che i file LFS siano arrivati davvero:

```sh
git lfs ls-files | head
```

Se i file elencati hanno un asterisco `*` dopo il codice, sono stati scaricati. Se hanno un trattino `-`, ripeti `git lfs pull`.

Per aggiornare il gioco alla versione più recente, più avanti:

```sh
git pull
git lfs pull
```

## 3. Installa Godot 4.7.2

Scaricalo dall'archivio ufficiale: <https://godotengine.org/download/archive/> (cerca **4.7.2-stable**, versione standard).

- **macOS**: apri lo zip e trascina `Godot.app` in Applicazioni. Se al primo avvio macOS lo blocca, apri Impostazioni di Sistema > Privacy e sicurezza e scegli «Apri comunque».
- **Windows**: estrai lo zip e avvia `Godot_v4.7.2-stable_win64.exe`.
- **Linux**: estrai lo zip e rendi eseguibile il file (`chmod +x`).

## 4. Avvia il prologo

### Dall'editor di Godot (il modo più semplice)

1. Avvia Godot e, nella finestra dei progetti, scegli **Importa**.
2. Seleziona il file `project.godot` nella cartella `the-last-caravan` e conferma.
3. La prima apertura richiede qualche minuto: Godot importa tutte le risorse. Aspetta che la barra in basso finisca.
4. Nel pannello **FileSystem** (in basso a sinistra) apri `scenes/prologo/piano_tessibuio.tscn` con un doppio clic.
5. Premi **F6** (su macOS **Cmd+R**), oppure il pulsante «Esegui la scena corrente» in alto a destra.

Attenzione: il pulsante ▶ «Esegui il progetto» (F5) oggi avvia la scena di prova dello sviluppo, non il prologo.

### Da riga di comando

Dalla cartella del progetto:

```sh
# macOS
/Applications/Godot.app/Contents/MacOS/Godot --path . res://scenes/prologo/piano_tessibuio.tscn

# Windows (PowerShell), adatta il percorso di Godot
& "C:\percorso\Godot_v4.7.2-stable_win64.exe" --path . res://scenes/prologo/piano_tessibuio.tscn

# Linux
./Godot_v4.7.2-stable_linux.x86_64 --path . res://scenes/prologo/piano_tessibuio.tscn
```

Se è la prima volta, lancia prima `Godot --headless --path . --import` e aspetta che finisca: importa le risorse, e senza questo passaggio il primo avvio può mostrare errori.

Il prologo passa da solo da una scena all'altra (il piano dei Tessibuio, l'accampamento, la colonna) fino al titolo.

## Comandi

| Azione | Tastiera e mouse | Gamepad (nomi Xbox) |
|---|---|---|
| Muoversi | W A S D o frecce | levetta sinistra o croce |
| Correre | Shift | pressione della levetta sinistra (L3) |
| Interagire, parlare, avanti nei dialoghi | E | A |
| Attaccare | J o clic sinistro | X |
| Parare | L o clic destro | LB |
| Saltare | Spazio o K | B |
| Uncino | Q | Y |
| Aprire e chiudere la lanterna | F | RB |
| Chiamare | R | RT |
| Opzioni | Esc | Menu (Start) |

I suggerimenti a schermo mostrano sempre il tasto del dispositivo che stai usando. Non tutti i comandi servono nel prologo: il gioco li introduce quando servono.

## Lingua

Il gioco usa la lingua del sistema operativo: italiano se il sistema è in italiano, altrimenti inglese.

## Problemi comuni

- **Tutto grigio o rosa, niente sprite, niente suoni**: i file LFS non sono stati scaricati. Esegui `git lfs install` e poi `git lfs pull` nella cartella del progetto.
- **Errori all'apertura o script che non si caricano**: controlla di usare Godot **4.7.2** standard (non .NET, non un'altra versione).
- **Il primo avvio è lento o mostra errori di importazione**: è l'importazione iniziale delle risorse. Aspetta che finisca, chiudi e riavvia.
- **Il gamepad non risponde**: collegalo prima di avviare il gioco. Su macOS i controller Xbox e PlayStation recenti funzionano via Bluetooth o cavo.

## Per chi sviluppa

Le istruzioni di lavoro sono in `CLAUDE.md`, il design in `docs/bibbia/`, lo stato delle fasi in `docs/fasi.md` e le note tecniche (versioni, controlli automatici, screenshot) in `docs/tecnica.md`.
