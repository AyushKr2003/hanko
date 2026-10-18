-- hanko: ink border on the focused sheet, a faint hairline on the rest.
local active_border_color = "rgb(ddd5c7)"
local inactive_border_color = "rgba(ddd5c738)"

hl.config({
  general = {
    col = {
      active_border = active_border_color,
      inactive_border = inactive_border_color,
    },
  },

  group = {
    col = {
      border_active = active_border_color,
      border_inactive = inactive_border_color,
    },
  },
})
