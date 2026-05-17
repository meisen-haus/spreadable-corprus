local core = require('openmw.core')
local types = require('openmw.types')
local config = require('scripts.corprus_plague.config')

local M = {}

local function getStaticModel(staticId)
    if not staticId or staticId == '' then
        return nil
    end

    local ok, staticRecord = pcall(function()
        return types.Static.record(staticId)
    end)
    if not ok or not staticRecord then
        staticRecord = types.Static.records[string.lower(staticId)]
    end

    return staticRecord and staticRecord.model or nil
end

local function getEffectVfx(effect)
    local model = getStaticModel(effect.hitStatic) or getStaticModel(effect.castStatic)
    if not model then
        return nil
    end

    return {
        model = model,
        options = {
            loop = false,
            particleTextureOverride = effect.particle or '',
            vfxId = config.spawnVfxId,
        },
    }
end

local function getSpawnVfx()
    for _, effectId in ipairs(config.spawnVfxMagicEffectIds) do
        local effect = core.magic.effects.records[effectId]
        if effect then
            local vfx = getEffectVfx(effect)
            if vfx then
                return vfx
            end
        end
    end
    return nil
end

function M.play(creature)
    if not creature or not creature:isValid() then
        return
    end

    local vfx = getSpawnVfx()
    if not vfx then
        return
    end

    creature:sendEvent('AddVfx', vfx)
end

return M
