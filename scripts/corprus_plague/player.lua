local core = require('openmw.core')
local selfApi = require('openmw.self')
local I = require('openmw.interfaces')
local self = require('openmw.self')
local types = require('openmw.types')
local config = require('scripts.corprus_plague.config')
local debug = require('scripts.corprus_plague.first_rest_debug')
local eligibility = require('scripts.corprus_plague.eligibility')
local actorRef = require('scripts.corprus_plague.actor_ref')
local settings = require('scripts.corprus_plague.settings')
local interactiveMessage = require('scripts.corprus_plague.interactive_message')

local time = { hour = 3600 }
pcall(function()
    time = require('openmw_aux.time')
end)

pcall(settings.registerPage)

local MIN_REST_GAME_SECONDS = math.max(1, (time.hour or 3600) * 0.5)
local QUEST_CHECK_FRAME_INTERVAL = 60

local activeRestSession
local dreamRequestSent = false
local cureQuestCheckFrames = 0
local cureInitialQuestCheckDone = false
local cureRequestSent = false
local restBedTarget
local trackedUiMode

local REST_MODE = (I.UI.MODE and I.UI.MODE.Rest) or 'Rest'

local function modeIsRest(mode)
    return mode == REST_MODE
end

local function normalizeQuestId(questId)
    if type(questId) ~= 'string' then
        return nil
    end
    return string.lower(questId)
end

local function isCureQuestUpdate(questId, stage)
    return normalizeQuestId(questId) == normalizeQuestId(config.cureQuestId)
        and (tonumber(stage) or 0) >= config.cureQuestStage
end

local function isGreetingResponse(data)
    return type(data) == 'table' and data.type == 'greeting'
end

local function sendCureRequest()
    if cureRequestSent then
        return
    end
    cureRequestSent = true
    core.sendGlobalEvent('CorprusPlagueCureCarrier')
end

local function getPlayerQuest(questId)
    if not types.Player or not types.Player.quests then
        return nil
    end

    local ok, quests = pcall(function()
        return types.Player.quests(selfApi.object)
    end)
    if not ok or not quests then
        return nil
    end

    return quests[questId]
        or quests[normalizeQuestId(questId)]
end

local function getCureQuest()
    return getPlayerQuest(config.cureQuestId)
end

local function checkCureQuestCompletion()
    local quest = getCureQuest()
    if not quest then
        return
    end

    if (tonumber(quest.stage) or 0) >= config.cureQuestStage then
        sendCureRequest()
    end
end

local function isSleepersAwakeActive()
    local quest = getPlayerQuest(config.sleepersAwakeQuestId)
    if not quest then
        return false
    end

    local stage = tonumber(quest.stage) or 0
    return stage >= config.sleepersAwakeQuestStartStage
        and stage < config.sleepersAwakeQuestEndStage
end

local function isSleeperFreed(recordId)
    local questId = config.sleeperQuestIds[recordId]
    if not questId then
        return false
    end

    local quest = getPlayerQuest(questId)
    return quest ~= nil and (tonumber(quest.stage) or 0) >= config.sleeperFreedQuestStage
end

local function getNpcDisplayName(actor)
    local npcRecord = types.NPC.record(actor.recordId)
    if npcRecord and npcRecord.name and npcRecord.name ~= '' then
        return npcRecord.name
    end
    return actor.recordId
end

local function tryScheduleSleeperAwakeDialogue(data)
    if not isGreetingResponse(data) or not isSleepersAwakeActive() then
        return
    end

    local actor = data.actor
    if not eligibility.isNpcActor(actor) then
        return
    end
    if not config.sleeperRecordIds[actor.recordId] then
        return
    end
    if isSleeperFreed(actor.recordId) then
        return
    end

    interactiveMessage.schedule(string.format(
        '%s\n\n"%s"',
        getNpcDisplayName(actor),
        config.sleeperAwakeDialogue
    ))
end

local function isRestingOnBed()
    return restBedTarget and restBedTarget:isValid()
end

local function cellAllowsSleep(cell)
    local ok, noSleep = pcall(function()
        return cell:hasTag('NoSleep')
    end)
    if ok and noSleep then
        return false
    end
    return true
end

local function isWerewolf()
    local ok, result = pcall(function()
        return types.NPC.isWerewolf(selfApi.object)
    end)
    return ok and result
end

local function canPlayerSleep(cell)
    if not cell or cell.isExterior or cell.name == '' then
        return false
    end
    if isWerewolf() then
        return false
    end
    if isRestingOnBed() then
        return true
    end
    return cellAllowsSleep(cell)
end

local function getSleepBlockReason(cell)
    if not cell then
        local current = self.cell
        if not current then
            return 'no cell'
        end
        if current.isExterior then
            return 'exterior cell'
        end
        return 'interior has no name'
    end
    if isWerewolf() then
        return 'werewolf form'
    end
    if not isRestingOnBed() and not cellAllowsSleep(cell) then
        return 'NoSleep cell (wait only)'
    end
    return 'unknown'
end

local function getInteriorCell()
    local cell = self.cell
    if not cell or cell.isExterior or cell.name == '' then
        return nil
    end
    return cell
end

local function noteRestProgress(session)
    if not session then
        return
    end
    if core.getGameTime() > session.startGameTime + 0.01 then
        session.sawTimeAdvance = true
    end
end

