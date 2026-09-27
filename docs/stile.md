# Guida di stile

Versione 1.1, 27 settembre 2026 (fase 2: passo 1, aggiornata dopo il passo 4). Traduce in regole pratiche gli elementi 46-54 e 99-101 della bibbia. Vale per chi genera asset (servizi e Claude Code) e per chi li rifinisce in Aseprite. Anteprima della palette accanto a Ottavia v1: `screenshots/2026-09-27-fase2-palette-ottavia.png`.

## Descrizione dello stile per i servizi di generazione

Nei prompt si usa sempre questa formula, mai nomi di altri giochi, studi o il termine "HD-2D":

> 3D diorama, low-poly models with low-resolution pixel-art textures, nearest filtering, soft warm sunset light, cool blue-violet shadows

Per le texture si aggiunge: "seamless tileable texture, detailed pixel-art shading with many small flecks, cracks and hue variation, up to 8 shades per material, no dithering, seen from above / from the front". Per le vedute d'insieme: "tilted top-down view at about 50 degrees, sun low on the left".

## Densità

**30 pixel per metro** per tutto: personaggi, terreno, rocce, piante, modelli (49, 54). Un pixel vale 3,3 cm. Regole e controlli in `tecnica.md`, "Lista di controllo per ogni texture".

A 1280×800 con la camera della fase 1 (20 m, 35°) un texel a 30 px/m occupa circa 1,8 pixel dello schermo; a 60 px/m circa 0,9, e sul terreno inclinato meno ancora. Prova delle due densità: `screenshots/2026-09-27-fase2-densita-30-60.png`. Scelta (54): 30 px/m anche per gli ambienti; a 60 px/m la grana va sotto il pixel dello schermo e sfarfalla.

## Palette di base (51)

32 colori, in `assets/palette/`:
- `palette_v1.gpl`: palette per Aseprite, da caricare con Palette > Load Palette (verificata: 32 colori);
- `palette_v1.png`: striscia di 32×1 pixel;
- `palette_v1_preview.png`: campioni ingranditi.

Si rigenera con `tools/palette_v1.py`. È una prima versione: i codici esatti restano da confermare con le immagini di riferimento del passo 2 (51, "Resta da definire").

**Palette v2 degli ambienti** (51): 64 colori, `assets/palette/palette_v2_env.{gpl,png,_preview.png}`, generata da `tools/palette_v2.py`. Contiene la v1, un tono intermedio (in OKLab) tra ogni coppia di colori vicini di ogni rampa, e 7 varianti di tinta: sottobosco `#2A3020`, verde acqua `#2F5A4E` `#4F8A72`, muschio `#9C9A3C` `#C2BE5E`, sentiero rosso `#6B3326` `#9A5236`. Vale per terreno, rocce, piante e modelli 3D; personaggi, creature e interfaccia restano sulla v1.

| Gruppo | Uso | Colori |
|---|---|---|
| Luce (8) | Rampa calda: superfici al sole, dal bruno dell'ombra calda al riflesso del sole | `#2B1B17` `#4E2A1E` `#7A3F22` `#A85E2A` `#D48A3A` `#EDB25A` `#F7D58C` `#FFF1CF` |
| Ombra (7) | Rampa fredda: ombre e luce ambientale, blu-viola; `#1E1A33` è il contorno dei personaggi | `#141125` `#1E1A33` `#2E2A52` `#433F73` `#5C5A94` `#7D7DB5` `#A7A9D4` |
| Crepuscolo (8) | Centro della fascia abitabile: vegetazione, terra, pietra | `#3E4424` `#5E6B2E` `#7E8C3A` `#A4AC5A` `#5A3F2B` `#806042` `#9A8C7A` `#C4B8A2` |
| Notte (4) | Varianti verso la Notte: ardesia, brina, pietra fredda | `#3B4163` `#6E7896` `#8F97B0` `#C8D3E6` |
| Giorno (4) | Varianti verso il Giorno: ocra, sabbia, osso sbiancato | `#9E6A2C` `#C9953F` `#E3CFA0` `#F4EEDC` |
| Accento (1) | Vetro della lanterna, l'unica luce della Notte | `#FFC46B` |

Regole d'uso:
- **Luci calde, ombre fredde.** Su ogni superficie il lato al sole scala verso la rampa Luce, il lato in ombra verso la rampa Ombra. Mai scurire un colore aggiungendo solo nero.
- **Verso la Notte** i colori del Crepuscolo cedono il posto alla rampa Notte; **verso il Giorno** alla rampa Giorno. In gioco lo fa anche il viraggio per zona (51); le texture di base restano sui colori del Crepuscolo.
- **I personaggi** hanno palette propria: Ottavia v1 ne usa 162 colori, presi dalle sue rotazioni approvate. I colori chiave coincidono con la palette di base: cappotto ≈ ardesia `#3B4163`, contorno `#1E1A33`, vetro della lanterna `#FFC46B`. I nuovi personaggi partono dalla palette di base e aggiungono solo i colori che li rendono riconoscibili.
- **Interfaccia** (55, da definire): parte dalla rampa Ombra per i fondi e dalla rampa Luce per testi e accenti. Non vira mai.

## Contorni

