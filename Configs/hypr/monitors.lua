-- archScratch - monitors. Default: every display at its preferred mode, auto-placed.
-- Pin a layout here, e.g.:
--   hl.monitor({ output = "eDP-1", mode = "1920x1080@60", position = "0x0", scale = 1 })
-- (`hyprctl monitors` lists output names; nwg-displays can help find modes.)
hl.monitor({
    output   = "",
    mode     = "preferred",
    position = "auto",
    scale    = "auto",
})
