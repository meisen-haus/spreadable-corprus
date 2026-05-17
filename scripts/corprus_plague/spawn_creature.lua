local types = require('openmw.types')
local world = require('openmw.world')

local M = {}

function M.getNpcDisplayName(actor)
    local npcRecord = types.NPC.record(actor.recordId)
    if npcRecord and npcRecord.name and npcRecord.name ~= '' then
        return npcRecord.name
    end
    return actor.recordId
end

function M.create(creatureTemplateId, displayName)
    local template = types.Creature.records[creatureTemplateId]
    local recordDraft = types.Creature.createRecordDraft({
        name = displayName,
        template = template,
    })
    local newRecord = world.createRecord(recordDraft)
    return world.createObject(newRecord.id)
end

return M
