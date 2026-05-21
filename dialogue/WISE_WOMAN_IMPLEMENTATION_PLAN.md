# Wise Woman topic dialogue — `corprus_plague_dialogue.omwaddon`

Plugin that adds one **topic** with **vanilla Choice** branches for NPCs of class **Wise Woman** / **Wise Woman Service**, gated by global short **`cp_firstrest_dream`**.

The plugin does **not** contain the first-rest nightmare OK box. It only supplies `GLOB` / `DIAL` / `INFO` records for the conversation window.

DO NOT REFERENCE OTHER UNMERGED BRANCHES FOR THIS CHANGE

---

## Requirements

- Morrowind + OpenMW **0.51+**
- Master: **`Morrowind.esm` only**
- Global **`cp_firstrest_dream`** is a **`GLOB`** short in this plugin (see `content_register.lua` — Lua does not register a duplicate).

---

## Global stages

| Value | Effect |
|-------|--------|
| `0` | No mod topics |
| `1` | **strange nightmare** in topic list; root INFO + Choice buttons |
| `2` | Mid-chain (BNAM on root already ran); Choice follow-ups use `Choice ==` filters |
| `3` | After **Sharmat?** branch; second Choice on that INFO |
| `4` | Chain complete; topic hidden (`stage < 4` for `AddTopic`) |

Test: `set cp_firstrest_dream to 1`, talk to a Wise Woman (e.g. Nibani Maesa, class `wise woman service`).

---

## Records

| Records | Count |
|---------|-------|
| `GLOB` `cp_firstrest_dream` | 1 |
| `DIAL` `strange nightmare` | 1 |
| `INFO` (3 lines × 2 classes) | 6 |

**One topic** — **Sharmat?** and **What can I do?** are **not** separate `DIAL` entries. They are **Choice** buttons on the root (and nested Choice on the Sharmat response).

| INFO id | SCVR | Player sees |
|---------|------|-------------|
| `CP_SN_ROOT` (+ `S` service) | `GlobalShort == 1` | Opening line; BNAM `Choice "Sharmat?" 1 "What can I do?" 2` only |
| `CP_SN_CH1` (+ `S`) | `Choice == 1` | Sharmat reply; BNAM `Choice "What can I do?" 2` only |
| `CP_SN_CH2` (+ `S`) | `Choice == 2` | Final line; BNAM `set cp_firstrest_dream to 4` |

INFO **PNAM/NNAM** chain per class: `CP_SN_CH2` → `CP_SN_CH1` → `CP_SN_ROOT` (OpenMW iterates in this order; empty links previously put **ROOT first**, so clicking a choice re-matched ROOT and broke the conversation).

Global stays **1** until the final line; only the last INFO BNAM runs `set cp_firstrest_dream to 4`.

**Every INFO:**

- **Speaker:** `CNAM` = `wise woman` or `wise woman service` (CLAS id, not display name)
- **BNAM:** only the final INFO sets global `4`; Lua mirrors stages on `DialogueResponse` for the Sharmat / What can I do lines

---

## SCVR / INTV

### Global short (root INFO only)

```text
02sX{operator}{globalName}
```

| Operator | Meaning |
|----------|---------|
| `0` | `==` |

Example: stage 1 → `SCVR` = `02sX0cp_firstrest_dream`, `INTV` = `1` (uint32 LE).

The literal **`X`** between `s` and the operator is required.

### Choice (branch INFO)

OpenMW function index **49** = `Choice` (SCVR bytes `01490` = index 0, type 1, function 49, comparison 0).

`INTV` = choice index (`1` = Sharmat?, `2` = What can I do?).

Do **not** use UESP’s `'50'` digit — that maps to the wrong function in OpenMW.

### BNAM Choice script

```text
Choice "Sharmat?" 1 "What can I do?" 2
set cp_firstrest_dream to 2
```

Nested on Sharmat INFO:

```text
Choice "What can I do?" 2
set cp_firstrest_dream to 3
```

---

## Build

```bash
node tools/build_dialogue_esp.mjs
```

Writes **`corprus_plague_dialogue.omwaddon`** (8 content records: 1× `GLOB` + 1× `DIAL` + 6× `INFO`).

Validate: binary contains `02sX0cp_firstrest_dream`, `01490`, and `Choice "Sharmat?"`.

---

## Install

OpenMW Launcher → **Data Files** → enable **`corprus_plague_dialogue.omwaddon`** after `Morrowind.esm`.

---

## Verify

1. `set cp_firstrest_dream to 1`
2. Talk to Nibani (or any Wise Woman) → pick **strange nightmare**
3. After her line, the dialogue UI should show **Choice** buttons **Sharmat?** and **What can I do?** (not sidebar topics, not blue hyperlink topic ids)
4. Pick **Sharmat?** → her reply → **What can I do?** button → final line → global `4`

With `debugFirstRestDream`, log should show `visibility: infos=6` (or 3 per loaded topic view) and `classOk=true` for `wise woman service`.

Stage progression in normal play: Lua sets global when the nightmare fires; BNAM + `DialogueResponse` advance during the conversation.
