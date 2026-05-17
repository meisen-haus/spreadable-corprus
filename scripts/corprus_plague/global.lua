local world = require('openmw.world')
local transform = require('scripts.corprus_plague.transform')
local carrier = require('scripts.corprus_plague.carrier')
local storageApi = require('scripts.corprus_plague.storage')
local actorRef = require('scripts.corprus_plague.actor_ref')
local config = require('scripts.corprus_plague.config')
local settings = require('scripts.corprus_plague.settings')

settings.registerGroup()

local scanAccumulator = 0

local function ensureAllPlayers()
    for _, player in ipairs(world.players) do
        carrier.ensure(player)
    end
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
                transform.infect(actor)
                return
            end

            if not storageApi.isInfected(plagueKey) and not storageApi.isTransformed(plagueKey) then
                storageApi.markInfected(plagueKey, world.getGameTime())
            end
        end,
    },
}
