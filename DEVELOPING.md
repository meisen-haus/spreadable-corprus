# Developer notes

Edit `scripts/corprus_plague/config.lua`, then **restart OpenMW** (config is read at startup).

## Logs

`debugCure = true` → `openmw.log`, search `[corprus_plague] cure:` (Windows: `Documents\My Games\OpenMW\openmw.log`).

## Debug flags (`config.lua`)

| Flag | Purpose |
|------|---------|
| `debugCure` | Log cure requests, retries, and success. |
| `debugSkipCureApplication` | Full cure pipeline but never set `cured`; leaves `curePending` for retry tests. |
| `debugForceCurePendingOnLoad` | Set `curePending` on every load (smoke-test load retry). Disable after use. |
| `clearPlagueDataOnLoad` | One load: wipe mod plague data only (vanilla quest unchanged). |
| `debugFirstRestDream` | Log/toast first-rest dream (`[corprus_plague] dream:`); F9 forces encounter indoors. |

## Console

First-rest nightmare journal: `journal cp_carrier 10` (sets the journal entry and enables Wise Woman topic dialogue).

Main-quest cure trigger: `journal C3_DestroyDagoth, 50`

Close the developer console (`` ` ``) before the cure OK box — `showInteractiveMessage` with the console open can crash OpenMW.

## Cure tests

Use `debugCure = true` to verify logs.

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
