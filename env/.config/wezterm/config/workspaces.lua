local wezterm = require("wezterm") ---@type Wezterm
local act = wezterm.action
local mux = wezterm.mux


local module = {}

local function add_keys(config, keys)
    config.keys = config.keys or {}

    for _, key in ipairs(keys) do
        table.insert(config.keys, key)
    end
end

---@param config Config
function module.apply_to_config(config)
    local keys = {

        {
            key = "w",
            mods = "LEADER",
            action = act.ShowLauncherArgs({
                flags = "FUZZY|WORKSPACES",
            }),
        },

        {
            key = "W",
            mods = "CTRL|SHIFT",
            action = act.PromptInputLine({
                description = "Name this workspace",
                action = wezterm.action_callback(function(window, pane, line)
                    if not line or line:match("^%s*$") then
                        return
                    end

                    local name = line:gsub("^%s+", ""):gsub("%s+$", "")

                    local mux_window = window:mux_window()
                    mux_window:set_workspace(name)

                    mux.set_active_workspace(name)
                end),
            }),
        },
    }

    add_keys(config, keys)
end

return module
