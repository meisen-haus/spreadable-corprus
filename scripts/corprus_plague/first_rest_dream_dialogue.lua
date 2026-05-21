-- Wise Woman topic progression (corprus_plague_dialogue.omwaddon).
-- Global stage is driven by BNAM on INFO records; Lua only logs (no setStage during dialogue).
local types = require('openmw.types')
local config = require('scripts.corprus_plague.config')
local dreamGlobal = require('scripts.corprus_plague.first_rest_dream_global')
local debug = require('scripts.corprus_plague.first_rest_debug')

local M = {}

local NIGHTMARE_TOPIC = config.firstRestDreamTopicIds.nightmare

local function normalizeInfoId(infoId)
    if type(infoId) ~= 'string' then
        return nil
    end
    return string.lower(infoId)
end

local function isWiseWoman(actor)
    if not actor or not actor:isValid() then
        return false
    end
    if not types.NPC.objectIsInstance(actor) then
        return false
    end
    local record = types.NPC.record(actor)
    if not record or not record.class then
        return false
    end
    return config.wiseWomanClassIds[string.lower(record.class)] == true
end

function M.onDialogueResponse(data)
    if type(data) ~= 'table' then
        return
    end
    if data.type ~= 'topic' then
        return
    end

    local actor = data.actor
    local record = actor and types.NPC.record(actor)
    local classId = record and record.class or 'n/a'
    local infoId = normalizeInfoId(data.infoId)
    debug.logf(
        'DialogueResponse topic recordId=%s infoId=%s actorClass=%s globalStage=%d',
        tostring(data.recordId),
        tostring(infoId),
        tostring(classId),
        dreamGlobal.getStage()
    )

    if not isWiseWoman(actor) then
        debug.logf('DialogueResponse: not Wise Woman (class=%s)', tostring(classId))
        return
    end

    local recordId = data.recordId
    if type(recordId) == 'string' and string.lower(recordId) ~= NIGHTMARE_TOPIC then
        debug.logf('DialogueResponse: recordId mismatch %q vs %q', recordId, NIGHTMARE_TOPIC)
        return
    end
end

function M.onDialogueClosed()
    dreamGlobal.syncPlayerTopics()
    debug.logf('DialogueResponse: dialogue closed, synced topics at global stage=%d', dreamGlobal.getStage())
end

return M
