-- Hanko's Hyprland keybindings. Loaded from ~/.config/hypr/bindings.lua only
-- while Hanko is the active bar:
--
--   if bar == "hanko" then
--     pcall(dofile, os.getenv("HOME") .. "/.config/omarchy/plugins/hanko.bar/keybinds.lua")
--   end
--
-- `o` is Omarchy's global binding helper. The look and motion live in style.lua.

-- o.rebind comes from ~/.config/hypr/bindings.lua; restated here so this file
-- works on its own. Same arguments as o.bind, after unbinding the key.
function o.rebind(keys, description, dispatcher, options)
  hl.unbind(keys)
  o.bind(keys, description, dispatcher, options)
end

o.rebind("SUPER + TAB", "Hanko overview", "omarchy-shell hanko overview")          -- was: Next workspace
o.bind("SUPER + D", "Hanko scroll", "omarchy-shell hanko scroll")
o.bind("SUPER + SHIFT + I", "Hanko settings", "omarchy-shell hanko settings")
