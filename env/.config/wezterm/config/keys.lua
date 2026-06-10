local wezterm = require("wezterm") ---@type Wezterm
local act = wezterm.action

local module = {}

---@param config Config
function module.apply_to_config(config)
    config.leader = {
        key = "a",
        mods = "ALT",
        timeout_milliseconds = 2000,
    }

    config.keys = {
        {
            key = "P",
            mods = "LEADER",
            action = act.ActivateCommandPalette,
        },
        {
            key = "R",
            mods = "CTRL|SHIFT",
            action = act.ReloadConfiguration,
        },

        {
            key = "f",
            mods = "LEADER",
            action = act.EmitEvent("cycle-font-forward"),
        },
        {
            key = "F",
            mods = "LEADER|SHIFT",
            action = act.EmitEvent("cycle-font-backward"),
        },

        {
            key = "N",
            mods = "CTRL|SHIFT",
            action = wezterm.action.ActivateTabRelative(1),
        },
        {
            key = "P",
            mods = "CTRL|SHIFT",
            action = wezterm.action.ActivateTabRelative(-1),
        },

    }
end

return module
