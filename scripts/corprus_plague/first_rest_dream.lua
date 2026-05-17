local util = require('openmw.util')
local world = require('openmw.world')
local storageApi = require('scripts.corprus_plague.storage')

local M = {}

local DREAM_MESSAGE = table.concat({
    'You wake from a strange nightmare. You recall only one part, but in perfect detail. ',
    'A tall figure with a golden mask leads you down the gangplank at Seyda Neen introducing you ',
    'to each Imperial officer as though you are a royal guest. You are asked many questions, you ',
    'smile and answer graciously. You puff up your chest and exhale, ash bursts forward from your ',
    'gaping mouth. The tall figure watches approvingly, you can',
    '\226\128\153',
    't see their lips but you know that they are smiling. You smile back through bared teeth, eyes ',
    'wide with the excitement of a jungle cat on the hunt. They are a friend. They are a rival. ',
    'They are willing prey.',
})

local CREATURE_ID = 'corprus_stalker'
local SPAWN_DISTANCE = 160

local function safeRemoveCreature(creature)
    if creature and creature:isValid() then
        pcall(function()
            creature:remove()
        end)
    end
end

local function toVector3(position)
    if type(position) ~= 'table'
        or type(position.x) ~= 'number'
        or type(position.y) ~= 'number'
        or type(position.z) ~= 'number'
    then
        return nil
    end
    return util.vector3(position.x, position.y, position.z)
end

local function getSpawnPosition(playerPosition, yaw)
    local fromPlayer = util.transform.move(playerPosition) * util.transform.rotateZ(yaw or 0)
    return fromPlayer * util.vector3(0, SPAWN_DISTANCE, 0)
end

local function sendDreamMessage()
    local player = world.players[1]
    if player and player:isValid() then
        player:sendEvent('CorprusPlagueFirstRestDreamMessage', { message = DREAM_MESSAGE })
    end
end

function M.trigger(data)
    if storageApi.hasFirstRestDreamTriggered() then
        return
    end

    local cellName = type(data) == 'table' and data.cellName or nil
    local playerPosition = type(data) == 'table' and toVector3(data.position) or nil
    if type(cellName) ~= 'string' or cellName == '' or not playerPosition then
        return
    end

    local creature
    local ok, err = pcall(function()
        creature = world.createObject(CREATURE_ID)
        if not creature or not creature:isValid() then
            error('failed to create corprus stalker')
        end

        local spawnPosition = getSpawnPosition(playerPosition, data.yaw)
        creature.enabled = true
        creature:teleport(cellName, spawnPosition)
        if not creature:isValid() then
            error('corprus stalker not in world after teleport')
        end
    end)

    if not ok then
        print('[corprus_plague] first rest dream spawn failed: ' .. tostring(err))
        safeRemoveCreature(creature)
        return
    end

    storageApi.markFirstRestDreamTriggered()
    sendDreamMessage()
end

return M
