local storage = require('openmw.storage')
local time = require('openmw_aux.time')
local config = require('scripts.corprus_plague.config')

local M = {}

function M.getDays()
    local days = storage.globalSection(config.settingsGroupKey):get('incubationDays')
    if type(days) ~= 'number' then
        return config.defaultIncubationDays
    end
    days = math.floor(days)
    if days < config.minIncubationDays then
        return config.minIncubationDays
    end
    if days > config.maxIncubationDays then
        return config.maxIncubationDays
    end
    return days
end

function M.getSeconds()
    return M.getDays() * time.day
end

return M
