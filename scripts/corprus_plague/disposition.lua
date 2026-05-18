local types = require('openmw.types')
local dispositionModifier = require('scripts.corprus_plague.disposition_modifier')
local storageApi = require('scripts.corprus_plague.storage')
local actorRef = require('scripts.corprus_plague.actor_ref')

local M = {}

local function targetPenalty()
    local infections = storageApi.getInfectionCount()
    if infections <= 0 then
        return 0
    end
    return infections * dispositionModifier.getPerInfection()
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

    if delta > 0 then
        local currentBase = types.NPC.getBaseDisposition(actor, player)
        local reduction = math.min(delta, math.max(0, currentBase))
        if reduction > 0 then
            types.NPC.modifyBaseDisposition(actor, player, -reduction)
        end
    else
        types.NPC.modifyBaseDisposition(actor, player, -delta)
    end

    storageApi.setDispositionPenalty(plagueKey, target)
end

return M
