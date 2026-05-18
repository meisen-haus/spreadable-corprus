# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- Per-save counter for **unique NPC infections** (`countedInfections` / `stats.infections` in plague save data).
- Save format **version 2**; version 1 saves rebuild the infection count from existing infection and transform records on load.
- Magic UI shows the live count on the carrier ability: active effect **Divine Disease Carrier**, source line **Pandemic - N pts** (N = unique NPCs infected this save, including those already transformed).

### Changed

- Player carrier ability renamed from **Spreadable Corprus** to **Pandemic** (`corprus_plague_pandemic`); active effect label is **Divine Disease Carrier** (`spreadable_corprus_marker` record id unchanged).
- Infection count is driven by count-specific dynamically registered Pandemic spell records so OpenMW’s Magic UI magnitude matches N (replacing a fixed 1 pt display).

### Removed

- Legacy carrier spells **corprus immunity** and **spreadable corprus** are stripped on load when present.

## [0.1.0] - 2026-05-16

### Added

- OpenMW 0.51+ Lua mod: spread Corprus to eligible NPCs through dialogue (greetings, topics, persuasion, voice, journal).
- Configurable incubation period (**Settings → Spreadable Corprus → Plague**, 1–21 days, default 7), stored per save.
- NPC transformation after incubation (70% Corprus Stalker / 30% Corprus Lame) with loot and display name preserved where possible.
- Per-save infection and transform tracking; transformed NPCs stay disabled after reload when their cell loads.
- Immunities for Sixth House faction, Dreamer class, named Sleepers, and configured record IDs (see `config.lua`).
- Prophecy-style message when an essential NPC transforms (optional, configurable).
