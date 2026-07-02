local wezterm = require("wezterm") ---@type Wezterm
local repo_picker = require("config.windows.repo_picker")
local wsl_workspaces = require("config.windows.wsl_workspaces")

local function add_keys(config, keys)
    config.keys = config.keys or {}

    for _, key in ipairs(keys) do
        table.insert(config.keys, key)
    end
end

local function add_launch_menu(config, entries)
    config.launch_menu = config.launch_menu or {}

    for _, entry in ipairs(entries) do
        table.insert(config.launch_menu, entry)
    end
end

local function file_exists(path)
    if not path or path == "" then
        return false
    end

    local file = io.open(path, "r")

    if file then
        file:close()
        return true
    end

    return false
end

local function git_bash_path()
    local candidates = {}

    local program_files = os.getenv("ProgramFiles")
    if program_files and program_files ~= "" then
        table.insert(candidates, program_files .. [[\Git\bin\bash.exe]])
    end

    local program_files_x86 = os.getenv("ProgramFiles(x86)")
    if program_files_x86 and program_files_x86 ~= "" then
        table.insert(candidates, program_files_x86 .. [[\Git\bin\bash.exe]])
    end

    local local_app_data = os.getenv("LOCALAPPDATA")
    if local_app_data and local_app_data ~= "" then
        table.insert(candidates, local_app_data .. [[\Programs\Git\bin\bash.exe]])
    end

    table.insert(candidates, [[C:\Program Files\Git\bin\bash.exe]])
    table.insert(candidates, [[C:\Program Files (x86)\Git\bin\bash.exe]])

    for _, candidate in ipairs(candidates) do
        if file_exists(candidate) then
            return candidate
        end
    end

    return [[C:\Program Files\Git\bin\bash.exe]]
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

    add_launch_menu(config, {
        {
            label = "PowerShell 7",
            args = { "pwsh.exe", "-NoLogo" },
            cwd = "C:/",
        },
        {
            label = "Command Prompt",
            args = { "cmd.exe" },
            cwd = "C:/",
        },
        {
            label = "Git Bash",
            args = { git_bash_path(), "--login", "-i" },
            cwd = "C:/",
        },
    })

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
