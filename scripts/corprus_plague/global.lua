local world = require('openmw.world')
local transform = require('scripts.corprus_plague.transform')
local carrier = require('scripts.corprus_plague.carrier')
local storageApi = require('scripts.corprus_plague.storage')
local actorRef = require('scripts.corprus_plague.actor_ref')
local config = require('scripts.corprus_plague.config')
local disposition = require('scripts.corprus_plague.disposition')
local settings = require('scripts.corprus_plague.settings')
local firstRestDream = require('scripts.corprus_plague.first_rest_dream')

settings.registerGroup()

local scanAccumulator = 0

local function ensureAllPlayers()
    local infectionCount = storageApi.getInfectionCount()
    for _, player in ipairs(world.players) do
        carrier.ensure(player, infectionCount)
    end
end

local function syncAllPlayerCarrierStats()
    local infectionCount = storageApi.getInfectionCount()
    for _, player in ipairs(world.players) do
        carrier.syncInfectionCount(player, infectionCount)
    end
end

local function getPrimaryPlayer()
    return world.players[1]
end

local function onGameReady()
    storageApi.clearAllPendingTransforms()
    ensureAllPlayers()
    transform.syncWorldWithStorage()
end

return {
    engineHandlers = {
        onNewGame = function()
            storageApi.clearAll()
            ensureAllPlayers()
        end,

        onSave = function()
            return storageApi.exportForSave()
        end,

        onLoad = function(savedData)
            storageApi.importFromSave(savedData)
        end,

        onPlayerAdded = onGameReady,

        onActorActive = function(actor)
            transform.tryTransform(actor)
        end,

        onUpdate = function(dt)
            scanAccumulator = scanAccumulator + dt
            if scanAccumulator < config.transformScanInterval then
                return
            end
            scanAccumulator = 0
            transform.tryTransformActiveActors()
        end,
    },

    eventHandlers = {
        CorprusPlagueInfect = function(data)
            local plagueKey = data.plagueKey
            if not plagueKey then
                return
            end

            local actor = actorRef.findActor(plagueKey)
            if actor and actor:isValid() then
                if transform.infect(actor) then
                    syncAllPlayerCarrierStats()
                end
                disposition.applyInfectionPenalty(actor, data.player or getPrimaryPlayer())
                return
            end

            if not storageApi.isInfected(plagueKey) and not storageApi.isTransformed(plagueKey) then
                if storageApi.markInfected(plagueKey, world.getGameTime()) then
                    syncAllPlayerCarrierStats()
                end
            end
        end,

        CorprusPlagueFirstRestDream = function(data)
            firstRestDream.trigger(data)
        end,
    },
}
