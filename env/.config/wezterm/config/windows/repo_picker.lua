local wezterm = require("wezterm")
local act = wezterm.action
local mux = wezterm.mux

local M = {}

-- ---------------------------------------------------------------------------
-- Config
-- ---------------------------------------------------------------------------

local is_windows = wezterm.target_triple:find("windows") ~= nil

local windows_home = os.getenv("HOME") or ""
local windows_devenv = os.getenv("DEVENV_ROOT") or ""

local windows_roots = {
    [[C:\Repos]],
    windows_devenv,
}

if windows_home ~= "" then
    table.insert(windows_roots, windows_home .. [[\personal]])
end

-- These are evaluated inside each WSL distro using bash, so $HOME is the WSL
-- user's HOME, not the Windows HOME.
local wsl_roots = {
    "$HOME/personal/dev",
    "$HOME/dev",
    "$HOME/work/dev",
}

local state_dir = os.getenv("XDG_STATE_HOME")
local cache_schema_version = 1
local cache_file = state_dir .. "/repo_picker_cache.json"

-- Workspace names will look like:
--
--   win-devenv-a1b2c3
--   wsl-arch-devenv-f4e5d6
--
-- The hash avoids collisions when two repos have the same folder name.
local include_hash_in_workspace_name = true

-- ---------------------------------------------------------------------------
-- Small helpers
-- ---------------------------------------------------------------------------

local function trim(s) return (s or ""):gsub("^%s+", ""):gsub("%s+$", "") end

local function split_lines(text)
    local lines = {}

    for line in (text or ""):gmatch("[^\r\n]+") do
        line = trim(line)

        if line ~= "" then
            table.insert(lines, line)
        end
    end

    return lines
end

local function basename(path)
    local normalized = tostring(path or ""):gsub("\\", "/")
    return normalized:match("([^/]+)$") or normalized
end

local function ps_single_quote(value) return "'" .. tostring(value):gsub("'", "''") .. "'" end

local function bash_double_quote_allow_env(value)
    -- Intentionally does not escape $, because roots like "$HOME/dev/personal"
    -- should expand inside WSL.
    return '"' .. tostring(value):gsub("\\", "\\\\"):gsub('"', '\\"'):gsub("`", "\\`") .. '"'
end

local function sanitize_workspace_part(value)
    value = tostring(value or "")
    value = value:gsub("[^%w%-_%.]+", "-")
    value = value:gsub("%-+", "-")
    value = value:gsub("^%-+", "")
    value = value:gsub("%-+$", "")

    if value == "" then
        return "repo"
    end

    return value:lower()
end

local function stable_hash(value)
    local hash = 5381
    value = tostring(value or "")

    for i = 1, #value do
        hash = ((hash * 33) + value:byte(i)) % 4294967296
    end

    return string.format("%08x", hash)
end

local function run_powershell(script)
    local success, stdout, stderr = wezterm.run_child_process({
        "pwsh.exe",
        "-NoLogo",
        "-NoProfile",
        "-Command",
        script,
    })

    if success then
        return success, stdout, stderr
    end

    return wezterm.run_child_process({
        "powershell.exe",
        "-NoProfile",
        "-Command",
        script,
    })
end

local function workspace_exists(name)
    for _, existing in ipairs(mux.get_workspace_names()) do
        if existing == name then
            return true
        end
    end

    return false
end

local function switch_to_workspace(window, workspace)
    local ok, err = pcall(mux.set_active_workspace, workspace)

    if not ok then
        wezterm.log_warn("Failed switching to workspace ", workspace, ": ", err)

        if window then
            window:toast_notification("WezTerm", "Failed switching to workspace: " .. workspace, nil, 4000)
        end
    end
end

local function toast(window, message)
    if window then
        window:toast_notification("WezTerm repo picker", message, nil, 3500)
    end
end

-- ---------------------------------------------------------------------------
-- Repo construction / identity / workspace naming
-- ---------------------------------------------------------------------------

