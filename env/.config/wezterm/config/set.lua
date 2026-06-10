local module = {}

---@param config Config
function module.apply_to_config(config)
    config.harfbuzz_features = { "calt=0", "clig=0", "liga=0" }

    config.scrollback_lines = 10000

    config.window_close_confirmation = "NeverPrompt"

    config.adjust_window_size_when_changing_font_size = false

    config.status_update_interval = 1000

    -- domains --
    -- config.unix_domains = {
    --     {
    --         name = "unix",
    --     },
    -- }

    -- Tab Bar --
    config.enable_tab_bar = true
    config.use_fancy_tab_bar = false
    config.tab_bar_at_bottom = true
    config.tab_max_width = 40
    config.show_tab_index_in_tab_bar = true

    -- Window --
    config.initial_cols = 240
    config.initial_rows = 56
end

return module
