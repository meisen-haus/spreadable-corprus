# Spreadable Corprus

An OpenMW gameplay mod that curses the player as Dagoth Ur's "Divine Disease Carrier". The player spreads a unique strain of Corprus to NPCs when they greet them. Infected NPCs eventually transform into Corprus creatures (Corprus Stalker or Lame Corprus).

## Description

You start the game with spreadable Corprus - which poses no risk to you and has no symptoms. Any eligible NPC that greets you becomes infected immediately. There is no random chance and no cure for infected NPCs.

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
4. Open **OpenMW Launcher** → **Data Files** and enable the folder (same as any content mod), and enable **`corprus_plague_dialogue.omwaddon`** after `Morrowind.esm`.
5. Launch the game. On a new or existing save, you should receive the **Pandemic** ability shortly after loading.

OpenMW loads `corprus_plague.omwscripts` automatically from enabled data folders. The companion plugin adds a journal entry and **Wise Woman** topic dialogue after the first-rest nightmare.

**Upgrading:** If an older build granted **Spreadable Corprus** (fixed **1 pt** in Magic), load the save once with this version—the legacy ability is removed and **Pandemic** is applied with the correct count. See [CHANGELOG.md](CHANGELOG.md) for save-format and UI details.

## Main features

- **Divine Disease Carrier** — player ability; active effect shows **Divine Disease Carrier** with **Pandemic - N pts** for the number of unique NPCs infected in this save. Defeating Dagoth Ur cures the carrier curse, stops new infections, and changes the active effect to **Divine Disease Carrier (Cured)** while **Pandemic** and the final pt count stay visible.
- **First-rest nightmare** — the first interior rest triggers a strange nightmare and a journal entry; **Wise Woman** NPCs can then discuss it via topic dialogue (requires `corprus_plague_dialogue.omwaddon`).
- **Airborne infection** — when an NPC greets the player they become infected.
- **Configurable incubation period** — **Settings → Spreadable Corprus → Pandemic → Incubation period (days)**; choose **1–21** days (default **7**). Stored in your save.
- **Transformation** — after incubation, infected NPCs become Corprus when active in the world; **70%** Stalker / **30%** Lame, with a brief spawn VFX on the new creature.
- **Disposition modifier** — As the pandemmic spreads, NPCs you speak with lose base disposition toward you for each Pandemic pt (default **0.5** per pt; **0–2** in **Settings → Spreadable Corprus → Pandemic**). This can be fully disabled if it suits the player.
- **Loot and identity** — Corprus keeps the NPC’s display name where possible; inventory is moved to the creature.
- **Immunities** — Some NPCs are immune - for example Sixth House faction members, **Dreamer**-class NPCs, and named Sleepers / related cultists (see `scripts/corprus_plague/config.lua` for the full ID list).
- **Essential warning** — ["thread of prophecy"](https://en.uesp.net/wiki/Morrowind:Essential_NPCs) message is triggered when an essential NPC transforms.
- **Per-save tracking** — infection counts and transform lists are written into each save file; after reload, transformed NPCs stay disabled when their cell loads.

## For developers

Debug flags and manual cure tests: [DEVELOPING.md](DEVELOPING.md).

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
