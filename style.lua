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
--   * Corners are square, like the flush bar. With `float: inset` the bar
--     floats 8 px off the screen with 7 px corners, and the windows take the
--     same gap and radius so their edges line up with its frame.
--   * Windows are plain sheets (Kaze's Ha 刃, docs/kaze mockup 05): square
--     corners, a 1 px edge, no shadow, no blur. Unfocused sheets dim a touch.
--     When focus moves the new edge inks up from faint over 600 ms while
--     plugins/hanko.desk runs light once round it. A paper shadow is still
--     there if you want one (`shadow_style`).
--   * Motion is Iai 居合 (core/Iai.js), the beats every Kaze surface moves
--     on: windows draw in and sheathe out, nothing springs, and
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
-- Only the two settings the windows care about: the float and the motion.
-- The preset → float table mirrors core/Style.js PRESETS; keep them in step.
-- A `surface: inset` from before `float` still floats.

local preset_float = { Islet = "inset" }

local style = read(config_home .. "/hanko/style.json") or ""
local edits = style:match('"edits"%s*:%s*(%b{})') or ""
local preset = style:match('"preset"%s*:%s*"(%w+)"') or "Kamon"
local float = edits:match('"float"%s*:%s*"(%w+)"')
  or (edits:match('"surface"%s*:%s*"inset"') and "inset")
  or preset_float[preset] or "flush"
local still = style:match('"motion"%s*:%s*"still"') ~= nil

local inset = float == "inset"

-- ── Frame ───────────────────────────────────────────────────────────────────

-- How windows sit on the page:
--   "none"   hairlines only, as the bar itself (default: Kaze has no shadows)
--   "paper"  a short soft black shadow, down and right; the focused sheet
--            lifts higher and darker
--   "print"  a hard black offset, no blur, focused window only
--   "seal"   the same hard offset in seal red ("you"), focused window only
local shadow_style = "none"

local black = "000000"
local shadows = {
  paper = { sharp = false, range = 14, render_power = 3, offset = { 3, 5 },
            color = rgba(black, 0.55), color_inactive = rgba(black, 0.25) },
  print = { sharp = true, range = 0, render_power = 1, offset = { 4, 4 },
            color = rgba(black, 0.85), color_inactive = clear },
  seal  = { sharp = true, range = 0, render_power = 1, offset = { 4, 4 },
            color = seal, color_inactive = clear },
}
local shadow = shadows[shadow_style]

hl.config({
  general = {
    -- Ma between sheets: 12 px from the screen (8 px with the inset bar,
    -- which floats 8 px off it), 6 px either side of a gap.
    gaps_out = inset and 8 or 12,
    gaps_in = 6,
    border_size = 1,

    col = {
      active_border = ink,
      inactive_border = line,
    },
  },

  decoration = {
    rounding = inset and 7 or 0,

    -- Barely there: the focused sheet reads as the lit one.
    dim_inactive = true,
    dim_strength = 0.06,

    -- Paper is opaque: no glass.
    blur = { enabled = false },

    shadow = shadow and {
      enabled = true,
      sharp = shadow.sharp,
      range = shadow.range,
      render_power = shadow.render_power,
      offset = shadow.offset,
      color = shadow.color,
      color_inactive = shadow.color_inactive,
    } or { enabled = false },
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

-- ── Motion: Iai 居合 (core/Iai.js, docs/kaze §3) ─────────────────────────────
-- What opens draws, what closes sheathes, nothing springs. Hyprland's speed
-- is in tenths of a second (speed = ms / 100); tests/unit.mjs checks every
-- curve and speed here against core/Iai.js.

-- 構 kamae, ready: 90 ms
hl.curve("kamae", { type = "bezier", points = { { 0.2, 0 }, { 0, 1 } } })
-- 抜 nuki, draw: 160 ms, a fast travel and a dead stop, no overshoot
hl.curve("nuki", { type = "bezier", points = { { 0.05, 0.9 }, { 0.1, 1 } } })
-- 振 chiburi, shake off: 220 ms
hl.curve("chiburi", { type = "bezier", points = { { 0.25, 0.1 }, { 0.25, 1 } } })
-- 納 noto, sheath: 240 ms, slow away, then into the edge
hl.curve("noto", { type = "bezier", points = { { 0.7, 0 }, { 0.84, 0 } } })

hl.config({ animations = { enabled = not still } })

hl.animation({ leaf = "global", enabled = true, speed = 1.6, bezier = "nuki" })
-- Windows draw in from the nearest edge and sheathe back into it. No pop-in.
hl.animation({ leaf = "windows", enabled = true, speed = 1.6, bezier = "nuki" })
hl.animation({ leaf = "windowsIn", enabled = true, speed = 1.6, bezier = "nuki", style = "slide" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 2.4, bezier = "noto", style = "slide" })
hl.animation({ leaf = "windowsMove", enabled = true, speed = 1.6, bezier = "nuki" })
-- The edge inks up from faint as focus arrives, over the focus sweep's
-- 600 ms (core/Sweep.js), so the light passes and leaves full ink.
hl.animation({ leaf = "border", enabled = true, speed = 6, bezier = "chiburi" })
-- Fades settle like a shake-off and leave like a sheath.
hl.animation({ leaf = "fade", enabled = true, speed = 0.9, bezier = "kamae" })
hl.animation({ leaf = "fadeIn", enabled = true, speed = 2.2, bezier = "chiburi" })
hl.animation({ leaf = "fadeOut", enabled = true, speed = 2.4, bezier = "noto" })
hl.animation({ leaf = "fadeDim", enabled = true, speed = 0.9, bezier = "kamae" })
hl.animation({ leaf = "fadeShadow", enabled = true, speed = 0.9, bezier = "kamae" })
hl.animation({ leaf = "fadeSwitch", enabled = false })
-- Layer surfaces (launcher, menus, Hanko's sheets) only fade: their own QML
-- draws and sheathes them, so Hyprland mustn't slide them as well.
hl.animation({ leaf = "layers", enabled = true, speed = 1.6, bezier = "nuki" })
hl.animation({ leaf = "layersIn", enabled = true, speed = 1.6, bezier = "nuki", style = "fade" })
hl.animation({ leaf = "layersOut", enabled = true, speed = 2.4, bezier = "noto", style = "fade" })
hl.animation({ leaf = "fadeLayersIn", enabled = true, speed = 1.6, bezier = "nuki" })
hl.animation({ leaf = "fadeLayersOut", enabled = true, speed = 2.4, bezier = "noto" })
-- Workspaces roll a short way, like a scroll, not a full-screen swipe.
hl.animation({ leaf = "workspaces", enabled = true, speed = 2.0, bezier = "nuki", style = "slidefade 8%" })
hl.animation({ leaf = "specialWorkspace", enabled = true, speed = 2.0, bezier = "nuki", style = "slidefadevert 8%" })

-- The overview is already animated by QML; keep Hyprland from sliding its
-- full-screen layer in as well.
hl.layer_rule({ match = { namespace = "^hanko-overview$" }, no_anim = true, animation = "none" })
-- The desk's overlay (the focus sweep, red frames) maps and unmaps with
-- every sweep: it must appear at once, not fade.
hl.layer_rule({ match = { namespace = "^hanko-desk$" }, no_anim = true, animation = "none" })
-- The OSD draws and sheathes itself (Iai); Hyprland mustn't fade it too.
hl.layer_rule({ match = { namespace = "^hanko-osd$" }, no_anim = true, animation = "none" })
-- The menu draws open itself; Hyprland mustn't fade it in as well.
hl.layer_rule({ match = { namespace = "^hanko-menu$" }, no_anim = true, animation = "none" })

-- ── Settings window ─────────────────────────────────────────────────────────
-- Hanko's settings open as a floating sheet in the middle of the screen,
-- never tiled. Matched on class and title so no other Quickshell window
-- picks this up.

o.window({ class = "^org\\.quickshell$", title = "^Hanko settings$" }, {
  float = true,
  center = true,
  size = { 1320, 980 },
})
