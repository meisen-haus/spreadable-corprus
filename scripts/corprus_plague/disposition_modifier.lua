local storage = require('openmw.storage')
local config = require('scripts.corprus_plague.config')

local M = {}

local function clampModifier(value)
    if type(value) ~= 'number' then
        value = tonumber(value)
    end
    if value == nil then
        return config.defaultDispositionModifier
    end
    value = math.floor(value * 10 + 0.5) / 10
    if value < config.minDispositionModifier then
        return config.minDispositionModifier
    end
    if value > config.maxDispositionModifier then
        return config.maxDispositionModifier
    end
    return value
end

function M.getPerInfection()
    local value = storage.globalSection(config.settingsGroupKey):get('dispositionModifier')
    if value == nil then
        return config.defaultDispositionModifier
    end
    return clampModifier(value)
end

return M
