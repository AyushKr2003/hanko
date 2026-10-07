-- ╭─────────────────────────────────────────────────────────────────────────╮
-- │  Hanko look'n'feel: Hyprland windows printed on the bar's paper         │
-- │  Load it from ~/.config/hypr/looknfeel.lua, after your own tweaks:      │
-- │                                                                         │
-- │    pcall(dofile, os.getenv("HOME")                                      │
-- │      .. "/.config/omarchy/plugins/hanko.bar/style.lua")                 │
-- │                                                                         │
-- │  pcall keeps Hyprland starting if Hanko is uninstalled; dofile (not     │
-- │  require) re-reads it on every `hyprctl reload`, which `omarchy theme   │
-- │  set` runs, so the windows follow the theme like the bar does.          │
-- ╰─────────────────────────────────────────────────────────────────────────╯
--
-- The bar's grammar (docs/DESIGN.md), carried over to the windows:
--
--   * Paper and ink come from the theme's colors.toml, the same three values
--     core/Ink.qml reads: foreground, background and red (Color.urgent).
--     Nothing here picks its own colour.
--   * Frames are 1 px hairlines. The focused window is framed in ink, the
--     others in Ink.line (the foreground at 22%), as the bar's dividers are.
--   * Corners are square, like the solid bar. With `surface: inset` the bar
--     floats 8 px off the screen with 7 px corners, and the windows take the
--     same gap and radius so their edges line up with its frame.
--   * The focused window is pressed onto the page like a seal: a hard,
--     unblurred print offset down and right, in seal red, because red means
--     "you" or "now". Unfocused windows cast nothing.
--   * Motion follows core/Motion.qml: no springs, nothing over 320 ms, and
--     `motion: still` in style.json cuts window animations too.

local home = os.getenv("HOME")
local state_home = os.getenv("XDG_STATE_HOME") or (home .. "/.local/state")
local config_home = os.getenv("XDG_CONFIG_HOME") or (home .. "/.config")

local function read(path)
  local f = io.open(path, "r")
  if not f then return nil end
  local text = f:read("*a")
  f:close()
  return text
end

-- ── Paper and ink (colors.toml) ─────────────────────────────────────────────

local palette = { foreground = "e0e0e0", background = "000000", red = "a55555" }

local toml = read(state_home .. "/omarchy/current/theme/colors.toml") or ""
local red_found = false
for key, hex in toml:gmatch('\n?%s*([%w_]+)%s*=%s*"#(%x%x%x%x%x%x)"') do
  hex = hex:lower()
  if key == "foreground" or key == "background" then
    palette[key] = hex
  elseif (key == "red" or key == "color1") and not red_found then
    -- Same pick as Omarchy's Color.qml: red, else color1, for urgent.
    palette.red = hex
    red_found = true
  end
end

local function rgba(hex, alpha)
  return string.format("rgba(%s%02x)", hex, math.floor(alpha * 255 + 0.5))
end

local ink = rgba(palette.foreground, 1)
local line = rgba(palette.foreground, 0.22)     -- Ink.line
local muted = rgba(palette.foreground, 0.55)
local seal = rgba(palette.red, 1)
local clear = rgba(palette.background, 0)

-- ── The bar's style (style.json) ────────────────────────────────────────────
-- Only the two settings the windows care about: the surface and the motion.
-- The preset → surface table mirrors core/Style.js PRESETS; keep them in step.

local preset_surface = {
  Sheet = "solid", Scroll = "solid", Hanko = "solid",
  Quiet = "glass", Instrument = "solid", Islet = "inset",
}

local style = read(config_home .. "/hanko/style.json") or ""
local edits = style:match('"edits"%s*:%s*(%b{})') or ""
local preset = style:match('"preset"%s*:%s*"(%w+)"') or "Hanko"
local surface = edits:match('"surface"%s*:%s*"(%w+)"') or preset_surface[preset] or "solid"
local still = style:match('"motion"%s*:%s*"still"') ~= nil

local inset = surface == "inset"

-- ── Frame ───────────────────────────────────────────────────────────────────

local print_offset = 4

hl.config({
  general = {
    -- 8 px from the screen, as the inset bar floats; 8 px between windows.
    gaps_out = 8,
    gaps_in = 4,
    border_size = 1,

    col = {
      active_border = ink,
      inactive_border = line,
    },
  },

  decoration = {
    rounding = inset and 7 or 0,

    shadow = {
      enabled = true,
      sharp = true,
      range = 0,
      render_power = 1,
      offset = { print_offset, print_offset },
      color = seal,
      color_inactive = clear,
    },
  },

  group = {
    col = {
      border_active = ink,
      border_inactive = line,
      border_locked_active = seal,
      border_locked_inactive = line,
    },

    -- Tabs read like the bar's cells: flat, mono labels, the active one
    -- marked by a 1 px rule in ink rather than a filled gradient.
    groupbar = {
      font_family = "monospace",
      font_size = 10,
      font_weight_active = "bold",
      font_weight_inactive = "normal",
      height = 20,
      indicator_height = 1,
      indicator_gap = 2,
      gradients = false,
      rounding = 0,
      text_color = ink,
      text_color_inactive = muted,
      col = {
        active = ink,
        inactive = line,
        locked_active = seal,
        locked_inactive = line,
      },
    },
  },
})

-- ── Motion (core/Motion.qml) ────────────────────────────────────────────────
-- Hyprland's speed is in deciseconds, so speed = ms / 100.

hl.curve("hankoUnroll", { type = "bezier", points = { { 0.2, 0.9 }, { 0.25, 1 } } })
hl.curve("hankoInk", { type = "bezier", points = { { 0.4, 0 }, { 0.2, 1 } } })
hl.curve("hankoPan", { type = "bezier", points = { { 0.16, 1 }, { 0.3, 1 } } })

hl.config({ animations = { enabled = not still } })

-- A window prints in like a sheet (180 ms) and rolls up quicker than it came.
hl.animation({ leaf = "windows", enabled = true, speed = 2.6, bezier = "hankoUnroll" })
hl.animation({ leaf = "windowsIn", enabled = true, speed = 1.8, bezier = "hankoUnroll", style = "popin 96%" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 1.4, bezier = "hankoInk", style = "popin 96%" })
hl.animation({ leaf = "windowsMove", enabled = true, speed = 2.6, bezier = "hankoPan" })
hl.animation({ leaf = "border", enabled = true, speed = 1.4, bezier = "hankoInk" })
hl.animation({ leaf = "fade", enabled = true, speed = 1.4, bezier = "hankoInk" })
hl.animation({ leaf = "fadeIn", enabled = true, speed = 1.4, bezier = "hankoInk" })
hl.animation({ leaf = "fadeOut", enabled = true, speed = 1.4, bezier = "hankoInk" })
hl.animation({ leaf = "fadeShadow", enabled = true, speed = 1.4, bezier = "hankoInk" })
-- Workspaces pan like the scroll does between sections (260 ms).
hl.animation({ leaf = "workspaces", enabled = true, speed = 2.6, bezier = "hankoPan", style = "slide" })
