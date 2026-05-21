local world = require('openmw.world')
local types = require('openmw.types')
local time = require('openmw_aux.time')
local config = require('scripts.corprus_plague.config')
local storageApi = require('scripts.corprus_plague.storage')
local firstRestDream = require('scripts.corprus_plague.first_rest_dream')
local dreamGlobal = require('scripts.corprus_plague.first_rest_dream_global')
local debug = require('scripts.corprus_plague.first_rest_debug')

local M = {}

local MIN_REST_GAME_SECONDS = math.max(1, time.hour * 0.5)

local state = {
    lastGameTime = nil,
}

local function isWerewolf(player)
    local ok, result = pcall(function()
        return types.NPC.isWerewolf(player)
    end)
    return ok and result
end

-- Any named interior (includes beds in dungeons); player script enforces legal sleep for UI rest.
local function cellAllowsRest(cell, player)
    if not cell or cell.isExterior or cell.name == '' then
        return false
    end
    if isWerewolf(player) then
        return false
    end
    return true
end

local function buildTriggerData(player)
    local cell = player.cell
    if not cell or cell.name == '' then
        return nil
    end
    local position = player.position
    return {
        cellName = cell.name,
        position = {
            x = position.x,
            y = position.y,
            z = position.z,
        },
        yaw = player.rotation:getYaw(),
    }
end

function M.resetSnapshots()
    state.lastGameTime = nil
end

function M.onGameReady(player)
    if config.debugFirstRestDream and player and player:isValid() then
        player:sendEvent('ShowMessage', {
            message = '[Corprus] First-rest debug on (F9 = test indoors)',
        })
    end
    if config.debugTriggerDreamOnLoad then
        local data = buildTriggerData(player)
        if data then
            debug.log('debugTriggerDreamOnLoad')
            firstRestDream.trigger(data)
        end
    end
end

function M.onPlayerRestCompleted(data)
    debug.log('CorprusPlagueRestCompleted received')
    firstRestDream.trigger(data)
end

function M.tick()
    if dreamGlobal.getStage() >= 1 then
        dreamGlobal.syncPlayerTopics()
    end

    if storageApi.hasFirstRestDreamTriggered() and not config.debugIgnoreFirstRestDreamSave then
        return
    end

    local player = world.players[1]
    if not player or not player:isValid() then
        return
    end

    local gameTime = world.getGameTime()
    local cell = player.cell

    if not cellAllowsRest(cell, player) then
        state.lastGameTime = gameTime
        return
    end

    if state.lastGameTime then
        local elapsed = gameTime - state.lastGameTime
        if elapsed >= MIN_REST_GAME_SECONDS then
            local data = buildTriggerData(player)
            if data then
                debug.log(string.format('backup tick +%.1fs in %s', elapsed, data.cellName))
                firstRestDream.trigger(data)
            end
        end
    end

    state.lastGameTime = gameTime
end

return M
