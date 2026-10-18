-- btop in four inks (Kaze 風, docs/kaze mockup 12): prints a btop theme for
-- the current Omarchy theme (or the colors.toml given as the first argument).
-- Meters are hairlines of ink on a faint line; a box is a hairline; the
-- selected process is a bone plate. Red only as a reading nears its limit:
-- memory and disks used, and temperature, end in the seal.
--   lua assets/kaze/btop.lua [colors.toml] > ~/.config/btop/themes/hanko.theme
local Ink = require("hanko.ink")
local c = Ink.current(arg and arg[1])
local frame = Ink.mix(c.bone, c.paper, 0.28)

local t = {
  { "main_bg", c.paper }, { "main_fg", c.inkDim }, { "title", c.ink }, { "hi_fg", c.ink },
  { "selected_bg", c.bone }, { "selected_fg", c.paper }, { "inactive_fg", c.inkFaint },
  { "graph_text", c.inkMuted }, { "meter_bg", c.line }, { "proc_misc", c.inkMuted },
  { "cpu_box", frame }, { "mem_box", frame }, { "net_box", frame }, { "proc_box", frame },
  { "div_line", c.line },
  { "temp_start", c.inkMuted }, { "temp_mid", c.ink }, { "temp_end", c.seal },
  { "cpu_start", c.inkFaint }, { "cpu_mid", c.inkDim }, { "cpu_end", c.ink },
  { "free_start", c.inkFaint }, { "free_mid", c.inkMuted }, { "free_end", c.inkDim },
  { "cached_start", c.inkFaint }, { "cached_mid", c.inkMuted }, { "cached_end", c.inkDim },
  { "available_start", c.inkFaint }, { "available_mid", c.inkMuted }, { "available_end", c.inkDim },
  { "used_start", c.inkDim }, { "used_mid", c.ink }, { "used_end", c.seal },
  { "download_start", c.inkFaint }, { "download_mid", c.inkMuted }, { "download_end", c.ink },
  { "upload_start", c.inkFaint }, { "upload_mid", c.inkMuted }, { "upload_end", c.ink },
  { "process_start", c.inkFaint }, { "process_mid", c.inkDim }, { "process_end", c.ink },
}

io.write("# Hanko 判子 · Kaze 風: btop in four inks, written by `hanko tools`\n")
io.write("# for the current Omarchy theme (a theme-set hook rewrites it).\n")
for _, kv in ipairs(t) do io.write(string.format('theme[%s]="%s"\n', kv[1], kv[2])) end
