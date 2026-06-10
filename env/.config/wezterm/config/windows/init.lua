local wezterm = require("wezterm") ---@type Wezterm
local repo_picker = require("config.windows.repo_picker")
local wsl_workspaces = require("config.windows.wsl_workspaces")

local function add_keys(config, keys)
    config.keys = config.keys or {}

    for _, key in ipairs(keys) do
        table.insert(config.keys, key)
    end
end

local module = {}

---@param config Config
function module.apply_to_config(config)
    wezterm.log_info("setting up Windows specific config")
    if wezterm.gui then
        for _, gpu in ipairs(wezterm.gui.enumerate_gpus()) do
            if gpu.backend == "Dx12" and gpu.device_type == "IntegratedGpu" then
                config.webgpu_preferred_adapter = gpu
                config.front_end = "WebGpu"
                config.max_fps = 144
                break
            end
        end
    end

    -- config.hide_tab_bar_if_only_one_tab = true
    -- config.window_background_opacity = 0.9
    -- config.win32_system_backdrop = "Mica"
    config.default_prog = { "pwsh.exe" }
    config.default_cwd = "C:/"

    config.wsl_domains = wsl_workspaces.get_wsl_domains()
    wezterm.on("gui-startup", function() wsl_workspaces.create_workspaces_for_all_wsl_distros() end)

    local keys = {
        {
            key = "r",
            mods = "LEADER",
            action = repo_picker.open_as_workspace(),
        },
        {
            key = "u",
            mods = "LEADER",
            action = repo_picker.refresh_cache(),
        },
    }
    add_keys(config, keys)
end

return module
