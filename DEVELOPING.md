# Developer notes

Edit `scripts/corprus_plague/config.lua`, then **restart OpenMW** (config is read at startup).

## Logs

Log file (Windows): `Documents\My Games\OpenMW\openmw.log`

| Flag | Grep pattern |
|------|----------------|
| `debugCure` | `[corprus_plague] cure:` |
| `debugFirstRestDream` | `[corprus_plague] dream:` |

With `debugFirstRestDream = true`, restart OpenMW, reproduce the issue, then search the log for `dream:`. Useful lines:

- `getStage: global "cp_firstrest_dream" not in mwscript table` — dialogue plugin/global not loaded; enable `corprus_plague_dialogue.omwaddon`.
- `setStage: N -> M (read back M)` — console `set` or Lua stage change.
- `UiModeChanged: … -> Dialogue` — topic sync should follow; if mode name differs, sync never runs.
- `addDreamTopics: stage=1 added {strange nightmare, …}` — `AddTopic` succeeded.
- `addDreamTopics: self.type.addTopic missing` — OpenMW too old for `types.Player.addTopic` (needs 0.51+ with issue #8334).
- `record is not a topic` — rebuild `corprus_plague_dialogue.omwaddon` (`node tools/build_dialogue_esp.mjs`); old builds used 4-byte DIAL DATA instead of 1-byte topic type.
- `content topic[…] "strange nightmare": MISSING` — dialogue `.omwaddon` not enabled or not on data path.
- `DialogueResponse topic recordId=strange nightmare` — mod line fired when you pick the topic.

## Debug flags (`config.lua`)

| Flag | Purpose |
|------|---------|
| `debugCure` | Log cure requests, retries, and success. |
| `debugSkipCureApplication` | Full cure pipeline but never set `cured`; leaves `curePending` for retry tests. |
| `debugForceCurePendingOnLoad` | Set `curePending` on every load (smoke-test load retry). Disable after use. |
| `clearPlagueDataOnLoad` | One load: wipe mod plague data only (vanilla quest unchanged). |
| `debugFirstRestDream` | Log to `openmw.log` (`[corprus_plague] dream:`); in-game toasts; F9 forces encounter indoors. **On in `config.lua` for topic debugging.** |

## Console

First-rest Wise Woman topics:

1. Enable **`corprus_plague_dialogue.omwaddon`** in OpenMW Launcher (after `Morrowind.esm`), same data folder as the Lua mod.
2. Restart OpenMW, then in console:

```
set cp_firstrest_dream to 1
```

3. **Close any open dialogue**, then talk to a **Wise Woman** (e.g. Nibani Maesa in `Wise Woman's Yurt`). Pick **strange nightmare** once. Linear chain in one window: opening line → **Sharmat?** only → devil-of-Red-Mountain line → **What can I do?** → final line → **Goodbye**. Use the red **Choice** text in the dialogue history, not the topic list on the left.

If a choice repeats the opening line, click the same **Choice** again or click **strange nightmare** once more in the topic list (Lua bumps the global so the next line can load). Rebuild the plugin after edits: `node tools/build_dialogue_esp.mjs`.

`AddTopic` alone is not enough: OpenMW only lists a topic if the NPC has a matching **INFO** line (class + global). With `debugFirstRestDream`, grep the log for `visibility:` — you want several INFO rows and `classOk=true`. If `infos=0`, rebuild the plugin and check `openmw.log` for `info record without dialog` or `invalid SCVR`.

If topics are still missing after `set`, rebuild (`node tools/build_dialogue_esp.mjs`) and confirm `corprus_plague_dialogue.omwaddon` is enabled. Quest Wise Women (e.g. Nibani) use class **`wise woman service`**, not `wise woman` — the plugin includes INFO for both. Topics added while dialogue is already open may not appear until you **exit and talk again**.

The full chain runs in one conversation via **Choice** BNAM on the plugin INFO records; global stages 2–3 are set by those scripts (Lua `DialogueResponse` mirrors the same INFO ids).

**F10** (with `debugFirstRestDream`): force topic sync without opening dialogue. **F9**: force first-rest dream test.

After `set cp_firstrest_dream to 1`, press **F10** or open dialogue with a Wise Woman — you should see `syncPlayerTopics` and `applyTopicsOnPlayer` in the log.

**First-rest nightmare:** `stage=0` until the dream runs or you `set cp_firstrest_dream to 1`. Complete a real rest (wait for time to pass in the rest menu, then confirm). Log should show `rest complete in …` not `rest ended early (0.0s)`. **F9** forces the dream indoors without resting.

Rebuild dialogue plugin: `node tools/build_dialogue_esp.mjs`

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
