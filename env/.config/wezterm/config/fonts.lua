local wezterm = require("wezterm") ---@type Wezterm

local module = {}

---@param config Config
function module.apply_to_config(config)
    local font_profiles = {
        {
            name = "Cascadia Mono NF",
            line_height = 1.00,
        },
        {
            name = "DaddyTimeMono Nerd Font Mono",
            line_height = 0.90,
        },
        {
            name = "DepartureMono Nerd Font Mono",
            line_height = 0.90,
        },
        {
            name = "BigBlueTermPlus Nerd Font Mono",
            line_height = 1.0,
        },
        {
            name = "OpenDyslexicM Nerd Font Mono",
            line_height = 0.80,
        },
    }

    local function apply_font_profile(window, profile)
        local overrides = window:get_config_overrides() or {}

        overrides.font = wezterm.font_with_fallback({
            profile.name,
            "Cascadia Mono NF",
        })

        overrides.line_height = profile.line_height

        window:set_config_overrides(overrides)
    end

    local function cycle_font(window, delta)
        delta = delta or 1

        local window_id = tostring(window:window_id())

        wezterm.GLOBAL.font_cycle_state = wezterm.GLOBAL.font_cycle_state or {}

        local current_index = wezterm.GLOBAL.font_cycle_state[window_id] or 1
        local next_index = current_index + delta

        if next_index > #font_profiles then
            next_index = 1
        elseif next_index < 1 then
            next_index = #font_profiles
        end

        wezterm.GLOBAL.font_cycle_state[window_id] = next_index

        apply_font_profile(window, font_profiles[next_index])
    end

    wezterm.on("cycle-font-forward", function(window, pane) cycle_font(window, 1) end)

    wezterm.on("cycle-font-backward", function(window, pane) cycle_font(window, -1) end)

    config.font_size = 12
    config.line_height = 1.0
    config.font = wezterm.font_with_fallback({
        "Cascadia Mono NF",
        "DaddyTimeMono Nerd Font Mono",
        "DepartureMono Nerd Font Mono",
        "BigBlueTermPlus Nerd Font Mono",
        "OpenDyslexicM Nerd Font Mono",
    })
end

return module
