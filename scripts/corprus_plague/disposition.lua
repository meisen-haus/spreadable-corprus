local types = require('openmw.types')
local config = require('scripts.corprus_plague.config')
local storageApi = require('scripts.corprus_plague.storage')
local actorRef = require('scripts.corprus_plague.actor_ref')

local M = {}

local function targetPenalty()
    local infections = storageApi.getInfectionCount()
    if infections <= 0 then
        return 0
    end
    return infections * config.dispositionPenaltyPerInfection
end

function M.applyInfectionPenalty(actor, player)
    if not actor or not actor:isValid() or not player or not player:isValid() then
        return
    end

    local plagueKey = actorRef.getPlagueKey(actor)
    if not plagueKey then
        return
    end

    local target = targetPenalty()
    local applied = storageApi.getDispositionPenalty(plagueKey)
    local delta = target - applied
    if delta == 0 then
        return
    end

    types.NPC.modifyBaseDisposition(actor, player, -delta)
    storageApi.setDispositionPenalty(plagueKey, target)
end

return M
