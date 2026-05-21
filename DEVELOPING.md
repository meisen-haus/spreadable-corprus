# Developer notes

Edit `scripts/corprus_plague/config.lua`, then **restart OpenMW** (config is read at startup).

## Core tuning (`config.lua`)

| Setting | Purpose |
|---------|---------|
| `enableStory` | `true` (default): nightmare, journal, cure, dialogue integration. `false`: pandemic mechanics only. |
| `transformCreatures` | `{ id, weight }` list for NPC morph targets. Weights are relative; IDs lowercased at load. Empty or invalid lists error at startup. Use exact Morrowind record IDs (e.g. `atronach_flame`). |
| `immuneRecordIds` | Named NPC record IDs that cannot be infected. |
| `immuneFactions` | Faction IDs (e.g. `sixth house`). |
| `immuneClasses` | Class IDs (e.g. `dreamer`). |
| `immuneSleeperRecordIds` | Sleeper / Sixth House NPC IDs (also mirrored in `tools/build_dialogue_esp.mjs` for story dialogue). |
| `transformScanInterval` | Seconds between active-NPC transform scans (default 5). |
| `showProphecyOnEssentialMorph` | Show vanilla essential-death message when an essential NPC transforms. |

Incubation and disposition defaults are in-game (**Settings → Spreadable Corprus → Pandemic**); bounds are in `config.lua`.

## Logs

`debugCure = true` → `openmw.log`, search `[corprus_plague] cure:` (Windows: `Documents\My Games\OpenMW\openmw.log`).

## Debug flags (`config.lua`)

Story mode only unless noted:

| Flag | Purpose |
|------|---------|
| `debugCure` | Log cure requests, retries, and success. |
| `debugSkipCureApplication` | Full cure pipeline but never set `cured`; leaves `curePending` for retry tests. |
| `debugForceCurePendingOnLoad` | Set `curePending` on every load (smoke-test load retry). Disable after use. |
| `clearPlagueDataOnLoad` | One load: wipe mod plague data only (vanilla quest unchanged). |
| `debugFirstRestDream` | Log/toast first-rest dream (`[corprus_plague] dream:`); F9 forces encounter indoors. |

First-rest nightmare triggers on **sleep** (bed or rest-until-healed with stat recovery), not on **Wait**. OpenMW uses the same Rest UI mode for both; the mod checks bed use or HP/fatigue gain to tell them apart.

## Story QA (console)

Requires `enableStory = true` and usually `corprus_plague_dialogue.omwaddon` for journal text.

First-rest nightmare journal: `journal cp_carrier 10` (sets the journal entry and enables Wise Woman topic dialogue).

Main-quest cure trigger: `journal C3_DestroyDagoth, 50`

Close the developer console (`` ` ``) before the cure OK box — `showInteractiveMessage` with the console open can crash OpenMW.

## Cure tests

Requires `enableStory = true`. Use `debugCure = true` to verify logs.

**1 — Failed apply + load retry**

- `debugSkipCureApplication = true` → restart → uncured save → `journal C3_DestroyDagoth, 50`
- Expect: still uncured; log `cure requested; curePending set`, `not marking cured`
- Save → `debugSkipCureApplication = false` → restart → load
- Expect: cured; log `retry pending cure (load)`, `carrier cured`

**2 — Forced pending on load**

- `debugForceCurePendingOnLoad = true` → restart → load
- Expect: log `debugForceCurePendingOnLoad: curePending set`, `retry pending cure (load)`, `carrier cured`
- Set flag back to `false`

**3 — Quest backfill**

- All cure debug flags `false` → uncured save → `journal C3_DestroyDagoth, 50` if needed
- Expect: log `cure requested; curePending set`, `carrier cured` (not load retry first)

Optional: save at index 50 uncured, reload — first-frame quest poll should cure without `journal`.

Reset all debug flags to `false` when done.
