local wezterm = require("wezterm") ---@type Wezterm

local module = {}

function module.register()
    local function format_cwd(pane)
        local cwd = pane:get_current_working_dir()
        if not cwd then
            return "CWD: <nil>"
        end

        -- Newer WezTerm: URL object
        if type(cwd) == "userdata" then
            if cwd.scheme == "file" and cwd.file_path then
                return cwd.file_path
            end
            return tostring(cwd)
        end

        -- Older / fallback string form
        return tostring(cwd)
    end

    wezterm.on(
        "update-status",
        function(window, pane) window:set_right_status(window:active_workspace() .. " - " .. format_cwd(pane)) end
    )

    local function basename(s) return string.gsub(s, "(.*[/\\])(.*)", "%2") end

    wezterm.on("format-tab-title", function(tab, tabs, panes, config, hover, max_width)
        local pane = tab.active_pane
        -- Get the process name (executable name)
        local title = basename(pane.foreground_process_name)
        local index = tab.tab_index + 1

        -- If for some reason the process name is empty, fall back to the pane title
        if title == "" then
            title = pane.title
        end

        return {
            { Text = " " .. index .. ": " .. title .. " " },
        }
    end)
end

return module
