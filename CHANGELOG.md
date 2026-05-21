# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- **Wise Woman topic dialogue** — `corprus_plague_dialogue.omwaddon` adds journal `cp_carrier` (stage 10 = nightmare) and a single topic **strange nightmare** with vanilla **Choice** branches (**Sharmat?**, **What can I do?**) for **Wise Woman** / **Wise Woman Service** NPCs, gated by the journal entry. Rebuild with `node tools/build_dialogue_esp.mjs`.
- Defeating Dagoth Ur (`C3_DestroyDagoth` stage 50) now cures the player carrier curse, stops new infections, shows a cure message, and changes the active effect to **Divine Disease Carrier (Cured)** while **Pandemic** and its pt count stay unchanged.
- Save format **version 4** — adds per-save `cured` and `curePending` (pending retries on load and every 5s until cured).
- Cure debug flags in `config.lua` (`debugCure`, `debugForceCurePendingOnLoad`, `debugSkipCureApplication`); see [DEVELOPING.md](DEVELOPING.md).
- Cure and first-rest messages use a deferred OK box so opening them while the developer console is open does not crash the game (shows after closing the console, not on reopen).

## [0.2.0] - 2026-05-18

### Added

- **First-rest nightmare** — the first time you complete a legal interior rest, a dream message plays and a Corprus Stalker spawns behind you (tracked per save).
- Per-save counter for **unique NPC infections** (`countedInfections` / `stats.infections` in Pandemic save data).
- Save format **version 2**; version 1 saves rebuild the infection count from existing infection and transform records on load.
- Magic UI shows the live count on the carrier ability: active effect **Divine Disease Carrier**, source line **Pandemic - N pts** (N = unique NPCs infected this save, including those already transformed).
- **Disposition penalty on dialogue** — when an NPC speaks during dialogue, their **base disposition** toward you is reduced by `N × modifier`, where **N** is your current Pandemic pt total (unique infections this save) and **modifier** is the per-pt rate below. Penalties apply only to NPCs you have spoken with; other NPCs are unaffected until you dialogue with them.
- **Per-NPC penalty tracking** — each NPC stores how much disposition penalty has already been applied. On later conversations, only the **delta** since the last talk is applied, so repeat dialogue does not stack the same penalty twice. Raising or lowering the modifier in settings adjusts the target on the next talk with that NPC.
- **Disposition modifier** setting — **Settings → Spreadable Corprus → Pandemic → Disposition modifier**: “For each pt of Pandemic, modify base disposition by:” Choose **0–2** in **0.1** steps (default **0.5**). Stored per save. **Off** is **0** (no penalty).
- Save format **version 3** — adds per-NPC `dispositionPenalties` to the save payload (version 2 saves load without prior penalty records).
- **Corprus spawn VFX** — a one-shot visual effect on the new creature when an NPC transforms (Corprus / blight disease magic effect visuals).

### Changed

- Settings group label **Plague** renamed to **Pandemic** (**Settings → Spreadable Corprus → Pandemic**).
- Player carrier ability renamed from **Spreadable Corprus** to **Pandemic** (`corprus_plague_pandemic`); active effect label is **Divine Disease Carrier** (`spreadable_corprus_marker` record id unchanged).
- Infection count is driven by count-specific dynamically registered Pandemic spell records so OpenMW’s Magic UI magnitude matches N (replacing a fixed 1 pt display).
- Dialogue infection events now pass the talking player from the player script so disposition changes target the correct character.

### Fixed

- **Essential NPC prophecy** — when an essential NPC transforms, the vanilla `sKilledEssential` message is shown again via OpenMW’s built-in `ShowMessage` event (the previous handler called `I.UI.showMessage`, which does not exist on the UI interface).
- **`findActor` for content-file NPCs** — plague keys prefixed with `f:` no longer stop after a failed `getObjectByFormId` lookup. The handler falls back to scanning active actors, so dialogue infection, carrier sync, and disposition penalties run for the NPC you are actually speaking with (previously Pandemic pts could rise while disposition stayed unchanged).
- **Disposition penalty at Off** — modifier **0** applies no penalty; penalties no longer clamp incorrectly when base disposition is low.

### Removed

- Legacy carrier spells **corprus immunity** and **spreadable corprus** are stripped on load when present.

## [0.1.0] - 2026-05-16

### Added

- OpenMW 0.51+ Lua mod: spread Corprus to eligible NPCs through dialogue (greetings, topics, persuasion, voice, journal).
- Configurable incubation period (**Settings → Spreadable Corprus → Pandemic**, 1–21 days, default 7), stored per save.
- NPC transformation after incubation (70% Corprus Stalker / 30% Corprus Lame) with loot and display name preserved where possible.
- Per-save infection and transform tracking; transformed NPCs stay disabled after reload when their cell loads.
- Immunities for Sixth House faction, Dreamer class, named Sleepers, and configured record IDs (see `config.lua`).
- Prophecy-style message when an essential NPC transforms (optional, configurable).
