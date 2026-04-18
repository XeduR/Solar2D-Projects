-- luacheck: no global (suppress warnings from this file)

-- Line length
max_line_length = 160

-- Use Lua 5.1 as base (Solar2D uses 5.1)
std = "lua51"

-- Solar2D globals (writable - allows overwriting for wrappers):
globals = {
    -- Solar2D core & internals:
    "audio",
    "display",
    "easing",
    "graphics",
    "media",
    "native",
    "network",
    "physics",
    "Runtime",
    "system",
    "timer",
    "transition",
    "metatable",

    -- project/framework specific custom globals:
    "utils",
}

-- Ignore unused arguments with specific names:
-- 212 = unused argument
ignore = {
    "212/self",
    "212/event",
    "212/_",
    "212/_*",
}

