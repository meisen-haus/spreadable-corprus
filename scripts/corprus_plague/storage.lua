local storage = require('openmw.storage')
local config = require('scripts.corprus_plague.config')

local SAVE_VERSION = 3

-- Per-save state (round-tripped via global.lua onSave/onLoad). Not in Persistent storage.
local state = {
    infections = {},
    transformed = {},
    pendingTransforms = {},
    firstRestDreamTriggered = false,
    countedInfections = {},
    dispositionPenalties = {},
    stats = {
        infections = 0,
    },
}

local legacySection = storage.globalSection(config.storageSection)

local M = {}

local function copyTable(t)
    if type(t) ~= 'table' then
        return t
    end
    local copy = {}
    for k, v in pairs(t) do
        copy[k] = copyTable(v)
    end
    return copy
end

local function countTable(t)
    local count = 0
    for _ in pairs(t) do
        count = count + 1
    end
    return count
end

local function resetInfectionStats()
    state.countedInfections = {}
    state.stats = {
        infections = 0,
    }
end

local function trackUniqueInfection(plagueKey)
    if not plagueKey or state.countedInfections[plagueKey] then
        return false
    end

    state.countedInfections[plagueKey] = true
    state.stats.infections = state.stats.infections + 1
    return true
end

local function rebuildInfectionStats()
    resetInfectionStats()
    for plagueKey in pairs(state.transformed) do
        trackUniqueInfection(plagueKey)
    end
    for plagueKey in pairs(state.infections) do
        trackUniqueInfection(plagueKey)
    end
end

function M.isInfected(plagueKey)
    return plagueKey ~= nil and state.infections[plagueKey] ~= nil
end

function M.isTransformed(plagueKey)
    return M.getTransformEntry(plagueKey) ~= nil
end

function M.getTransformEntry(plagueKey)
    if not plagueKey then
        return nil
    end
    return state.transformed[plagueKey]
end

function M.isTransformPending(plagueKey)
    return plagueKey ~= nil and state.pendingTransforms[plagueKey] ~= nil
end

function M.getInfection(plagueKey)
    if not plagueKey then
        return nil
    end
    return state.infections[plagueKey]
end

function M.markInfected(plagueKey, gameTime)
    if not plagueKey then
        return false
    end
    local wasNew = trackUniqueInfection(plagueKey)
    state.infections[plagueKey] = { infectedAt = gameTime }
    return wasNew
end

function M.clearInfection(plagueKey)
    if not plagueKey then
        return
    end
    state.infections[plagueKey] = nil
end

function M.claimTransform(plagueKey)
    if not plagueKey or M.isTransformed(plagueKey) or M.isTransformPending(plagueKey) then
        return false
    end
    state.pendingTransforms[plagueKey] = true
    return true
end

function M.releaseTransform(plagueKey)
    if not plagueKey then
        return
    end
    state.pendingTransforms[plagueKey] = nil
end

function M.markTransformed(plagueKey, entry)
    if not plagueKey then
        return false
    end
    local wasNew = trackUniqueInfection(plagueKey)
    M.clearInfection(plagueKey)
    M.releaseTransform(plagueKey)
    state.transformed[plagueKey] = entry or {}
    return wasNew
end

function M.getInfectionCount()
    return state.stats.infections
end

function M.getDispositionPenalty(plagueKey)
    if not plagueKey then
        return 0
    end
    local penalty = state.dispositionPenalties[plagueKey]
    if type(penalty) ~= 'number' then
        return 0
    end
    return penalty
end

function M.setDispositionPenalty(plagueKey, penalty)
    if not plagueKey then
        return
    end
    if type(penalty) ~= 'number' or penalty <= 0 then
        state.dispositionPenalties[plagueKey] = nil
        return
    end
    state.dispositionPenalties[plagueKey] = penalty
end

function M.getStats()
    return copyTable(state.stats)
end

function M.clearAllPendingTransforms()
    state.pendingTransforms = {}
end

function M.hasFirstRestDreamTriggered()
    return state.firstRestDreamTriggered == true
end

function M.markFirstRestDreamTriggered()
    state.firstRestDreamTriggered = true
end

function M.clearAll()
    state.infections = {}
    state.transformed = {}
    state.pendingTransforms = {}
    state.firstRestDreamTriggered = false
    state.dispositionPenalties = {}
    resetInfectionStats()
end

function M.exportForSave()
    return {
        version = SAVE_VERSION,
        infections = copyTable(state.infections),
        transformed = copyTable(state.transformed),
        firstRestDreamTriggered = state.firstRestDreamTriggered,
        countedInfections = copyTable(state.countedInfections),
        dispositionPenalties = copyTable(state.dispositionPenalties),
        stats = copyTable(state.stats),
    }
end

-- Wipe obsolete Persistent bucket (Pandemic data is per-save via global.lua onSave/onLoad).
function M.purgeLegacyPersistent()
    legacySection:reset({})
end

function M.importFromSave(savedData)
    M.clearAll()
    M.purgeLegacyPersistent()

    if config.clearPlagueDataOnLoad then
        return
    end

    if savedData and (savedData.version == SAVE_VERSION or savedData.version == 2 or savedData.version == 1) then
        if type(savedData.infections) == 'table' then
            state.infections = copyTable(savedData.infections)
        end
        if type(savedData.transformed) == 'table' then
            state.transformed = copyTable(savedData.transformed)
        end
        if savedData.version == SAVE_VERSION and type(savedData.dispositionPenalties) == 'table' then
            state.dispositionPenalties = copyTable(savedData.dispositionPenalties)
        end

        if savedData.version >= 2 and type(savedData.countedInfections) == 'table' then
            state.countedInfections = copyTable(savedData.countedInfections)
            state.stats = {
                infections = countTable(state.countedInfections),
            }
        else
            rebuildInfectionStats()
        end

        state.firstRestDreamTriggered = savedData.firstRestDreamTriggered == true
    end
end

-- Drop stale cross-save data left from builds before onSave roundtrip.
M.purgeLegacyPersistent()

return M