- **Personaggi e creature:** contorno scuro di 1 pixel, `#1E1A33` (come Ottavia v1). Staccano dal fondo e restano leggibili in combattimento.
- **Ambienti e modelli 3D:** nessun contorno. In 3D i bordi li disegnano già luce, ombre e sfocatura; un contorno dipinto nella texture comparirebbe a metà delle facce, nei punti sbagliati.
- **Vegetazione piatta** (piani incrociati dell'erba, piante in primo piano): nessun contorno, per fondersi con la vegetazione 3D. Le piante di prova della fase 1 hanno un contorno selettivo: vanno rifatte senza.

## Luce (48, 100, 47)

Valori della fase 1, ora predefiniti (`scenes/proto/diorama.tscn`, `scripts/proto/proto_settings.gd`):

| Elemento | Valore |
|---|---|
| Sole | colore `#FFB873` (1,0; 0,72; 0,45), intensità 2, altezza 14°, direzione 300° cioè da ovest-sudovest: da sinistra e un po' dal lato della camera (100) |
| Ombre del sole | attive, distanza massima 80 m |
| Luce ambientale | colore `#8073D9` (0,5; 0,45; 0,85), intensità 0,8, contributo del cielo 0,5: è lei a dare il blu-viola alle ombre |
| Cielo | zenit `#4D428F`, orizzonte `#FFAD6B` |
| Foschia | di distanza densità 0,003 con prospettiva aerea 0,6; volumetrica densità 0,008, colore `#F2E0D1`, anisotropia 0,6 |
| Bagliore | intensità 0,7, soglia 0,85 |
| Occlusione ambientale (SSAO) | raggio 1,2, intensità 1,6 |
| Sfocatura (47) | vicina fino a 2 m prima del punto di fuoco, lontana da 3 m dopo; intensità 0,2; camera a 20 m, 50°, campo visivo 35° (50) |
| Viraggio (51) | intensità 1; verso il Giorno ×(1,12; 1,04; 0,86), verso la Notte ×(0,72; 0,74; 1,05) |

Nelle texture **non si dipingono luce e ombra direzionali forti**: le fa il motore, e un'ombra dipinta sarebbe sbagliata appena il modello ruota. Si dipinge solo il volume interno del materiale (fessure, venature, grumi), con la luce generica dall'alto a sinistra.

## Materiali alla nostra densità

A 30 px/m un pixel è 3,3 cm: i dettagli più piccoli di 3 cm non esistono. Fino a 8 toni per materiale dalla palette v2, forme grandi e leggibili arricchite da micro-dettaglio (vedi sotto), niente retino.

### Ricchezza degli ambienti

Regole generiche, scritte dopo aver guardato esempi della direzione voluta (le immagini di altri giochi non si usano mai come input, riferimento nei prompt o addestramento):

1. **Micro-dettaglio.** Sopra le forme grandi, granelli e sassolini di 1-2 px, crepe sottili di 1 px, fili d'erba e muschio sparsi a gruppi, non a caso uniforme.
2. **Più sfumature e tinta che varia.** Ogni materiale usa 6-8 toni e cambia tinta al suo interno: il muschio va dal verde al giallo, la terra del sentiero verso il rosso-bruno, l'erba fresca verso il verde acqua.
3. **Rilievo da geometria e luce.** Crepe e spigoli delle rocce sono modellati, non solo dipinti; ombre di contatto e occlusione forti; nelle zone buie pozze di luce calda.
4. **Vegetazione a ciuffi.** Piante fatte di molte foglie o fili sottili, con un bordo chiaro di 1 px sul lato del Giorno; contrasto di tinta forte tra piante vicine.
5. **Stessa grana degli sprite** (54): la ricchezza non viene da pixel più piccoli ma dai punti 1-4.

- **Legno** (carri, ponti, casse): assi larghe 15-20 cm, cioè 5-6 px, separate da una riga scura di 1 px. Venatura con righe di 1 px ogni 2-3 px, nel verso dell'asse. Nodi di 2×2 px. Il legno dei carri è sbiadito dal sole, verso le tinte "pietra calda" e "sabbia".
- **Pietra** (muri, terrazze, rocce): blocchi di 30-60 cm, cioè 9-18 px, con fughe scure di 1 px. Tre toni per blocco più un bordo chiaro di 1 px sul lato alto. Crepe diagonali di 1 px, poche.
- **Foglie** (alberi, cespugli, felci): grumi di 3-6 px, non foglie singole. Due o tre verdi più un riflesso caldo sul lato del Giorno. La sagoma dei grumi pende verso ovest, cioè verso il Giorno.
- **Stoffa** (tende, teloni, vestiti rattoppati): toppe di 10-20 px, con cuciture tratteggiate di 1 px. Pieghe larghe 2-3 px. Il lato esposto al Giorno è più sbiadito (98, in discussione).
- **Metallo** (Generatori, Ali, Code): ferro scuro dalla rampa Ombra con ruggine dalla rampa Luce. Rivetti di 1 px ogni 4-6 px. Riflessi di 1 px solo sugli spigoli. Le Ali, rivolte al sole, sono il metallo più scuro; le Code, verso la Notte, sono coperte di brina.
- **Terreno del Crepuscolo:** zolle e ciuffi di 4-8 px su una base di due toni, sassi di 2-3 px. Si deve ripetere senza che si veda la tessera.
