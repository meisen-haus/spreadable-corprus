-- Build a set from a list of record IDs (must already be lowercase).
local function idSet(ids)
    local set = {}
    for _, id in ipairs(ids) do
        set[id] = true
    end
    return set
end

-- Sleepers Awake victims (UESP: Morrowind:Sleepers_Awake) plus Sixth House faction NPCs.
local sleeperAndHouseNpcIds = {
    -- Sixth House faction (Category:Morrowind-Factions-Sixth House)
    'dreamer prophet',
    'hanarai assutlanipal',
    'zula',
    -- Generic dreamer NPC record used in Sixth House areas
    'dreamer',
    -- Mind-controlled "Sleeper" agents (15 reputation rewards)
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

return {
    storageSection = 'corprus_plague',

    -- Short global in corprus_plague_dialogue.omwaddon (console: set cp_firstrest_dream to N).
    firstRestDreamGlobalId = 'cp_firstrest_dream',
    wiseWomanClassIds = idSet({
        'wise woman',
        'wise woman service',
    }),
    firstRestDreamTopicIds = {
        nightmare = 'strange nightmare',
    },
    firstRestDreamInfoIds = {
        root = 'cp_sn_root',
        rootService = 'cp_sn_roots',
        sharmatChoice = 'cp_sn_ch1',
        sharmatChoiceService = 'cp_sn_ch1s',
        sharmatGlobal = 'cp_sn_g2',
        sharmatGlobalService = 'cp_sn_g2s',
        whatCanIDoChoice = 'cp_sn_ch2',
        whatCanIDoChoiceService = 'cp_sn_ch2s',
        whatCanIDoGlobal = 'cp_sn_g3',
        whatCanIDoGlobalService = 'cp_sn_g3s',
    },

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
    debugFirstRestDream = true, -- openmw.log + optional in-game toasts; F9 forces encounter indoors
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

    immuneSleeperRecordIds = idSet(sleeperAndHouseNpcIds),
}
