-- Load-context script: registers the carrier ability (requires openmw.content, OpenMW 0.51+).
local content = require('openmw.content')
local config = require('scripts.corprus_plague.config')

-- Record IDs have no spaces (see core.MagicEffectId.ResistCorprusDisease).
local effectTemplate = content.magicEffects.records['resistcorprusdisease']
    or content.magicEffects.records['curecommondisease']
if not effectTemplate then
    error('[corprus_plague] no magic effect template for carrier marker')
end

local iconTemplate = content.magicEffects.records['corprus']
    or content.magicEffects.records['resistcorprusdisease']

content.magicEffects.records[config.carrierEffectId] = {
    template = effectTemplate,
    name = config.carrierEffectName,
    harmful = false,
    icon = iconTemplate and iconTemplate.icon or effectTemplate.icon,
}

-- Seed with magnitude 1 so the effect appears in Magic > Active Effects.
-- carrier.lua overwrites the live magnitude with the per-save infection count.
content.spells.records[config.carrierSpellId] = {
    name = config.carrierSpellName,
    type = content.spells.TYPE.Ability,
    effects = {
        {
            id = config.carrierEffectId,
            range = content.RANGE.Self,
            duration = 0,
            magnitudeMin = 1,
            magnitudeMax = 1,
        },
    },
}
