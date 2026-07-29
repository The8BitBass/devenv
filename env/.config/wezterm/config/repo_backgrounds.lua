local wezterm = require("wezterm") ---@type Wezterm
local backgrounds = require("config.backgrounds")

local module = {}

-- Repo metadata: <repo-root>/.devenv/project.json with { "id": "project-name" }.
-- Wallpaper map: $XDG_DATA_HOME/devenv/wallpapers/projects.json.
-- Project entries may point directly at image paths, or at keys in the optional
-- images table where per-image HSB transforms can be stored.
local project_metadata_file = ".devenv/project.json"
local wallpaper_mapping_file = "projects.json"
local default_context = "default"

local cwd_repo_cache = {}
local project_id_cache = {}
local mapping_cache = nil
local mapping_loaded = false
local resolved_background_cache = {}
local last_cwd_by_window = {}
local last_background_by_window = {}

local function trim(value) return tostring(value or ""):gsub("^%s+", ""):gsub("%s+$", "") end

local function url_decode(value)
    return tostring(value or ""):gsub("%%(%x%x)", function(hex) return string.char(tonumber(hex, 16)) end)
end

local function normalize_path(path)
    path = tostring(path or ""):gsub("\\", "/")

    if path:match("^/+$") then
        return "/"
    end

    path = path:gsub("/+$", "")

    if path == "" then
        return nil
    end

    if path:match("^%a:$") then
        return path .. "/"
    end

    return path
end

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

local function path_parent(path)
    path = normalize_path(path)

    if not path then
        return nil
    end

    if path == "/" or path:match("^%a:/$") then
        return nil
    end

    local parent = path:match("^(.*)/[^/]+$")

    if not parent or parent == "" then
        if path:sub(1, 1) == "/" then
            return "/"
        end

        return nil
    end

    if parent:match("^%a:$") then
        return parent .. "/"
    end

    return parent
end

local function local_path_exists(path)
    if not path or path == "" then
        return false
    end

    local file = io.open(path, "r")

    if file then
        file:close()
        return true
    end

    local ok, _, code = os.rename(path, path)

    return ok or code == 13
end

local function read_file(path)
    local file = io.open(path, "r")

    if not file then
        return nil
    end

    local text = file:read("*a")
    file:close()

    return text
end

local function bash_single_quote(value) return "'" .. tostring(value):gsub("'", "'\\''") .. "'" end

local function wsl_run(distro, script)
    if not distro or distro == "" then
        return false, ""
    end

    local success, stdout = wezterm.run_child_process({
        "wsl.exe",
        "--distribution",
        distro,
        "--exec",
        "bash",
        "-lc",
        script,
    })

    return success, stdout or ""
end

local function wsl_read_file(distro, path)
    local success, stdout = wsl_run(distro, "cat -- " .. bash_single_quote(path) .. " 2>/dev/null")

    if not success then
        return nil
    end

    return stdout
end

local function parse_json(text, source)
    if not text or trim(text) == "" then
        return nil
    end

    local ok, data = pcall(wezterm.json_parse, text)

    if not ok or type(data) ~= "table" then
        wezterm.log_warn("Failed parsing JSON: ", source)
        return nil
    end

    return data
end

local function data_home()
    local configured = os.getenv("XDG_DATA_HOME")

    if configured and configured ~= "" then
        return normalize_path(configured)
    end

    local home = os.getenv("HOME")

    if home and home ~= "" then
        return path_join(home, ".local", "share")
    end

    return nil
end

local function wallpaper_root()
    local root = data_home()

    if not root then
        return nil
    end

    root = path_join(root, "devenv", "wallpapers")

    if not local_path_exists(path_join(root, wallpaper_mapping_file)) then
        return nil
    end

    return root
end

local function parse_file_uri(value)
    value = tostring(value or "")

    if not value:match("^file://") then
        return nil, nil
    end

    local rest = value:sub(8)
    local host = nil
    local path = rest

    if rest:sub(1, 1) ~= "/" then
        host, path = rest:match("^([^/]*)(/.*)$")
    end

    if host == "" then
        host = nil
    end

    path = url_decode(path or "")

    if path:match("^/%a:") then
        path = path:sub(2)
    end

    return host, normalize_path(path)
end

local function domain_name(pane)
    local ok, name = pcall(function() return pane:get_domain_name() end)

    if ok and type(name) == "string" and name ~= "" then
        return name
    end

    return nil
end

local function distro_from_domain(domain)
    if not domain then
        return nil
    end

    return domain:match("^WSL:(.+)$")
end

