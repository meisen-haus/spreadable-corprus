local world = require('openmw.world')
local config = require('scripts.corprus_plague.config')
local incubation = require('scripts.corprus_plague.incubation')
local eligibility = require('scripts.corprus_plague.eligibility')
local storageApi = require('scripts.corprus_plague.storage')
local actorRef = require('scripts.corprus_plague.actor_ref')
local inventory = require('scripts.corprus_plague.inventory')
local prophecy = require('scripts.corprus_plague.prophecy')
local spawnCreature = require('scripts.corprus_plague.spawn_creature')
local disableActor = require('scripts.corprus_plague.disable_actor')

local M = {}

local totalWeight = 0
for _, entry in ipairs(config.transformCreatures) do
    totalWeight = totalWeight + entry.weight
end

local function pickCreatureId()
    local roll = math.random() * totalWeight
    local cumulative = 0
    for _, entry in ipairs(config.transformCreatures) do
        cumulative = cumulative + entry.weight
        if roll <= cumulative then
            return entry.id
        end
    end
    return config.transformCreatures[1].id
end

local function safeRemoveCreature(creature)
    if creature and creature:isValid() then
        pcall(function()
            creature:remove()
        end)
    end
end

function M.tryTransform(actor)
    if not eligibility.isNpcActor(actor) then
        return
    end

    local plagueKey = actorRef.getPlagueKey(actor)
    if not plagueKey then
        return
    end

    if storageApi.isTransformed(plagueKey) then
        if actor:isValid() and actor.enabled then
            disableActor.disable(actor)
        end
        return
    end

    if storageApi.isTransformPending(plagueKey) then
        return
    end

    local infection = storageApi.getInfection(plagueKey)
    if not infection then
        return
    end

    local elapsed = world.getGameTime() - infection.infectedAt
    if elapsed < incubation.getSeconds() then
        return
    end

    if not actor:isValid() then
        return
    end

    if not storageApi.claimTransform(plagueKey) then
        return
    end

    local creature
    local committed = false

    local ok, err = pcall(function()
        local cell = actor.cell
        if not cell then
            error('npc has no cell')
        end

        local position = actor.position
        local rotation = actor.rotation
        local cellName = cell.name
        local displayName = spawnCreature.getNpcDisplayName(actor)

        prophecy.notifyPlayerIfEssential(actor)

        local creatureId = pickCreatureId()
        creature = spawnCreature.create(creatureId, displayName)
        if not creature or not creature:isValid() then
            error('failed to create corprus creature')
        end

        creature.enabled = true
        creature:teleport(cellName, position, { rotation = rotation })
        if not creature:isValid() then
            error('corprus not in world after teleport')
        end

        inventory.transferActorLoot(actor, creature)

        disableActor.disable(actor)

        storageApi.markTransformed(plagueKey, {
            recordId = actor.recordId,
            cellName = cellName,
        })
        committed = true
    end)

    if not ok and not committed then
        print('[corprus_plague] transform failed for ' .. tostring(plagueKey)
            .. ' (' .. tostring(actor.recordId) .. '): ' .. tostring(err))
        safeRemoveCreature(creature)
        storageApi.releaseTransform(plagueKey)
    end
end

function M.infect(actor)
    if not eligibility.canInfect(actor, storageApi) then
        return false
    end

    local plagueKey = actorRef.getPlagueKey(actor)
    if not plagueKey then
        return false
    end

    storageApi.markInfected(plagueKey, world.getGameTime())
    return true
end

function M.tryTransformActiveActors()
    for _, actor in ipairs(world.activeActors) do
        M.tryTransform(actor)
    end
end

-- After load: re-disable transformed refs and run pending transforms for active NPCs.
function M.syncWorldWithStorage()
    for _, actor in ipairs(world.activeActors) do
        M.tryTransform(actor)
    end
end

return M
