local core = require('openmw.core')
local types = require('openmw.types')
local world = require('openmw.world')
local config = require('scripts.corprus_plague.config')

local M = {}

function M.isEssentialNpc(actor)
    if not actor or not actor:isValid() then
        return false
    end
    local record = types.NPC.record(actor.recordId)
    return record ~= nil and record.isEssential
end

-- Vanilla essential-death message; must run on the player script (UI.showInteractiveMessage).
function M.notifyPlayerIfEssential(actor)
    if not config.showProphecyOnEssentialMorph then
        return
    end
    if not M.isEssentialNpc(actor) then
        return
    end

    local message = core.getGMST(config.essentialDeathGmst)
    if not message or message == '' then
        return
    end

    for _, player in ipairs(world.players) do
        player:sendEvent('CorprusPlagueEssentialMorph', { message = message })
    end
end

return M
