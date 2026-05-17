local core = require('openmw.core')
local I = require('openmw.interfaces')
local self = require('openmw.self')
local eligibility = require('scripts.corprus_plague.eligibility')
local actorRef = require('scripts.corprus_plague.actor_ref')
local settings = require('scripts.corprus_plague.settings')

settings.registerPage()

local MIN_REST_GAME_SECONDS = 1800
local REST_CONFIRMATION_WINDOW_SECONDS = 10

local restCandidate
local pendingRestCandidate
local dreamRequestSent = false

local function isRestMode(mode)
    if type(mode) ~= 'string' then
        return false
    end
    local normalized = mode:lower()
    return normalized:find('rest', 1, true) ~= nil
        or normalized:find('wait', 1, true) ~= nil
end

local function getInteriorCell()
    local cell = self.cell
    if not cell or cell.isExterior or cell.name == '' then
        return nil
    end
    return cell
end

local function snapshotRestAttempt()
    local cell = getInteriorCell()
    if not cell then
        return nil
    end

    return {
        cellName = cell.name,
        gameTime = core.getGameTime(),
        position = {
            x = self.position.x,
            y = self.position.y,
            z = self.position.z,
        },
        yaw = self.rotation:getYaw(),
    }
end

local function isStillInCandidateCell(candidate)
    local cell = getInteriorCell()
    return cell and candidate and cell.name == candidate.cellName
end

local function queueCompletedRest(candidate)
    candidate.expiresAt = core.getRealTime() + REST_CONFIRMATION_WINDOW_SECONDS
    pendingRestCandidate = candidate
end

local function trySendFirstRestDream()
    if dreamRequestSent or not pendingRestCandidate then
        return
    end

    local gameTimeElapsed = core.getGameTime() - pendingRestCandidate.gameTime
    if gameTimeElapsed >= MIN_REST_GAME_SECONDS and isStillInCandidateCell(pendingRestCandidate) then
        dreamRequestSent = true
        core.sendGlobalEvent('CorprusPlagueFirstRestDream', pendingRestCandidate)
        pendingRestCandidate = nil
        return
    end

    if core.getRealTime() > pendingRestCandidate.expiresAt then
        pendingRestCandidate = nil
    end
end

local function updateFirstRestDream()
    if dreamRequestSent then
        return
    end

    if isRestMode(I.UI.getMode()) then
        restCandidate = restCandidate or snapshotRestAttempt()
        return
    end

    if restCandidate then
        queueCompletedRest(restCandidate)
        restCandidate = nil
    end

    trySendFirstRestDream()
end

local function showDreamMessage(message)
    if not message or message == '' then
        return
    end
    if I.UI.showInteractiveMessage then
        I.UI.showInteractiveMessage(message)
    else
        I.UI.showMessage(message)
    end
end

return {
    engineHandlers = {
        onFrame = function()
            updateFirstRestDream()
        end,
    },

    eventHandlers = {
        CorprusPlagueFirstRestDreamMessage = function(data)
            showDreamMessage(type(data) == 'table' and data.message or nil)
        end,

        CorprusPlagueEssentialMorph = function(data)
            if data.message and data.message ~= '' then
                -- Non-blocking message; interactive boxes leave the cursor active in menus.
                I.UI.showMessage(data.message)
            end
        end,

        -- Fires when an NPC speaks in dialogue (topic, greeting, persuasion, voice, journal).
        DialogueResponse = function(data)
            local actor = data.actor
            if not eligibility.isNpcActor(actor) then
                return
            end
            local plagueKey = actorRef.getPlagueKey(actor)
            if not plagueKey then
                return
            end
            core.sendGlobalEvent('CorprusPlagueInfect', { plagueKey = plagueKey })
        end,
    },
}
