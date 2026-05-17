local core = require('openmw.core')
local I = require('openmw.interfaces')
local eligibility = require('scripts.corprus_plague.eligibility')
local actorRef = require('scripts.corprus_plague.actor_ref')
local settings = require('scripts.corprus_plague.settings')

settings.registerPage()

return {
    eventHandlers = {
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
