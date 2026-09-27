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

## 65. Regole per Claude Code  [Da definire]

Il file CLAUDE.md nel progetto, con specifiche, convenzioni e divieti. Claude Code lo legge a ogni sessione: è lì che confluisce tutto ciò che definiamo in questa pagina.

## 66. Struttura del progetto  [Da definire]

Cartelle, nomi dei file, organizzazione degli asset.

## 67. Controlli  [In discussione]

Pensati prima per il gamepad, come richiede la verifica Steam Deck. Proposta di partenza: A interagire, X Colpo, Y Uncino, B Passo, LB Parata, RB Lanterna, RT Richiamo (su PlayStation: croce, quadrato, triangolo, cerchio, L1, R1, R2).

**Resta da definire:** La mappatura di tastiera e mouse, da proporre nella fase 3.
