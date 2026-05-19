local config = require('scripts.corprus_plague.config')

local M = {}

function M.log(message)
    if config.debugFirstRestDream and message and message ~= '' then
        print('[corprus_plague] first rest dream: ' .. message)
    end
end

function M.toast(message)
    if not config.debugFirstRestDream or not message or message == '' then
        return
    end
    local I = require('openmw.interfaces')
    if I.UI.showMessage then
        I.UI.showMessage(message)
    end
end

return M
