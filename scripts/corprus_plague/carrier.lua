local core = require('openmw.core')
local types = require('openmw.types')
local config = require('scripts.corprus_plague.config')

local M = {}

-- Older builds used these instead of the custom carrier ability.
local legacyCarrierSpellIds = {
    'corprus immunity',
}

local function hasSpell(player, spellId)
    for _, spell in pairs(types.Actor.spells(player)) do
        if spell.id == spellId then
            return true
        end
    end
    return false
end

local function normalizeInfectionCount(infectionCount)
    infectionCount = tonumber(infectionCount) or 0
    if infectionCount < 0 then
        return 0
    end
    return math.floor(infectionCount)
end

function M.syncInfectionCount(player, infectionCount)
    if not player or not player:isValid() then
        return
    end

    local activeEffects = types.Actor.activeEffects(player)
    activeEffects:set(normalizeInfectionCount(infectionCount), config.carrierEffectId)
end

function M.ensure(player, infectionCount)
    if not player or not player:isValid() then
        return
    end
    if not core.magic.spells.records[config.carrierSpellId] then
        error('[corprus_plague] carrier spell missing; requires OpenMW 0.51+ with LOAD script')
    end

    local spells = types.Actor.spells(player)

    for _, legacyId in ipairs(legacyCarrierSpellIds) do
        if hasSpell(player, legacyId) then
            spells:remove(legacyId)
        end
    end

    -- Re-apply each time so updated effect definitions replace stale active instances.
    if hasSpell(player, config.carrierSpellId) then
        spells:remove(config.carrierSpellId)
    end
    spells:add(config.carrierSpellId)
    M.syncInfectionCount(player, infectionCount)
end

return M
