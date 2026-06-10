local wezterm = require("wezterm") ---@type Wezterm

local config = wezterm.config_builder() ---@type Config


local function apply(module_name)
  require(module_name).apply_to_config(config)
end

local function register(module_name)
  require(module_name).register()
end

apply("config.keys")
apply("config.set")
apply("config.colors")
apply("config.fonts")
apply("config.backgrounds")
apply("config.workspaces")

register("config.events")

if wezterm.target_triple:find("windows") then
  apply("config.windows")
else
  apply("config.linux")
end

return config
