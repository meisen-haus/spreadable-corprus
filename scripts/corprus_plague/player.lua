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

-- OpenMW briefly switches Rest -> Loading while the rest menu initializes; not a real cancel.
local function isRestUiFlicker(mode)
    return mode == 'Loading' or mode == 'LoadingWallpaper'
end

local function modeIsRest(mode)
    return mode == REST_MODE
end

local DIALOGUE_MODE = (I.UI.MODE and I.UI.MODE.Dialogue) or 'Dialogue'
local loggedUiModes = false

local function isDialogueUiMode(mode)
    if type(mode) ~= 'string' or mode == '' then
        return false
    end
    if mode == DIALOGUE_MODE or mode == 'Dialogue' then
        return true
    end
    return mode:lower():find('dialog', 1, true) ~= nil
end

local function requestDreamTopicSync(reason, dialogueTarget)
    debug.log('requestDreamTopicSync: ' .. tostring(reason))
    local payload = { reason = reason }
    if dialogueTarget and dialogueTarget.isValid and dialogueTarget:isValid()
        and types.NPC.objectIsInstance(dialogueTarget)
    then
        local record = types.NPC.record(dialogueTarget)
        payload.npcClass = record and record.class
        payload.npcId = record and record.id
    end
    core.sendGlobalEvent('CorprusPlagueSyncDreamTopics', payload)
end

local function logDialogueTarget(arg)
    if not config.debugFirstRestDream then
        return
    end
    if not arg or not (arg.isValid and arg:isValid()) then
        debug.log('dialogue open: no NPC in UiModeChanged arg')
        return
    end
    if not types.NPC.objectIsInstance(arg) then
        debug.log('dialogue open: target is not an NPC')
        return
    end
    local record = types.NPC.record(arg)
    local classId = record and record.class
    local classOk = classId and config.wiseWomanClassIds[string.lower(classId)] == true
    debug.logf(
        'dialogue open: npc=%s class=%s wiseWoman=%s',
        tostring(record and record.id),
        tostring(classId),
        tostring(classOk)
    )
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

local function addDreamTopicsForStage(stage)
    stage = tonumber(stage) or 0
    if stage < 1 then
        debug.log('addDreamTopics: skipped (stage < 1)')
        return
    end

    local topics = config.firstRestDreamTopicIds
    local added = {}
    local function addOne(topicId)
        if types.Player and types.Player.addTopic then
            types.Player.addTopic(self, topicId)
        elseif self.type and self.type.addTopic then
            self.type.addTopic(self, topicId)
        else
            error('no addTopic API')
        end
    end

    local ok, err = pcall(function()
        if stage >= 1 and stage < 4 then
            addOne(topics.nightmare)
            table.insert(added, topics.nightmare)
        end
    end)
    if ok then
        debug.logf('addDreamTopics: stage=%d added {%s}', stage, table.concat(added, ', '))
    else
        debug.log('addDreamTopics failed: ' .. tostring(err))
    end
end

local function sendCureRequest()
    if cureRequestSent then
        return
    end
    cureRequestSent = true
    core.sendGlobalEvent('CorprusPlagueCureCarrier')
end

local function getCureQuest()
    if not types.Player or not types.Player.quests then
        return nil
    end

    local ok, quests = pcall(function()
        return types.Player.quests(selfApi.object)
    end)
    if not ok or not quests then
        return nil
    end

    return quests[config.cureQuestId]
        or quests[normalizeQuestId(config.cureQuestId)]
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
        if activeRestSession then
            debug.log('rest session resumed (after ' .. tostring(oldMode) .. ')')
        else
            activeRestSession = beginRestSession()
        end
    elseif wasRest and not isRest then
        if isRestUiFlicker(newMode) then
            debug.log('rest UI flicker Rest -> ' .. tostring(newMode) .. ' (keeping session)')
        else
            tryCompleteRestSession()
            restBedTarget = nil
        end
    end

    trackedUiMode = newMode
end

local function pollRestUiMode()
    local mode = I.UI.getMode()
    if activeRestSession then
        noteRestProgress(activeRestSession)
    end
    if mode == trackedUiMode then
        return
    end
    if not loggedUiModes and config.debugFirstRestDream and I.UI.MODE then
        loggedUiModes = true
        local names = {}
        for name, _ in pairs(I.UI.MODE) do
            table.insert(names, tostring(name))
        end
        table.sort(names)
        debug.logf('I.UI.MODE keys: %s', table.concat(names, ', '))
        debug.logf('DIALOGUE_MODE constant: %s', tostring(DIALOGUE_MODE))
    end
    handleUiModeTransition(trackedUiMode, mode, nil)
    if isDialogueUiMode(mode) then
        requestDreamTopicSync('pollRestUiMode', nil)
    end
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
            if key.symbol == 'f10' or key.symbol == 'F10' then
                requestDreamTopicSync('F10', nil)
                debug.toast('[Corprus] F10 topic sync — close dialogue and talk again')
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
            if config.debugFirstRestDream and oldMode ~= newMode then
                debug.logf('UiModeChanged: %s -> %s', tostring(oldMode), tostring(newMode))
            end
            if isDialogueUiMode(oldMode) and not isDialogueUiMode(newMode) then
                core.sendGlobalEvent('CorprusPlagueFirstRestDreamDialogueClosed', {})
            end
            if isDialogueUiMode(newMode) then
                logDialogueTarget(data.arg)
                requestDreamTopicSync('UiModeChanged', data.arg)
            end
        end,

        CorprusPlagueAddDreamTopics = function(data)
            local stage = type(data) == 'table' and data.stage or 0
            debug.logf('CorprusPlagueAddDreamTopics event stage=%s', tostring(stage))
            addDreamTopicsForStage(stage)
        end,

        CorprusPlagueFirstRestDreamMessage = function(data)
            interactiveMessage.schedule(type(data) == 'table' and data.message or nil)
        end,

        CorprusPlagueCureMessage = function(data)
            interactiveMessage.schedule(type(data) == 'table' and data.message or nil)
        end,

        CorprusPlagueFirstRestDreamFailed = function()
            dreamRequestSent = false
            debug.log('spawn failed; retry allowed this session')
        end,

        DialogueResponse = function(data)
            -- Global script only: first_rest_dream_dialogue uses openmw.world.
            core.sendGlobalEvent('CorprusPlagueFirstRestDreamDialogue', data)

            local actor = data.actor
            if not eligibility.isNpcActor(actor) then
                return
            end
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
