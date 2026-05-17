local I = require('openmw.interfaces')
local config = require('scripts.corprus_plague.config')

local dayItems = {}
for day = config.minIncubationDays, config.maxIncubationDays do
    dayItems[#dayItems + 1] = day
end

local M = {}

function M.registerPage()
    I.Settings.registerPage({
        key = config.settingsPageKey,
        l10n = 'CorprusPlague',
        name = 'CorprusPlague',
        description = 'settingsPageDescription',
    })
end

function M.registerGroup()
    I.Settings.registerGroup({
        key = config.settingsGroupKey,
        page = config.settingsPageKey,
        l10n = 'CorprusPlague',
        name = 'plagueSettings',
        description = 'plagueSettingsDescription',
        permanentStorage = false,
        order = 0,
        settings = {
            {
                key = 'incubationDays',
                renderer = 'select',
                name = 'incubationDays',
                description = 'incubationDaysDescription',
                default = config.defaultIncubationDays,
                argument = {
                    l10n = 'CorprusPlague',
                    items = dayItems,
                },
            },
        },
    })
end

return M