local function beginRestSession()
    local cell = getInteriorCell()
    if not canPlayerSleep(cell) then
        debug.log('rest blocked: ' .. getSleepBlockReason(cell))
        return nil
    end

    debug.log('rest session started in ' .. cell.name .. (isRestingOnBed() and ' (bed)' or ''))

    return {
        cellName = cell.name,
        startGameTime = core.getGameTime(),
        sawTimeAdvance = false,
        position = {
            x = self.position.x,
            y = self.position.y,
            z = self.position.z,
        },
        yaw = self.rotation:getYaw(),
    }
end

local function isStillInSessionCell(session)
    local cell = getInteriorCell()
    return cell and session and cell.name == session.cellName
end

local function buildRestPayload(session)
    return {
        cellName = session.cellName,
        position = session.position,
        yaw = session.yaw,
    }
end

local function tryCompleteRestSession()
    local session = activeRestSession
    activeRestSession = nil

    if dreamRequestSent or not session then
        return
    end

    local elapsed = core.getGameTime() - session.startGameTime
    if not session.sawTimeAdvance and elapsed < MIN_REST_GAME_SECONDS then
        debug.log(string.format('rest ended early (%.1fs)', elapsed))
        return
    end
    if not isStillInSessionCell(session) then
        debug.log('rest ended in different cell')
        return
    end

    debug.log(string.format('rest complete in %s (%.1fs)', session.cellName, elapsed))

    dreamRequestSent = true
    core.sendGlobalEvent('CorprusPlagueRestCompleted', buildRestPayload(session))
end

local function setRestBedTarget(target)
    if target and target.isValid and target:isValid() then
        restBedTarget = target
    end
end

local function handleUiModeTransition(oldMode, newMode, arg)
    local wasRest = modeIsRest(oldMode)
    local isRest = modeIsRest(newMode)

    if config.debugFirstRestDream and oldMode ~= newMode then
        debug.log(string.format('UI mode %s -> %s', tostring(oldMode), tostring(newMode)))
    end

    if isRest and not wasRest then
        setRestBedTarget(arg)
        activeRestSession = beginRestSession()
    elseif wasRest and not isRest then
        tryCompleteRestSession()
        restBedTarget = nil
    end

    trackedUiMode = newMode
end

local function pollRestUiMode()
    local mode = I.UI.getMode()
    if mode == trackedUiMode then
        if modeIsRest(mode) then
            noteRestProgress(activeRestSession)
        end
        return
    end
    handleUiModeTransition(trackedUiMode, mode, nil)
end

local function sendTestRestEvent()
    local cell = getInteriorCell() or self.cell
    if not cell or cell.name == '' then
        debug.toast('[Corprus] F9 test: need interior cell')
        return
    end
    dreamRequestSent = true
    core.sendGlobalEvent('CorprusPlagueRestCompleted', {
        cellName = cell.name,
        position = {
            x = self.position.x,
            y = self.position.y,
            z = self.position.z,
        },
        yaw = self.rotation:getYaw(),
    })
end

local function scheduleFirstRestDreamMessages(data)
    if type(data) ~= 'table' then
        return
    end
    if type(data.messages) == 'table' then
        interactiveMessage.scheduleMany(data.messages)
        return
    end
    interactiveMessage.schedule(data.message)
end

return {
    engineHandlers = {
        onFrame = function()
            if trackedUiMode == nil then
                pcall(function()
                    trackedUiMode = I.UI.getMode()
                end)
            end
            pollRestUiMode()
            if not cureInitialQuestCheckDone then
                cureInitialQuestCheckDone = true
                checkCureQuestCompletion()
            end
            cureQuestCheckFrames = (cureQuestCheckFrames or 0) + 1
            if cureQuestCheckFrames >= QUEST_CHECK_FRAME_INTERVAL then
                cureQuestCheckFrames = 0
                checkCureQuestCompletion()
            end
            interactiveMessage.onFrame()
        end,

        onQuestUpdate = function(questId, stage)
            if isCureQuestUpdate(questId, stage) then
                sendCureRequest()
            end
        end,

        onKeyPress = function(key)
            if interactiveMessage.isConsoleKey(key) then
                interactiveMessage.onConsoleKeyPressed()
            end
            if not config.debugFirstRestDream then
                return
            end
            if key.symbol == 'f9' or key.symbol == 'F9' then
                sendTestRestEvent()
            end
        end,
    },

    eventHandlers = {
        UiModeChanged = function(data)
            if type(data) ~= 'table' then
                return
            end
            local oldMode = data.oldMode
            local newMode = data.newMode or data.mode
            if oldMode == nil then
                oldMode = trackedUiMode
            end
            handleUiModeTransition(oldMode, newMode, data.arg)
            interactiveMessage.onUiModeChanged(newMode)
        end,

        CorprusPlagueFirstRestDreamMessage = scheduleFirstRestDreamMessages,

        CorprusPlagueCureMessage = function(data)
            interactiveMessage.schedule(type(data) == 'table' and data.message or nil)
        end,

        CorprusPlagueFirstRestDreamFailed = function()
            dreamRequestSent = false
            debug.log('spawn failed; retry allowed this session')
        end,

        DialogueResponse = function(data)
            if type(data) ~= 'table' then
                return
            end
            local actor = data.actor
            if not eligibility.isNpcActor(actor) then
                return
            end
            tryScheduleSleeperAwakeDialogue(data)
            local plagueKey = actorRef.getPlagueKey(actor)
            if not plagueKey then
                return
            end
            core.sendGlobalEvent('CorprusPlagueInfect', {
                plagueKey = plagueKey,
                player = selfApi.object,
            })
        end,
    },
}
