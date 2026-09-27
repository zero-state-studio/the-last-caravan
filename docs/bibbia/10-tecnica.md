# Tecnica e pipeline

*Quello che serve a Claude Code per costruire il gioco.*

## 60. Motore di gioco  [Definito]

Godot 4, con GDScript tipizzato. Scene, risorse e script sono semplice testo, quindi Claude Code costruisce e modifica tutto senza passare dall'editor. Si avvia, si testa e si esporta da riga di comando. È gratuito e open source, senza royalty sulle vendite. Ha già tutti gli ingredienti dello stile: sprite in 3D che guardano sempre la camera, texture pixelate, sfocatura di profondità, bagliori, foschia volumetrica.

**Resta da definire:** Fissare una versione stabile e non cambiarla a metà progetto. Il punto debole è la resa delle luci, meno raffinata di Unity: va verificata subito con il prototipo visivo.

## 61. Verifica automatica  [Da definire]

Test automatici eseguiti senza editor, più un comando che avvia il gioco, salva uno screenshot e si chiude. Così Claude Code può controllare da solo il risultato di ogni modifica, anche visivo.

## 62. Integrazione con Steam  [Da definire]

Obiettivi, salvataggi nel cloud e overlay tramite GodotSteam.

## 63. Strumenti e ruoli  [Definito]

PixelLab per sprite e animazioni. Aseprite per rifinirli ed esportare gli spritesheet. Meshy per i modelli 3D degli ambienti. Scenario per texture, concept e illustrazioni. ElevenLabs per musica, effetti e voci. Steam per la distribuzione.

## 64. Collegare gli strumenti a Claude Code  [Da definire]

Per ogni strumento: accesso tramite API o connettore, gestione delle chiavi, script che Claude Code usa per generare e importare gli asset.

## 65. Regole per Claude Code  [Definito]

Sono nel file `CLAUDE.md` del progetto: fonte di verità, lavoro a passi con verifica e commit, nessuna decisione di design presa da Claude Code, segnaposti `TODO-DESIGN` per ciò che è da definire, registro degli asset generati per la dichiarazione AI, soglie di budget oltre le quali chiedere conferma, divieto di usare immagini di altri giochi. Claude Code lo legge a ogni sessione, e si affina man mano.

## 66. Struttura del progetto  [Definito]

Quella descritta in `CLAUDE.md`: progetto Godot nella radice, cartelle per scene, script, asset approvati, traduzioni, test, strumenti, output grezzi dei servizi e documentazione. Le cartelle che Godot non deve importare hanno un file `.gdignore`. I file binari passano da Git LFS.

## 67. Controlli  [Definito]

Pensati prima per il gamepad, come richiede la verifica Steam Deck. Gamepad: A interagire, X Colpo, Y Uncino, B Passo, LB Parata, RB Lanterna, RT Richiamo, Menu opzioni (su PlayStation: croce, quadrato, triangolo, cerchio, L1, R1, R2, Options). Tastiera e mouse, con la mano sinistra su WASD senza spostarla: tasto sinistro del mouse Colpo, tasto destro Parata, barra spaziatrice Passo, Q Uncino, E interagire, R Richiamo, F Lanterna, Esc opzioni. Il mouse non mira: Colpo e Uncino seguono la direzione del movimento con l'aiuto alla mira, come con il gamepad, così la sensazione è la stessa su tutti i comandi. Tutti i comandi sono rimappabili dalle opzioni (96).