local function wsl_path_from_unc(path, host)
    path = normalize_path(path)

    if not path then
        return nil, nil
    end

    if host and host:lower() == "wsl.localhost" then
        local distro, linux_path = path:match("^/([^/]+)(/.*)$")
        return distro, normalize_path(linux_path)
    end

    local distro, linux_path = path:match("^//wsl%.localhost/([^/]+)(/.*)$")

    if distro and linux_path then
        return distro, normalize_path(linux_path)
    end

    distro, linux_path = path:match("^//wsl%$/([^/]+)(/.*)$")

    if distro and linux_path then
        return distro, normalize_path(linux_path)
    end

    return nil, nil
end

local function cwd_info_for_pane(pane)
    local cwd = pane:get_current_working_dir()

    if not cwd then
        return nil
    end

    local host = nil
    local path = nil

    if type(cwd) == "userdata" then
        if cwd.scheme and cwd.scheme ~= "file" then
            return nil
        end

        host = cwd.host
        path = cwd.file_path or cwd.path
    else
        local value = tostring(cwd)
        host, path = parse_file_uri(value)

        if not path then
            path = normalize_path(value)
        end
    end

    if not path then
        return nil
    end

    local domain = domain_name(pane)
    local distro = distro_from_domain(domain)
    local unc_distro, unc_path = wsl_path_from_unc(path, host)

    if unc_path then
        return {
            context = "wsl",
            distro = unc_distro or distro,
            path = unc_path,
        }
    end

    if distro then
        return {
            context = "wsl",
            distro = distro,
            path = path,
        }
    end

    if wezterm.target_triple:find("windows") then
        return {
            context = "windows",
            path = path,
        }
    end

    return {
        context = "linux",
        path = path,
    }
end

local function cwd_cache_key(info)
    if not info then
        return "default"
    end

    return tostring(info.context or "") .. "|" .. tostring(info.distro or "") .. "|" .. tostring(info.path or "")
end

local function repo_cache_key(repo)
    if not repo then
        return "default"
    end

    return tostring(repo.context or "") .. "|" .. tostring(repo.distro or "") .. "|" .. tostring(repo.root or "")
end

local function find_local_repo_root(cwd)
    local dir = normalize_path(cwd)

    while dir do
        if local_path_exists(path_join(dir, ".git")) then
            return dir
        end

        dir = path_parent(dir)
    end

    return nil
end

local function find_wsl_repo_root(info)
    local script = table.concat({
        "dir=" .. bash_single_quote(info.path),
        "while [ -n \"$dir\" ]; do",
        "  if [ -e \"$dir/.git\" ]; then printf '%s\\n' \"$dir\"; exit 0; fi",
        "  parent=$(dirname -- \"$dir\")",
        "  if [ \"$parent\" = \"$dir\" ]; then exit 0; fi",
        "  dir=$parent",
        "done",
    }, "\n")

    local success, stdout = wsl_run(info.distro, script)

    if not success then
        return nil
    end

    local root = trim(stdout)

    if root == "" then
        return nil
    end

    return root
end

local function repo_for_cwd(info)
    local key = cwd_cache_key(info)

    if cwd_repo_cache[key] ~= nil then
        return cwd_repo_cache[key] or nil
    end

    if not info or not info.path then
        cwd_repo_cache[key] = false
        return nil
    end

    local root = nil

    if info.context == "wsl" then
        root = find_wsl_repo_root(info)
    else
        root = find_local_repo_root(info.path)
    end

    if not root then
        cwd_repo_cache[key] = false
        return nil
    end

    local repo = {
        context = info.context,
        distro = info.distro,
        root = root,
    }

    cwd_repo_cache[key] = repo
    return repo
end

local function read_project_metadata(repo)
    if not repo then
        return nil
    end

    local path = path_join(repo.root, project_metadata_file)

    if repo.context == "wsl" then
        return wsl_read_file(repo.distro, path)
    end

    return read_file(path)
end

local function project_id_for_repo(repo)
    local key = repo_cache_key(repo)

    if project_id_cache[key] ~= nil then
        return project_id_cache[key] or nil
    end

    local data = parse_json(read_project_metadata(repo), project_metadata_file)
    local project_id = nil

    if data then
        project_id = trim(data.id or data.project or data.name)
    end

    if project_id == "" then
        project_id = nil
    end

    project_id_cache[key] = project_id or false

    return project_id
end

local function load_mapping(root)
    if mapping_loaded then
        return mapping_cache
    end

    mapping_loaded = true

    if not root then
        return nil
    end

    local path = path_join(root, wallpaper_mapping_file)
    local data = parse_json(read_file(path), path)

    if type(data) ~= "table" then
        return nil
    end

    mapping_cache = data

    return mapping_cache
end

