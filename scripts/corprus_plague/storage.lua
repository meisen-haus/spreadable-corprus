local storage = require('openmw.storage')
local config = require('scripts.corprus_plague.config')

local SAVE_VERSION = 1

-- Per-save state (round-tripped via global.lua onSave/onLoad). Not in Persistent storage.
local state = {
    infections = {},
    transformed = {},
    pendingTransforms = {},
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
        return
    end
    state.infections[plagueKey] = { infectedAt = gameTime }
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
        return
    end
    M.clearInfection(plagueKey)
    M.releaseTransform(plagueKey)
    state.transformed[plagueKey] = entry or {}
end

function M.clearAllPendingTransforms()
    state.pendingTransforms = {}
end

function M.clearAll()
    state.infections = {}
    state.transformed = {}
    state.pendingTransforms = {}
end

function M.exportForSave()
    return {
        version = SAVE_VERSION,
        infections = copyTable(state.infections),
        transformed = copyTable(state.transformed),
    }
end

-- Wipe obsolete Persistent bucket (plague data is per-save via global.lua onSave/onLoad).
function M.purgeLegacyPersistent()
    legacySection:reset({})
end

function M.importFromSave(savedData)
    M.clearAll()
    M.purgeLegacyPersistent()

    if config.clearPlagueDataOnLoad then
        return
    end

    if savedData and savedData.version == SAVE_VERSION then
        if type(savedData.infections) == 'table' then
            state.infections = copyTable(savedData.infections)
        end
        if type(savedData.transformed) == 'table' then
            state.transformed = copyTable(savedData.transformed)
        end
    end
end

-- Drop stale cross-save data left from builds before onSave roundtrip.
M.purgeLegacyPersistent()

return M
