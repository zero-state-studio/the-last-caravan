# Fase 4a: piano e costi stimati

*Prompt: `docs/prompts/PROMPT-04.md`. Livello: `docs/livelli/prologo.md` (106). Fermate dopo i passi 1, 3 e 5, e alla fine.*

## Budget della fase e saldi al 2026-09-28

| Servizio | Tetto della fase | Saldo all'inizio |
|---|---|---|
| PixelLab | 300 generazioni | 4.924 generazioni del mese (rinnovo 2026-10-26): il piano basta |
| Scenario | 1.000 CU | 1.122 CU usate negli ultimi 31 giorni (il saldo residuo non è leggibile dallo strumento) |
| Meshy | 400 crediti | 5.263 crediti |
| ElevenLabs | 15.000 crediti | non leggibile: la chiave non ha il permesso di lettura dell'account |

## Stima per passo

| Passo | Cosa | PixelLab | Scenario | Meshy | ElevenLabs |
|---|---|---|---|---|---|
| 1 | tre mezzi di prova (122-124); 12 personaggi in vista sud (117-121, Anselmo, Arold, Enea) | 12-36 | 0-30 | 45-90 | 0 |
| 2 | Ottavia: 7 animazioni in 8 direzioni, 2 in una o due direzioni | 90-130 | 0 | 0 | 0 |
| 3-5 | spazi 1-5: texture, oggetti (tende, brande, arbusti e croste che si rompono, Code, terrazze), animazioni delle comparse | 50-80 | 300-500 | 100-150 | 0 |
| 6 | musica (126), effetti (127), voci di prova | 0 | 0-50 | 0 | 5.000-10.000 |
| **Totale** | | **150-250** | **300-580** | **145-240** | **5.000-10.000** |

Metodi, come nelle fasi 1-3:
- personaggi con `create_character_pro_flash` (1 generazione per 8 rotazioni) e animazioni con `animate_character` (1-2 generazioni per direzione);
- mezzi con Meshy meshy-5 (anteprima 5, rifinitura con texture 10), poi semplificati e riportati a 30 px/m con `tools/mesh_simplify.py` e `tools/meshy_pixelize.py`;
- texture con Scenario e il modello personalizzato.

Prima di ogni gruppo il costo esatto va nel resoconto; oltre le soglie di `CLAUDE.md` si chiede prima.

## Note

- Lo «scatto» del prologo è la corsa tenuta della fase 3 (Shift, L3). I suggerimenti usano le parole del livello («Tieni premuto per scattare»).
- L'arrampicata non ha ancora un comando nella bibbia (33, 67): domanda aperta al passo 1, prima delle animazioni del passo 2.
- Anche le interazioni (aprire la porta, svegliare Ruggero, legare Mirco, porgere la mano ad Anselmo) non hanno un comando: domanda aperta al passo 1.
