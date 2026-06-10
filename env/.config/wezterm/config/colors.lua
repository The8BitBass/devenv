local module = {}

---@param config Config
function module.apply_to_config(config)
    config.colors = {
        foreground = "#FFFFFF",
        background = "#000000",
        cursor_bg = "#FFFFFF",
        cursor_fg = "#000000",
        cursor_border = "#FFFFFF",
        selection_bg = "#FFFFFF",
        selection_fg = "#000000",

        ansi = {
            "#2C2C2C", -- black
            "#AC1000", -- red
            "#006800", -- green
            "#AC8000", -- yellow
            "#0000FC", -- blue
            "#4028C4", -- magenta
            "#008894", -- cyan
            "#BCC0C4", -- white
        },

        brights = {
            "#606060", -- bright black
            "#FC3800", -- bright red
            "#00A800", -- bright green
            "#FCB800", -- bright yellow
            "#0078FC", -- bright blue
            "#6848FC", -- bright magenta
            "#01E8E4", -- bright cyan
            "#FCF8FC", -- bright white
        },
    }
end

return module
