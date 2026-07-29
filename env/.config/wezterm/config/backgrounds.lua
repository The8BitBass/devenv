local module = {}

local default_hsb = {
    hue = 1.0,
    brightness = 0.10,
    saturation = 1.00,
}

local default_background_files = {}

local function path_join(...)
    local parts = {}

    for _, part in ipairs({ ... }) do
        part = tostring(part or ""):gsub("\\", "/")

        if #parts == 0 then
            if part:match("^/+$") then
                part = "/"
            else
                part = part:gsub("/+$", "")
            end
        else
            part = part:gsub("^/+", ""):gsub("/+$", "")
        end

        if part ~= "" then
            table.insert(parts, part)
        end
    end

    if #parts == 0 then
        return ""
    end

    local result = parts[1]

    for i = 2, #parts do
        if result == "/" then
            result = result .. parts[i]
        else
            result = result .. "/" .. parts[i]
        end
    end

    return result
end

local function file_exists(path)
    local file = io.open(path, "r")

    if file then
        file:close()
        return true
    end

    local ok, _, code = os.rename(path, path)

    return ok or code == 13
end

local function add_default_candidate_roots()
    local candidates = {}

    local data_home = os.getenv("XDG_DATA_HOME")

    if not data_home or data_home == "" then
        local home = os.getenv("HOME")

        if home and home ~= "" then
            data_home = path_join(home, ".local", "share")
        end
    end

    if data_home and data_home ~= "" then
        table.insert(candidates, path_join(data_home, "devenv", "wallpapers"))
    end

    local config_home = os.getenv("XDG_CONFIG_HOME")
    if config_home and config_home ~= "" then
        table.insert(candidates, path_join(config_home, "wezterm"))
    end

    local devenv_root = os.getenv("DEVENV_ROOT")
    if devenv_root and devenv_root ~= "" then
        table.insert(candidates, path_join(devenv_root, "env", ".config", "wezterm"))
    end

    local names = {
        "default.jpg",
        "default.jpeg",
        "default.png",
        "Deku_Tree_Night.jpg",
    }

    for _, root in ipairs(candidates) do
        for _, name in ipairs(names) do
            table.insert(default_background_files, path_join(root, name))
        end
    end
end

add_default_candidate_roots()

local function merge_hsb(hsb)
    hsb = type(hsb) == "table" and hsb or {}

    return {
        hue = tonumber(hsb.hue) or default_hsb.hue,
        brightness = tonumber(hsb.brightness) or default_hsb.brightness,
        saturation = tonumber(hsb.saturation) or default_hsb.saturation,
    }
end

local function image_background(file, hsb)
    return {
        source = { File = file },
        width = "Cover",
        height = "Cover",
        horizontal_align = "Center",
        vertical_align = "Middle",
        hsb = merge_hsb(hsb),
    }
end

function module.default_background()
    for _, file in ipairs(default_background_files) do
        if file_exists(file) then
            return {
                image_background(file),
            }
        end
    end

    return {
        {
            source = { Color = "#050505" },
            width = "100%",
            height = "100%",
        },
    }
end

function module.background_for_file(file, hsb)
    return {
        image_background(file, hsb),
    }
end

---@param config Config
function module.apply_to_config(config)
    config.background = module.default_background()
    --[[
        -- {
        --     source = { Color = "black" },
        --     width = "100%",
        --     height = "100%",
        --     opacity = 0.4,
        -- },
    --]]
end

return module