local function project_entries(config)
    if type(config) ~= "table" then
        return nil
    end

    if type(config.projects) == "table" then
        return config.projects
    end

    if type(config.images) == "table" then
        return nil
    end

    return config
end

local function image_metadata(config, image_ref)
    if type(config) ~= "table" or type(config.images) ~= "table" then
        return nil
    end

    local metadata = config.images[image_ref]

    if type(metadata) == "string" then
        return {
            path = metadata,
        }
    end

    if type(metadata) ~= "table" then
        return nil
    end

    return {
        path = metadata.path or metadata.image,
        hsb = metadata.hsb,
    }
end

local function is_absolute_path(path)
    path = tostring(path or "")

    return path:match("^%a:[/\\]") ~= nil or path:match("^[/\\][/\\]") ~= nil or path:sub(1, 1) == "/"
end

local function resolve_image_path(root, image)
    image = trim(image)

    if image == "" then
        return nil
    end

    if is_absolute_path(image) then
        return image
    end

    return path_join(root, image)
end

local function image_spec_for_ref(config, root, image_ref, fallback_hsb)
    image_ref = trim(image_ref)

    if image_ref == "" then
        return nil
    end

    local metadata = image_metadata(config, image_ref)
    local image = metadata and metadata.path or image_ref
    local path = resolve_image_path(root, image)

    if not path then
        return nil
    end

    return {
        path = path,
        hsb = (metadata and metadata.hsb) or fallback_hsb,
    }
end

local function image_spec_for_value(config, root, value, fallback_hsb)
    if type(value) == "string" then
        return image_spec_for_ref(config, root, value, fallback_hsb)
    end

    if type(value) ~= "table" then
        return nil
    end

    local image_ref = value.image or value.path

    if type(image_ref) ~= "string" then
        return nil
    end

    local spec = image_spec_for_ref(config, root, image_ref, fallback_hsb)

    if not spec then
        return nil
    end

    if type(value.hsb) == "table" then
        spec.hsb = value.hsb
    end

    return spec
end

local function hsb_key(hsb)
    if type(hsb) ~= "table" then
        return ""
    end

    return table.concat({
        tostring(hsb.hue or ""),
        tostring(hsb.brightness or ""),
        tostring(hsb.saturation or ""),
    }, ":")
end

local function mapped_image_for_project(root, project_id, context)
    local config = load_mapping(root)
    local mapping = project_entries(config)

    if type(mapping) ~= "table" then
        return nil
    end

    local entry = mapping[project_id]

    if type(entry) == "string" or (type(entry) == "table" and (entry.image or entry.path)) then
        return image_spec_for_value(config, root, entry)
    end

    if type(entry) ~= "table" then
        return nil
    end

    local image = entry[context] or entry[default_context]

    return image_spec_for_value(config, root, image, entry.hsb)
end

local function background_for_cwd(info)
    local repo = repo_for_cwd(info)
    local key = repo_cache_key(repo)

    if resolved_background_cache[key] ~= nil then
        return resolved_background_cache[key].background, resolved_background_cache[key].key
    end

    local root = wallpaper_root()
    local project_id = project_id_for_repo(repo)
    local spec = nil

    if root and project_id then
        spec = mapped_image_for_project(root, project_id, repo.context)
    end

    if spec and spec.path and local_path_exists(spec.path) then
        resolved_background_cache[key] = {
            background = backgrounds.background_for_file(spec.path, spec.hsb),
            key = spec.path .. "|" .. hsb_key(spec.hsb),
        }
    else
        resolved_background_cache[key] = {
            background = backgrounds.default_background(),
            key = "default",
        }
    end

    return resolved_background_cache[key].background, resolved_background_cache[key].key
end

local function window_id(window)
    local ok, id = pcall(function() return window:window_id() end)

    if ok then
        return tostring(id)
    end

    return tostring(window)
end

function module.apply_to_window_for_pane(window, pane)
    if not window or not pane then
        return
    end

    local info = cwd_info_for_pane(pane)
    local id = window_id(window)
    local cwd_key = cwd_cache_key(info)

    if last_cwd_by_window[id] == cwd_key then
        return
    end

    last_cwd_by_window[id] = cwd_key

    local background, background_key = background_for_cwd(info)

    if last_background_by_window[id] == background_key then
        return
    end

    local overrides = window:get_config_overrides() or {}
    overrides.background = background
    window:set_config_overrides(overrides)

    last_background_by_window[id] = background_key
end

function module.clear_cache()
    cwd_repo_cache = {}
    project_id_cache = {}
    mapping_cache = nil
    mapping_loaded = false
    resolved_background_cache = {}
    last_cwd_by_window = {}
    last_background_by_window = {}
end

return module
