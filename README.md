# Spreadable Corprus

An OpenMW gameplay mod that lets the player spread a unique strain of Corprus to NPCs when they greet you. Infected NPCs eventually transform into Corprus creatures.

## Description

You start the game with incurable, spreadable Corprus. Any eligible NPC that greets you becomes infected immediately. There is no random chance and no cure—for you or for them.

After an incubation period (defaults to 7 days but configurable in-game), the next time that NPC is active in the world they transform: their body is replaced by a Corprus creature (usually a **Corprus Stalker**, sometimes a **Corprus Lame**). A one-shot Corprus-style visual effect plays on the new creature when it appears. This Corprus creature has their name and is holding their equipment, and the original NPC is removed. Essential NPCs can still transform; you may see the same prophecy-style message vanilla uses when an essential character dies.

## Installation instructions

**Requires OpenMW 0.51 or newer.** This mod does not work on original Morrowind (Morrowind.exe).

1. Install [OpenMW](https://openmw.org/) 0.51+ with a normal Morrowind data setup (base game; Tribunal and Bloodmoon recommended).
2. Extract this archive so you have a folder (for example `spreadable-corprus`) containing:
   - `corprus_plague.omwscripts`
   - `scripts/`
   - `l10n/`
3. Place that folder on your OpenMW **data path**—for example next to other mods:
   - `...\OpenMW 0.51.0\data\spreadable-corprus\`
4. Open **OpenMW Launcher** → **Data Files** and enable the folder (same as any content mod).
5. Launch the game. On a new or existing save, you should receive the **Pandemic** ability shortly after loading.

No ESP or plugin is required. OpenMW loads `corprus_plague.omwscripts` automatically from enabled data folders.

**Upgrading:** If an older build granted **Spreadable Corprus** (fixed **1 pt** in Magic), load the save once with this version—the legacy ability is removed and **Pandemic** is applied with the correct count. See [CHANGELOG.md](CHANGELOG.md) for save-format and UI details.

## Main features

- **Pandemic** — permanent player ability; active effect shows **Divine Disease Carrier** with **Pandemic - N pts** for the number of unique NPCs infected in this save.
- **Dialogue infection** — speaking with an NPC (topics, greetings, persuasion, voice, journal) infects them if they are eligible.
- **Configurable incubation period** — **Settings → Spreadable Corprus → Pandemic → Incubation period (days)**; choose **1–21** days (default **7**). Stored in your save.
- **Transformation** — after incubation, infected NPCs become Corprus when active in the world; **70%** Stalker / **30%** Lame, with a brief spawn VFX on the new creature.
- **Disposition modifier** — NPCs you speak with lose base disposition toward you for each Pandemic pt (default **0.5** per pt; **0–2** in **Settings → Spreadable Corprus → Pandemic**).
- **Loot and identity** — Corprus keeps the NPC’s display name where possible; inventory is moved to the creature.
- **Immunities** — Sixth House faction members, **Dreamer**-class NPCs, and named Sleepers / related cultists (see `scripts/corprus_plague/config.lua` for the full ID list).
- **Essential warning** — prophecy message when an essential NPC transforms.
- **Per-save tracking** — infection and transform lists are written into each save file; after reload, transformed NPCs stay disabled when their cell loads.
- **Infection statistic** — each save tracks the total number of unique NPCs infected (by stable actor identity, not display name), even after they transform; the count appears in **Magic → Active Effects** as **Pandemic - N pts**.

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
