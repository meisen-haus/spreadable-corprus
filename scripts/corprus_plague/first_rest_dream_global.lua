-- cp_firstrest_dream global (GLOB in corprus_plague_dialogue.omwaddon; short, stages 0–4).
local world = require('openmw.world')
local types = require('openmw.types')
local config = require('scripts.corprus_plague.config')
local debug = require('scripts.corprus_plague.first_rest_debug')

local M = {}

local lastAppliedStage = -1
local lastApplyOk = false
local loggedContentTopics = false

local function logTopicRecordsFromContent()
    local core = require('openmw.core')
    local topics = config.firstRestDreamTopicIds
    for key, id in pairs(topics) do
        local record = core.dialogue.topic.records[id]
        debug.logf('content topic[%s] %q: %s', key, id, record and 'found' or 'MISSING (enable corprus_plague_dialogue.omwaddon)')
    end
    loggedContentTopics = true
end

local function getGlobals()
    local player = world.players[1]
    if not player or not player:isValid() then
        debug.log('getGlobals: no valid player')
        return nil
    end
    local ok, globals = pcall(function()
        return world.mwscript.getGlobalVariables(player)
    end)
    if not ok then
        debug.log('getGlobals: mwscript.getGlobalVariables failed: ' .. tostring(globals))
        return nil
    end
    if not globals then
        debug.log('getGlobals: returned nil')
    end
    return globals
end

local function getPrimaryPlayer()
    local player = world.players[1]
    if player and player:isValid() then
        return player
    end
    return nil
end

function M.getStage()
    local globals = getGlobals()
    if not globals then
        return 0
    end
    local raw = globals[config.firstRestDreamGlobalId]
    if raw == nil then
        debug.logf('getStage: global %q not in mwscript table', config.firstRestDreamGlobalId)
        return 0
    end
    return math.floor(tonumber(raw) or 0)
end

local function applyTopicsOnPlayer(player, stage)
    local topics = config.firstRestDreamTopicIds
    local added = {}

    if not types.Player or not types.Player.addTopic then
        debug.log('applyTopicsOnPlayer: types.Player.addTopic missing (OpenMW 0.51+ required)')
        return false
    end

    local ok, err = pcall(function()
        -- Keep topic on the list after the nightmare (stage >= 1, including completed stage 4).
        if stage >= 1 then
            types.Player.addTopic(player, topics.nightmare)
            table.insert(added, topics.nightmare)
        end
    end)

    if ok then
        debug.logf('applyTopicsOnPlayer: stage=%d added {%s}', stage, table.concat(added, ', '))
    else
        debug.log('applyTopicsOnPlayer failed: ' .. tostring(err))
        if config.debugFirstRestDream and not loggedContentTopics then
            logTopicRecordsFromContent()
        end
    end
    return ok
end

function M.syncPlayerTopics()
    local stage = M.getStage()
    if stage < 1 then
        return
    end

    if stage == lastAppliedStage and lastApplyOk then
        return
    end

    local player = getPrimaryPlayer()
    if not player then
        debug.log('syncPlayerTopics: no player')
        return
    end

    if config.debugFirstRestDream and not loggedContentTopics then
        logTopicRecordsFromContent()
    end

    if stage ~= lastAppliedStage then
        debug.logf('syncPlayerTopics: stage=%d (was %d)', stage, lastAppliedStage)
    end

    if applyTopicsOnPlayer(player, stage) then
        lastAppliedStage = stage
        lastApplyOk = true
        return
    end

    lastApplyOk = false
    player:sendEvent('CorprusPlagueAddDreamTopics', { stage = stage })
end

function M.setStage(stage, opts)
    local globals = getGlobals()
    if not globals then
        debug.logf('setStage(%d): no globals table', stage)
        return
    end

    local before = math.floor(tonumber(globals[config.firstRestDreamGlobalId]) or 0)
    globals[config.firstRestDreamGlobalId] = stage
    local after = M.getStage()
    debug.logf('setStage: %d -> %d (read back %d)', before, stage, after)
    if stage ~= before then
        lastAppliedStage = -1
        lastApplyOk = false
    end

    local syncTopics = not (type(opts) == 'table' and opts.syncTopics == false)
    if syncTopics then
        M.syncPlayerTopics()
    end
end

function M.ensureMinimumStage(minStage)
    local current = M.getStage()
    debug.logf('ensureMinimumStage(%d): current=%d', minStage, current)
    if current < minStage then
        M.setStage(minStage)
    else
        M.syncPlayerTopics()
    end
end

function M.logTopicVisibilityDiagnostics(npcClass)
    if not config.debugFirstRestDream then
        return
    end

    local core = require('openmw.core')
    local topicId = config.firstRestDreamTopicIds.nightmare
    local rec = core.dialogue.topic.records[topicId]
    if not rec then
        debug.logf('visibility: topic %q missing — enable corprus_plague_dialogue.omwaddon', topicId)
        return
    end

    local infoCount = 0
    if rec.infos then
        for i, info in ipairs(rec.infos) do
            infoCount = infoCount + 1
            debug.logf(
                'visibility: info[%d] id=%s classFilter=%s',
                i,
                tostring(info.id),
                tostring(info.filterActorClass)
            )
        end
    end

    if infoCount == 0 then
        debug.log(
            'visibility: topic has 0 INFO lines — NPC cannot offer it; '
                .. 'grep openmw.log for "info record without dialog" or "invalid SCVR"'
        )
    end

    local globals = getGlobals()
    local rawGlobal = globals and globals[config.firstRestDreamGlobalId]
    local classOk = npcClass == nil or config.wiseWomanClassIds[string.lower(tostring(npcClass))] == true
    debug.logf(
        'visibility: stage=%d global=%s npcClass=%s classOk=%s infos=%d',
        M.getStage(),
        tostring(rawGlobal),
        tostring(npcClass),
        tostring(classOk),
        infoCount
    )
    if npcClass and not classOk then
        debug.log('visibility: CNAM mismatch — INFO filter will fail for this NPC')
    end
end

return M
