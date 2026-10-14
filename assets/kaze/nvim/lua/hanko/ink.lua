-- Hanko's ink ramp in Lua (core/InkMath.js, the same numbers): the theme's
-- foreground walked toward its background until each tier lands on a fixed
-- contrast against the paper. Used by the Neovim colourscheme (colors/hanko.lua)
-- and by scripts/hanko-tools for btop. tests/unit.mjs checks it agrees with
-- InkMath.js.
local M = {}

M.TIERS = { ink = 12, inkDim = 9, inkMuted = 6.2, inkFaint = 4.6 }

local function rgb(hex)
  local h = tostring(hex or ""):gsub("#", "")
  if #h == 3 then h = h:sub(1, 1):rep(2) .. h:sub(2, 2):rep(2) .. h:sub(3, 3):rep(2) end
  return { tonumber(h:sub(1, 2), 16) or 0, tonumber(h:sub(3, 4), 16) or 0, tonumber(h:sub(5, 6), 16) or 0 }
end

local function hex(c)
  local out = "#"
  for i = 1, 3 do
    local v = math.max(0, math.min(255, math.floor(c[i] + 0.5)))
    out = out .. string.format("%02x", v)
  end
  return out
end

-- t = 1 is all a, t = 0 is all b.
function M.mix(a, b, t)
  local A, B = rgb(a), rgb(b)
  return hex({ A[1] * t + B[1] * (1 - t), A[2] * t + B[2] * (1 - t), A[3] * t + B[3] * (1 - t) })
end

function M.luminance(h)
  local c = rgb(h)
  for i = 1, 3 do
    local v = c[i] / 255
    c[i] = v <= 0.03928 and v / 12.92 or ((v + 0.055) / 1.055) ^ 2.4
  end
  return 0.2126 * c[1] + 0.7152 * c[2] + 0.0722 * c[3]
end

function M.contrast(a, b)
  local x, y = M.luminance(a), M.luminance(b)
  return (math.max(x, y) + 0.05) / (math.min(x, y) + 0.05)
end

-- The faintest mix of fg into bg that still reaches `target` (in steps of
-- 0.01, exactly as InkMath.js walks it).
function M.tier(fg, bg, target)
  local t, c = 1, M.mix(fg, bg, 1)
  while t > 0.2 do
    local next = M.mix(fg, bg, t - 0.01)
    if M.contrast(next, bg) < target then break end
    t = t - 0.01
    c = next
  end
  return c
end

function M.isLight(bg) return M.luminance(bg) > 0.4 end

-- Every colour a tool gets: paper, the four inks, line, bone and seal.
function M.ramp(fg, bg, red)
  local light = M.isLight(bg)
  return {
    paper = bg,
    ink = M.tier(fg, bg, M.TIERS.ink),
    inkDim = M.tier(fg, bg, M.TIERS.inkDim),
    inkMuted = M.tier(fg, bg, M.TIERS.inkMuted),
    inkFaint = M.tier(fg, bg, M.TIERS.inkFaint),
    line = M.mix(fg, bg, light and 0.14 or 0.12),
    lineSoft = M.mix(fg, bg, light and 0.07 or 0.06),
    bone = fg,
    seal = red or "#d8452f",
    light = light,
  }
end

-- The current Omarchy theme's colors.toml as { foreground, background, red, ... }.
function M.theme(path)
  local home = os.getenv("HOME") or ""
  local state = os.getenv("XDG_STATE_HOME") or (home .. "/.local/state")
  local config = os.getenv("XDG_CONFIG_HOME") or (home .. "/.config")
  local tries = path and { path } or {
    state .. "/omarchy/current/theme/colors.toml",
    config .. "/omarchy/current/theme/colors.toml",
  }
  for _, p in ipairs(tries) do
    local f = io.open(p, "r")
    if f then
      local out = {}
      for line in f:lines() do
        local k, v = line:match('^%s*([%w_]+)%s*=%s*"(#%x%x%x%x%x%x)"')
        if k then out[k] = v end
      end
      f:close()
      if out.foreground and out.background then return out end
    end
  end
  return nil
end

-- The ramp for the current theme (or a fallback paper and ink).
function M.current(path)
  local t = M.theme(path) or { foreground = "#ddd5c7", background = "#0a0a09", red = "#d8452f" }
  return M.ramp(t.foreground, t.background, t.red)
end

return M
