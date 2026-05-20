-- Build a set from a list of record IDs (must already be lowercase).
local function idSet(ids)
    local set = {}
    for _, id in ipairs(ids) do
        set[id] = true
    end
    return set
end

-- Sixth House faction NPCs (Category:Morrowind-Factions-Sixth House).
local sixthHouseNpcIds = {
    -- Sixth House faction (Category:Morrowind-Factions-Sixth House)
    'dreamer prophet',
    'hanarai assutlanipal',
    'zula',
    -- Generic dreamer NPC record used in Sixth House areas
    'dreamer',
}

-- Mind-controlled "Sleeper" agents (UESP: Morrowind:Sleepers_Awake; 15 reputation rewards).
local sleeperNpcIds = {
    'alvura othrenim',
    'assi serimilk',
    'daynasa telandas',
    'dralas gilu',
    'drarayne girith',
    'dravasa andrethi',
    'endris dilmyn',
    'eralane hledas',
    'llandras belaal',
    'neldris llervu',
    'nelmil hler',
    'rararyn radarys',
    'relur faryon',
    'vireveri darethran',
    'vivyne andrano',
}

local sleeperQuestIds = {
    ['alvura othrenim'] = 'A1_Sleepers_Alvura',
    ['assi serimilk'] = 'A1_Sleepers_Assi',
    ['daynasa telandas'] = 'A1_Sleepers_Daynasa',
    ['dralas gilu'] = 'A1_Sleepers_Dralas',
    ['drarayne girith'] = 'A1_Sleepers_Drarayne',
    ['dravasa andrethi'] = 'A1_Sleepers_Dravasa',
    ['endris dilmyn'] = 'A1_Sleepers_Endris',
    ['eralane hledas'] = 'A1_Sleepers_Eralane',
    ['llandras belaal'] = 'A1_Sleepers_Llandras',
    ['neldris llervu'] = 'A1_Sleepers_Neldris',
    ['nelmil hler'] = 'A1_Sleepers_Nelmil',
    ['rararyn radarys'] = 'A1_Sleepers_Rararyn',
    ['relur faryon'] = 'A1_Sleepers_Relur',
    ['vireveri darethran'] = 'A1_Sleepers_Vireveri',
    ['vivyne andrano'] = 'A1_Sleepers_Vivyne',
}

local sleeperAndHouseNpcIds = {}
for _, id in ipairs(sixthHouseNpcIds) do
    sleeperAndHouseNpcIds[#sleeperAndHouseNpcIds + 1] = id
end
for _, id in ipairs(sleeperNpcIds) do
    sleeperAndHouseNpcIds[#sleeperAndHouseNpcIds + 1] = id
end

return {
    storageSection = 'corprus_plague',

    -- Registered in content_register.lua (LOAD context, OpenMW 0.51+).
    carrierSpellId = 'corprus_plague_pandemic',
    carrierSpellName = 'Pandemic',
    carrierEffectId = 'spreadable_corprus_marker',
    carrierEffectName = 'Divine Disease Carrier',
    carrierCuredEffectId = 'spreadable_corprus_marker_cured',
    carrierCuredEffectName = 'Divine Disease Carrier (Cured)',

    -- Vanilla main quest update when Dagoth Ur is defeated.
    cureQuestId = 'C3_DestroyDagoth',
    cureQuestStage = 50,
    cureMessage = "Dagoth Ur’s curse has been lifted. You are no longer his Divine Disease carrier, but at what cost to Vvardenfell?",

    sleepersAwakeQuestId = 'A1_SleepersAwake',
    sleepersAwakeQuestStartStage = 1,
    sleepersAwakeQuestEndStage = 50,
    sleeperFreedQuestStage = 1,
    sleeperAwakeDialogue = 'The vessel approaches, and we breathe deep, for he is with us even now.',
    hanaraiRecordId = 'hanarai assutlanipal',
    hanaraiDialogue = 'The House Unmourned rises. And he shall tear down this kingdom of false kings and bastards. Washed away in a cloud of perfect ash.',

    -- Show "#{sKilledEssential}" when an essential NPC morphs (same text as vanilla death).
    showProphecyOnEssentialMorph = true,
    essentialDeathGmst = 'sKilledEssential',

    settingsPageKey = 'CorprusPlague',
    settingsGroupKey = 'SettingsCorprusPlague',
    defaultIncubationDays = 7,
    minIncubationDays = 1,
    maxIncubationDays = 21,

    defaultDispositionModifier = 0.5,
    minDispositionModifier = 0,
    maxDispositionModifier = 2,
    dispositionModifierStep = 0.1,

    -- Set true for ONE load to wipe bad infection/transform records from earlier tests, then set false.
    clearPlagueDataOnLoad = false,

    -- First-rest nightmare — development only (see scripts/corprus_plague/first_rest_dream*.lua).
    debugFirstRestDream = false, -- openmw.log + optional in-game toasts; F9 forces encounter indoors
    debugIgnoreFirstRestDreamSave = false, -- allow re-trigger on the same save
    debugTriggerDreamOnLoad = false, -- fire nightmare immediately on load

    -- Carrier cure (Dagoth Ur) — development only. See DEVELOPING.md.
    debugCure = false, -- log cure flow to openmw.log ([corprus_plague] cure: …)
    debugForceCurePendingOnLoad = false, -- set curePending on every load (smoke-test load retry)
    debugSkipCureApplication = false, -- accept cure events but do not mark cured (fail-state test)

    -- How often to check active NPCs for transformation (seconds of simulation time).
    transformScanInterval = 5,

    spawnVfxMagicEffectIds = { 'corprus', 'blightdisease' },
    spawnVfxId = 'spreadable_corprus_spawn_vfx',

    transformCreatures = {
        { id = 'corprus_stalker', weight = 70 },
        { id = 'corprus_lame', weight = 30 },
    },

    -- Only the living god form, not other Vivec-related NPCs.
    immuneRecordIds = idSet({
        'vivec_god',
        'yagrum bagarn',
    }),

    -- Faction membership checked at runtime via types.NPC.getFactions.
    immuneFactions = idSet({
        'sixth house',
    }),

    -- Dreamer-class cultists and named sleepers (see list above).
    immuneClasses = idSet({
        'dreamer',
    }),

    sleeperRecordIds = idSet(sleeperNpcIds),
    sleeperQuestIds = sleeperQuestIds,
    immuneSleeperRecordIds = idSet(sleeperAndHouseNpcIds),
}
