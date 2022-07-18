-- TODO: this has to become an object
-- TODO: return cell size; window size on demand
local config = {}

config.DEFAULT_OPTS = {
    mappings = {},
    protocol = 'kitty',
}

config.window_info = {
    cols = 0,
    rows = 0,
    xpixels = 0,
    ypixels = 0,
}

return config
