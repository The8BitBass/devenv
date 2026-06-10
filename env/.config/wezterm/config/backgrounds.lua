local module = {}

---@param config Config
function module.apply_to_config(config)
    config.background = {
        {
            source = { File = "C:\\.config\\wezterm\\Deku_Tree_Night.jpg" },
            width = "Cover",
            height = "Cover",
            horizontal_align = "Center",
            vertical_align = "Middle",
            hsb = {
                hue = 1.0,
                brightness = 0.10,
                saturation = 1.00,
            },
        },
        -- {
        --     source = { Color = "black" },
        --     width = "100%",
        --     height = "100%",
        --     opacity = 0.4,
        -- },
    }
end

return module
