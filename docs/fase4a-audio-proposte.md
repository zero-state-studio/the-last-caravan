# Fase 4a, passo 6: proposte per l'audio

*Approvate e generate il 2026-09-28: voci O1, A2 e la catena proposta; testi della musica M1-M4 come sotto; 27 effetti (lista in `source-assets/elevenlabs/2026-09-28-sfx-prologo/effetti.json`). Proposta originale (PROMPT-04, passo 6): Voci solo per la narrazione di Ottavia e per la catena del verdetto, come prova provvisoria, con voci già presenti nella libreria di ElevenLabs (59). Musica come in 126, effetti come in 127.*

## Voci

Tutte in italiano standard, dalla libreria condivisa di ElevenLabs. I link fanno ascoltare il campione dell'autore della voce.

### Ottavia (sessant'anni, rigida e diretta con tutti, narrazione in prima persona)

| # | Voce | Perché | Ascolto |
|---|---|---|---|
| O1 | Elettra, attrice matura (`G0q9AYE8QsarSbMtaIEu`) | Matura e profonda, può essere dura o morbida: adatta al tono asciutto di Ottavia | [campione](https://storage.googleapis.com/eleven-public-prod/database/workspace/6cb621affda64691adf95cc9642fdc3d/voices/G0q9AYE8QsarSbMtaIEu/01W2GUnOY9BfrVIFGwWi.mp3) |
| O2 | Elena (`zORK9zlVk5JLkgvi02K9`) | Bassa e autorevole, lenta, con pause deliberate: buona per la narrazione del mondo | [campione](https://api.us.elevenlabs.io/v1/voices/zORK9zlVk5JLkgvi02K9/previews/audio?payload=eyJ2b2ljZV9zb3VyY2UiOiJjdXN0b20iLCJ3b3Jrc3BhY2VfaWQiOiJhNGU0ZmZjOWY2YjA0MDQ3OTU1NTg5Mjg4YmFmZDdjNiIsImZpbGVuYW1lIjoiZTJjMjU0MTYtZDg1ZC00Mjc4LTliNmYtN2RiYzU4Y2EyMGU2Lm1wMyIsInRpbWVzdGFtcCI6MTc5MDYwMDQwMDAwMDAwMH0%3D) |
| O3 | Morgaine (`BMLpHVZqLTDQfQalqMJJ`) | Scura e drammatica: la più epica, forse troppo teatrale per Ottavia | [campione](https://storage.googleapis.com/eleven-public-prod/database/workspace/313555e6488046d5bb52335614916a55/voices/BMLpHVZqLTDQfQalqMJJ/ee65cd4f-f55f-498d-b143-781d4f8eb0c5.mp3) |

### Anselmo (cinquant'anni, attento e gentile, l'ultima voce della catena)

| # | Voce | Perché | Ascolto |
|---|---|---|---|
| A1 | Luigi (`KUqzTMhYFYqnFWfMUjfX`) | Caldo e rassicurante, naturale | [campione](https://storage.googleapis.com/eleven-public-prod/database/workspace/5bf5d0fc0232419a8c0fa2a93e656e42/voices/KUqzTMhYFYqnFWfMUjfX/1d789cd7-3e24-4413-ab31-52847a068638.mp3) |
| A2 | Dade M, voce notturna (`r0Vl7ChATyljg1s6iN8z`) | Lento, espressivo, intimo: adatto a «Dammi la mano» | [campione](https://storage.googleapis.com/eleven-public-prod/database/workspace/ed9b05e6324c457685490352e9a1ec90/voices/r0Vl7ChATyljg1s6iN8z/V0tM10qaesm8ZYbxEoXL.mp3) |
| A3 | Gianky (`XvhFUZxcWhVLTd5ItX8K`) | Naturale, da racconto, più neutro | [campione](https://storage.googleapis.com/eleven-public-prod/database/workspace/87e8ed810aad4544b0684934b355db4b/voices/XvhFUZxcWhVLTd5ItX8K/039e0927-4e3e-42b3-9c93-2ccf53f16aa9.mp3) |

### Le altre voci della catena (una per battuta, sempre più vicine)

Proposta, senza scelta a tre perché sono voci di passaggio: «Il Sindaco dice...» Nonno Ben (anziano); «...la Serrafila è arrivata oltre il limite.» Valeria (donna adulta); «...dieci Tregue.» Jorgos (uomo adulto); «...poi la lanterna.» Luigi o la voce scelta per Anselmo (il passaggio all'ultima voce).

## Musica (126)

Nessuna musica nel piano buio: solo il battito attutito dei Generatori (un effetto, sotto). Nella catena del verdetto la musica tace.

| # | Dove | Durata | Testo della richiesta (inglese, per ElevenLabs Music) |
|---|---|---|---|
| M1 | Porta e narrazione: il tema di Ottavia intero | 50 s | Solo hurdy-gurdy playing a slow, melancholic folk melody in D dorian, 68 bpm, the full theme stated once from beginning to end. Underneath, a very soft, low, muffled drum pulse like a slow heartbeat. In the second half a bass clarinet joins with a gentle counter-melody and a frame drum enters lightly. Warm, intimate, wide, sunset feeling. Acoustic, no vocals, no choir, no synths. |
| M2 | L'accampamento che smonta: versione leggera e ritmata | 90 s, in loop | Light, rhythmic acoustic folk arrangement of a hurdy-gurdy melody in D dorian, 96 bpm. Frame drum groove, plucked metal strings, bass clarinet counter-line, a busy but hopeful mood, people packing up a camp at sunset. Loopable, steady energy, no vocals, no synths. |
| M3 | Il ritorno con Mirco: tensione, battito più rapido | 75 s, in loop | Tense, urgent acoustic piece at 122 bpm driven by a fast low drum pulse like a racing heartbeat. Low bowed strings, sparse glassy and icy textures, short broken fragments of a hurdy-gurdy melody in D dorian. Rising tension, cold night approaching. Loopable, no vocals, no synths. |
| M4 | Sul titolo: la prima frase del tema, lasciata a metà | 14 s | Solo hurdy-gurdy playing only the first phrase of a slow melancholic folk melody in D dorian, 68 bpm, then it stops unresolved in the middle of the phrase and rings out into silence. Intimate, no other instruments, no vocals. |

## Effetti sonori (127)

Una richiesta ElevenLabs Sound Effects ciascuno, 0,5-4 s (i loop più lunghi): cigolio della branda e respiro nel buio (due effetti); battito dei Generatori lento, attutito dentro, e più rapido fuori (loop); fruscio delle tende; sportello della lanterna, apertura e chiusura (c'è già un provvisorio della fase 3: da rifare); ronzio della fiamma (loop); porta del camion che si apre e vento che entra; passi su erba secca e su brina; salto e atterraggio; prese dell'arrampicata; bastone su legno, su ghiaccio e su creature; arbusti e croste che si spezzano; gemito metallico della Coda che si libera; zampettio dello sciame di Brinacchi, colpo subito e sconfitta; parata e deviazione; respiro affannato; la corda che si annoda; brusio della folla (loop); tromba parlante dello Gnomone.

## Costi stimati (ElevenLabs, tetto della fase 15.000)

| Cosa | Stima |
|---|---|
| Voci: narrazione (7 righe, circa 420 caratteri), catena (4 righe) e Anselmo (2 righe), circa 650 caratteri; con una seconda ripresa | 700-1.400 |
| Musica: circa 3,8 minuti in quattro brani | da misurare sul primo brano (il costo per minuto della musica non è leggibile dallo strumento); stima 3.000-8.000 |
| Effetti: circa 26, con qualche seconda prova | 400-800 |
| **Totale** | **4.100-10.200** |

## Da sapere

- Per usare le voci della libreria condivisa, ElevenLabs può chiedere di aggiungerle prima alle voci dell'account. La chiave ha solo il permesso di lettura delle voci: se serve aggiungerle, te lo dirò e sceglierai tu se farlo dal sito.
- Le voci sono di prova e solo in italiano; l'inglese resta in sottotitoli.