local function make_windows_repo(path)
    return {
        kind = "windows",
        name = basename(path),
        path = path,
        label = "Windows  " .. basename(path) .. "  " .. path,
    }
end

local function make_wsl_repo(domain, path)
    return {
        kind = "wsl",
        distro = domain.distribution,
        name = basename(path),
        path = path,
        label = domain.distribution .. "  " .. basename(path) .. "  " .. path,
        domain = { DomainName = domain.name },
    }
end

local function repo_identity(repo)
    local path = tostring(repo.path or ""):gsub("\\", "/")

    if repo.kind == "windows" then
        path = path:lower()
    end

    if repo.kind == "wsl" then
        return "wsl|" .. tostring(repo.distro or "") .. "|" .. path
    end

    return "windows|" .. path
end

local function workspace_name_for_repo(repo)
    local repo_name = sanitize_workspace_part(repo.name)

    local prefix
    if repo.kind == "wsl" then
        prefix = "wsl-" .. sanitize_workspace_part(repo.distro)
    else
        prefix = "win"
    end

    local base = repo_name .. "-" .. prefix

    if include_hash_in_workspace_name then
        return base .. "-" .. stable_hash(repo_identity(repo)):sub(1, 6)
    end

    return base
end

local function sort_repos(repos)
    table.sort(repos, function(a, b) return tostring(a.label):lower() < tostring(b.label):lower() end)

    return repos
end

-- ---------------------------------------------------------------------------
-- Cache
-- ---------------------------------------------------------------------------

local function normalize_cached_repo(repo)
    if type(repo) ~= "table" then
        return nil
    end

    if repo.kind ~= "windows" and repo.kind ~= "wsl" then
        return nil
    end

    if type(repo.path) ~= "string" or repo.path == "" then
        return nil
    end

    if repo.kind == "windows" then
        return make_windows_repo(repo.path)
    end

    if type(repo.distro) ~= "string" or repo.distro == "" then
        return nil
    end

    local domain_name = nil

    if type(repo.domain) == "table" and type(repo.domain.DomainName) == "string" then
        domain_name = repo.domain.DomainName
    end

    if not domain_name or domain_name == "" then
        domain_name = "WSL:" .. repo.distro
    end

    return make_wsl_repo({
        name = domain_name,
        distribution = repo.distro,
    }, repo.path)
end

local function load_cache()
    local file = io.open(cache_file, "r")

    if not file then
        return nil
    end

    local text = file:read("*a")
    file:close()

    if not text or text == "" then
        return nil
    end

    local ok, data = pcall(wezterm.json_parse, text)

    if not ok or type(data) ~= "table" then
        wezterm.log_warn("Failed parsing repo cache: ", cache_file)
        return nil
    end

    if data.schema_version ~= cache_schema_version then
        wezterm.log_info("Ignoring old repo cache schema: ", cache_file)
        return nil
    end

    if type(data.repos) ~= "table" then
        return nil
    end

    local repos = {}
    local seen = {}

    for _, cached in ipairs(data.repos) do
        local repo = normalize_cached_repo(cached)

        if repo then
            local id = repo_identity(repo)

            if not seen[id] then
                seen[id] = true
                table.insert(repos, repo)
            end
        end
    end

    return sort_repos(repos)
end

local function save_cache(repos)
    local data = {
        schema_version = cache_schema_version,
        generated_at = os.date("%Y-%m-%dT%H:%M:%S%z"),
        repos = repos,
    }

    local ok, json = pcall(wezterm.json_encode, data)

    if not ok then
        return false, "Failed encoding repo cache JSON"
    end

    local file, err = io.open(cache_file, "w")

    if not file then
        return false, tostring(err)
    end

    file:write(json)
    file:write("\n")
    file:close()

    return true, nil
end

-- ---------------------------------------------------------------------------
-- Windows repo discovery
-- ---------------------------------------------------------------------------

