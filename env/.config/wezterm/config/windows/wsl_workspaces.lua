local wezterm = require("wezterm")
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

local function slugify(value) return value:lower():gsub("[^%w]+", "-"):gsub("^-+", ""):gsub("-+$", "") end

local function workspace_name_for_wsl_distro(distro_name) return "wsl-" .. slugify(distro_name) end

function M.get_wsl_domains()
    return wezterm.default_wsl_domains()
end

function M.create_workspace_for_wsl_domain(domain)
    local workspace_name = workspace_name_for_wsl_distro(domain.distribution)

    if workspace_exists(workspace_name) then
        return
    end

    local tab, pane, window = mux.spawn_window({
        workspace = workspace_name,
        domain = {
            DomainName = domain.name,
        },
    })

    tab:set_title("shell")
    window:set_title(workspace_name)
end

function M.create_workspaces_for_all_wsl_distros()
    for _, domain in ipairs(M.get_wsl_domains()) do
        wezterm.log_info("domain: ", domain.name)
        M.create_workspace_for_wsl_domain(domain)
    end
end

function M.switch_to_wsl_workspace(distro_name)
    local workspace_name = workspace_name_for_wsl_distro(distro_name)
    mux.set_active_workspace(workspace_name)
end

return M
