local wezterm = require("wezterm") ---@type Wezterm
local act = wezterm.action
local mux = wezterm.mux

local M = {}

local function workspace_exists(name)
    for _, workspace in ipairs(mux.get_workspace_names()) do
        if workspace == name then
            return true
        end
    end

    return false
end

local function spawn_tab(mux_window, spec)
    local tab, pane = mux_window:spawn_tab({
        domain = spec.domain,
        cwd = spec.cwd,
        args = spec.args,
    })

    if spec.title then
        tab:set_title(spec.title)
    end

    if spec.send_text then
        pane:send_text(spec.send_text)
    end

    return tab, pane
end

function M.create_workspace_layout(name, tabs)
    if workspace_exists(name) then
        return
    end

    local first = tabs[1]

    local first_tab, first_pane, mux_window = mux.spawn_window({
        workspace = name,
        domain = first.domain,
        cwd = first.cwd,
        args = first.args,
    })

    if first.title then
        first_tab:set_title(first.title)
    end

    if first.send_text then
        first_pane:send_text(first.send_text)
    end

    for i = 2, #tabs do
        spawn_tab(mux_window, tabs[i])
    end
end

return M