local function find_windows_repos()
    if not is_windows then
        return {}
    end

    local quoted_roots = {}

    for _, root in ipairs(windows_roots) do
        if root and root ~= "" then
            table.insert(quoted_roots, ps_single_quote(root))
        end
    end

    if #quoted_roots == 0 then
        return {}
    end

    local script = [=[
[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new()
$ErrorActionPreference = 'SilentlyContinue'

$roots = @(
]=] .. table.concat(quoted_roots, ",\n") .. [=[
)

$seen = @{}
$results = New-Object System.Collections.Generic.List[string]

function Add-Repo([string] $Path) {
  if ([string]::IsNullOrWhiteSpace($Path)) {
    return
  }

  $resolved = Resolve-Path -LiteralPath $Path -ErrorAction SilentlyContinue

  if ($null -eq $resolved) {
    return
  }

  $full = $resolved.Path
  $key = $full.ToLowerInvariant()

  if (-not $seen.ContainsKey($key)) {
    $seen[$key] = $true
    [void] $results.Add($full)
  }
}

foreach ($root in $roots) {
  if (-not (Test-Path -LiteralPath $root -PathType Container)) {
    continue
  }

  if (Test-Path -LiteralPath (Join-Path $root '.git')) {
    Add-Repo $root
  }

  Get-ChildItem -LiteralPath $root -Force -Recurse -ErrorAction SilentlyContinue -Filter '.git' |
    ForEach-Object {
      Add-Repo (Split-Path -Parent $_.FullName)
    }
}

$results | Sort-Object
]=]

    local success, stdout, stderr = run_powershell(script)

    if not success then
        wezterm.log_warn("Failed scanning Windows repos: ", stderr)
        return {}
    end

    local repos = {}

    for _, path in ipairs(split_lines(stdout)) do
        table.insert(repos, make_windows_repo(path))
    end

    return repos
end

-- ---------------------------------------------------------------------------
-- WSL repo discovery
-- ---------------------------------------------------------------------------

local function get_wsl_domains()
    if not is_windows then
        return {}
    end

    local ok, domains = pcall(wezterm.default_wsl_domains)

    if not ok then
        wezterm.log_warn("Failed reading default WSL domains: ", domains)
        return {}
    end

    local result = {}

    for _, domain in ipairs(domains or {}) do
        local distro = domain.distribution

        if not distro or distro == "" then
            distro = tostring(domain.name or ""):gsub("^WSL:", "")
        end

        if distro and distro ~= "" then
            table.insert(result, {
                name = domain.name,
                distribution = distro,
            })
        end
    end

    return result
end

local function bash_roots_array()
    local lines = {
        "roots=(",
    }

    for _, root in ipairs(wsl_roots) do
        table.insert(lines, "  " .. bash_double_quote_allow_env(root))
    end

    table.insert(lines, ")")

    return table.concat(lines, "\n")
end

local function find_wsl_repos_for_domain(domain)
    local script = [=[
set -e

]=] .. bash_roots_array() .. [=[

{
  for root in "${roots[@]}"; do
    [ -d "$root" ] || continue

    if [ -e "$root/.git" ]; then
      printf '%s\n' "$root"
    fi

    find "$root" \( -type d -o -type f \) -name .git -prune -print 2>/dev/null |
      while IFS= read -r git_path; do
        printf '%s\n' "${git_path%/.git}"
      done
  done
} | sort -u
]=]

    local success, stdout, stderr = wezterm.run_child_process({
        "wsl.exe",
        "--distribution",
        domain.distribution,
        "--",
        "bash",
        "-lc",
        script,
    })

    if not success then
        wezterm.log_warn("Failed scanning WSL repos for ", domain.distribution, ": ", stderr)
        return {}
    end

    local repos = {}

    for _, path in ipairs(split_lines(stdout)) do
        table.insert(repos, make_wsl_repo(domain, path))
    end

    return repos
end

local function find_wsl_repos()
    local repos = {}

    for _, domain in ipairs(get_wsl_domains()) do
        for _, repo in ipairs(find_wsl_repos_for_domain(domain)) do
            table.insert(repos, repo)
        end
    end

    return repos
end

-- ---------------------------------------------------------------------------
-- Live scan
-- ---------------------------------------------------------------------------

local function scan_all_repos()
    local repos = {}
    local seen = {}

    local function add(repo)
        local id = repo_identity(repo)

        if seen[id] then
            return
        end

        seen[id] = true
        table.insert(repos, repo)
    end

    for _, repo in ipairs(find_windows_repos()) do
        add(repo)
    end

    for _, repo in ipairs(find_wsl_repos()) do
        add(repo)
    end

    return sort_repos(repos)
end

local function refresh_cache_data()
    local repos = scan_all_repos()
    local ok, err = save_cache(repos)

    if not ok then
        wezterm.log_warn("Failed saving repo cache: ", err)
    end

    return repos, ok, err
end

local function get_cached_or_refresh()
    local repos = load_cache()

    if repos and #repos > 0 then
        return repos, true
    end

    local refreshed = refresh_cache_data()
    return refreshed, false
end

-- ---------------------------------------------------------------------------
-- Workspace creation
-- ---------------------------------------------------------------------------

local function spawn_opts_for_repo(repo)
    local opts = {
        cwd = repo.path,
    }

    if repo.domain then
        opts.domain = repo.domain
    end

    return opts
end

local function create_workspace(window, repo, workspace)
    local first_opts = spawn_opts_for_repo(repo)
    first_opts.workspace = workspace

    -- First tab: default shell in CWD.
    local editor_tab, editor_pane, mux_window = mux.spawn_window(first_opts)
    editor_tab:set_title("nvim")

    -- Let the default shell start, then run nvim from inside it.
    editor_pane:send_text("nvim .\r")

    -- Second tab: default shell in same CWD.
    local shell_opts = spawn_opts_for_repo(repo)
    local shell_tab = mux_window:spawn_tab(shell_opts)
    shell_tab:set_title("shell")

    -- Leave the editor tab selected.
    editor_tab:activate()

    switch_to_workspace(window, workspace)
end

local function open_or_create_workspace(window, repo)
    local workspace = workspace_name_for_repo(repo)

    if workspace_exists(workspace) then
        switch_to_workspace(window, workspace)
        return
    end

    create_workspace(window, repo, workspace)
end

-- ---------------------------------------------------------------------------
-- Public actions
-- ---------------------------------------------------------------------------

function M.open_as_workspace()
    return wezterm.action_callback(function(window, pane)
        local repos = get_cached_or_refresh()

        if not repos or #repos == 0 then
            toast(window, "No git repos found")
            return
        end

        local choices = {}

        for i, repo in ipairs(repos) do
            local workspace = workspace_name_for_repo(repo)
            local suffix = workspace_exists(workspace) and "  [existing workspace]" or ""

            table.insert(choices, {
                id = tostring(i),
                label = repo.label .. suffix,
            })
        end

        window:perform_action(
            act.InputSelector({
                title = "Open repo workspace",
                fuzzy = true,
                choices = choices,
                action = wezterm.action_callback(function(inner_window, inner_pane, id)
                    if not id then
                        return
                    end

                    local repo = repos[tonumber(id)]

                    if repo then
                        open_or_create_workspace(inner_window, repo)
                    end
                end),
            }),
            pane
        )
    end)
end

function M.refresh_cache()
    return wezterm.action_callback(function(window, pane)
        local repos, ok, err = refresh_cache_data()

        if not ok then
            toast(window, "Failed refreshing repo cache: " .. tostring(err))
            return
        end

        toast(window, "Repo cache refreshed: " .. tostring(#repos) .. " repos")
    end)
end

return M
