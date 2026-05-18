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

    -- Registered in content_register.lua (LOAD context, OpenMW 0.51+).
    carrierSpellId = 'spreadable corprus',
    carrierSpellName = 'Divine Disease Carrier',
    carrierEffectId = 'spreadable_corprus_marker',
    carrierEffectName = 'Infections -',

    -- Show "#{sKilledEssential}" when an essential NPC morphs (same text as vanilla death).
    showProphecyOnEssentialMorph = true,
    essentialDeathGmst = 'sKilledEssential',

    settingsPageKey = 'CorprusPlague',
    settingsGroupKey = 'SettingsCorprusPlague',
    defaultIncubationDays = 7,
    minIncubationDays = 1,
    maxIncubationDays = 21,

    -- Set true for ONE load to wipe bad infection/transform records from earlier tests, then set false.
    clearPlagueDataOnLoad = false,

    -- How often to check active NPCs for transformation (seconds of simulation time).
    transformScanInterval = 5,

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
