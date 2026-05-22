# Spreadable Corprus

An OpenMW gameplay mod that curses the player as Dagoth Ur's "Divine Disease Carrier". The player spreads a unique strain of Corprus to NPCs when they speak during dialogue. Infected NPCs eventually transform into Corprus creatures (by default, Corprus Stalker or Lame Corprus).

## Description

You start the game with spreadable Corprus - which poses no risk to you and has no symptoms. Any eligible NPC you speak with during dialogue becomes infected immediately. There is no random chance and no cure for infected NPCs.

After an incubation period (defaults to 7 days but configurable in-game), the next time that NPC is active in the world they transform: their body is replaced by a Corprus creature (usually a **Corprus Stalker**, sometimes a **Lame Corprus**). This Corprus creature has the original NPCs name and is holding their equipment. Essential NPCs can still transform; you may see the same prophecy-style message vanilla uses when an essential character dies.

## Installation instructions

**Requires OpenMW 0.51 or newer.**

1. Install [OpenMW](https://openmw.org/) 0.51+ with a normal Morrowind data setup (base game; Tribunal and Bloodmoon recommended).
2. Extract this archive so you have a folder (for example `spreadable-corprus`) containing:
   - `corprus_plague.omwscripts`
   - `corprus_plague_dialogue.omwaddon`
   - `scripts/`
   - `l10n/`
3. Place that folder on your OpenMW **data path**—for example next to other mods:
   - `...\OpenMW 0.51.0\data\spreadable-corprus\`
4. Open **OpenMW Launcher** → **Data Files** and enable the folder (same as any content mod).
5. **Optional:** enable **`corprus_plague_dialogue.omwaddon`** after `Morrowind.esm` for journal text and **`strange nightmare`** topic dialogue (story mode only; see **Optional story content**).
6. Launch the game. On a new or existing save, you should receive the **Pandemic** ability shortly after loading.

OpenMW loads `corprus_plague.omwscripts` automatically from enabled data folders. The core pandemic (infection, transform, Pandemic ability) works with scripts alone.

Rebuild the plugin after editing dialogue: `node tools/build_dialogue_esp.mjs`. Published GitHub releases build and attach the addon plus a full mod zip automatically (see [DEVELOPING.md](DEVELOPING.md#releases)).

**Upgrading:** If an older build granted **Spreadable Corprus** (fixed **1 pt** in Magic), load the save once with this version—the legacy ability is removed and **Pandemic** is applied with the correct count. See [CHANGELOG.md](CHANGELOG.md) for save-format and UI details.

## Configuration

Edit [`scripts/corprus_plague/config.lua`](scripts/corprus_plague/config.lua), then **restart OpenMW** (config is read at startup).

| Setting | Purpose |
|---------|---------|
| **`enableStory`** | `true` (default): first-rest nightmare, journal entries, Dagoth Ur cure, and dialogue addon integration. `false`: core pandemic only—no nightmare, no journal writes, no cure; **`corprus_plague_dialogue.omwaddon` not required**. |
| **`transformCreatures`** | Weighted list of creature record IDs NPCs morph into after incubation. Weights are relative (e.g. `{ id = 'corprus_lame', weight = 1 }` alone = 100% Lame Corprus). IDs must match loaded content (use exact Morrowind record IDs, e.g. `atronach_flame` not `flame_atronach`).

Example — morph infected NPCs into vanilla atronachs instead of Corprus (equal weight each):

```lua
transformCreatures = {
    { id = 'atronach_flame', weight = 1 },
    { id = 'atronach_frost', weight = 1 },
    { id = 'atronach_storm', weight = 1 },
},
```

Morrowind record IDs use the form **`atronach_flame`**, not `flame_atronach`. There is no Iron Atronach in vanilla Morrowind (only Flame, Frost, and Storm).

Toggling **`enableStory` mid-save** is unsupported; a save already marked cured will stay non-infectious until a new game.

## Core pandemic

These features work with **`corprus_plague.omwscripts` only** (no dialogue addon required):

- **Divine Disease Carrier** — player ability; active effect shows **Divine Disease Carrier** with **Pandemic - N pts** for the number of unique NPCs infected in this save.
- **Airborne infection** — when an NPC speaks during dialogue with you they become infected.
- **Configurable incubation period** — **Settings → Spreadable Corprus → Pandemic → Incubation period (days)**; choose **1–21** days (default **7**). Stored in your save.
- **Transformation** — after incubation, infected NPCs become Corprus when active in the world. Target creature is chosen from **`transformCreatures`** in `config.lua` (default **70%** Stalker / **30%** Lame), with a brief spawn VFX on the new creature.
- **Disposition modifier** — As the pandemic spreads, NPCs you speak with lose base disposition toward you for each Pandemic pt (default **0.5** per pt; **0–2** in **Settings → Spreadable Corprus → Pandemic**). This can be fully disabled if it suits the player.
- **Loot and identity** — Corprus keeps the NPC’s display name where possible; inventory is moved to the creature.
- **Immunities** — Some NPCs are immune - for example Sixth House faction members, **Dreamer**-class NPCs, and named Sleepers / related cultists (see `scripts/corprus_plague/config.lua` for the full ID list).
- **Essential warning** — ["thread of prophecy"](https://en.uesp.net/wiki/Morrowind:Essential_NPCs) message is triggered when an essential NPC transforms.
- **Per-save tracking** — infection counts and transform lists are written into each save file; after reload, transformed NPCs stay disabled when their cell loads.

## Optional story content

Requires **`enableStory = true`** in `config.lua` and **`corprus_plague_dialogue.omwaddon`** enabled for journal text and topic dialogue.

- **First-rest nightmare** — the first time you **sleep** in a legal interior (bed rest or rest-until-healed with HP/fatigue recovery—not **Wait**), a strange nightmare plays, a Corprus Stalker spawns, and journal **`cp_carrier` stage 10** is written.
- **Strange nightmare dialogue** — with the addon enabled and **`cp_carrier` ≥ 10**, NPCs respond to the topic **strange nightmare**:
  - **Wise Women**: admonishing **Choice** conversation (**Sharmat?** → **What can I do?**); grateful but wary line after **`cp_carrier` ≥ 100**.
  - **Caius Cosades**, **Mehra Milo**, **Hassour Zainsubani**: worried, redirect, or dream-lore responses.
  - **Ashlanders**: direct you to a Wise Woman.
  - **Sixth House** cultists: cult line; confused response after cure.
  - **Named Sleepers Awake victims** (e.g. Rararyn Radarys): same cult/cured lines, but only after vanilla **`A1_2_AntabolisInformant` ≥ 10** (Dwemer puzzle box returned to Hasphat).
- **Carrier cure** — defeating Dagoth Ur (`C3_DestroyDagoth` stage 50) cures the curse, shows an OK message, sets **`cp_carrier` stage 100**, stops new infections, and changes the active effect to **Divine Disease Carrier (Cured)** while **Pandemic** and the final pt count stay visible.

## Main features (summary)

See **Core pandemic** and **Optional story content** above for the full list.

## For developers

Debug flags and manual cure tests: [DEVELOPING.md](DEVELOPING.md).

Dialogue plugin source: [tools/build_dialogue_esp.mjs](tools/build_dialogue_esp.mjs). Rebuild with:

```bash
node tools/build_dialogue_esp.mjs
```

## Changelog

Release notes: [CHANGELOG.md](CHANGELOG.md).

## Requirements

| Requirement | Details |
|-------------|---------|
| **OpenMW** | **0.51.0 or newer** (Lua `LOAD` scripts and `openmw.content` registration). |
| **Morrowind data** | Base **Morrowind** assets installed and configured in OpenMW. |
| **Expansions** | Not strictly required for the mod to load; a full playthrough assumes **Tribunal** / **Bloodmoon** content like vanilla. |
| **Other mods** | Compatibility with other mods is unknown—not tested. |
| **Original engine** | **Not supported** — OpenMW only. |

## Shout outs

- **[OpenMW](https://openmw.org/)** — Lua scripting, settings UI, and the engine this mod is built for.
- **[UESP](https://en.uesp.net/wiki/Morrowind:Sleepers_Awake)** — reference for Sleeper and Sixth House NPC IDs used in the immunity list.
- **Bethesda** — *The Elder Scrolls III: Morrowind* and its creatures, records, and world.

## License

This project is licensed under the [MIT License](LICENSE).
