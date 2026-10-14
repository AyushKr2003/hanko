-- Hanko 判子: Neovim on the bar's paper (Kaze 風, Dōgu). The colourscheme is
-- the hanko.bar plugin's assets/kaze/nvim/colors/hanko.lua, which works out
-- its inks from this theme's colors.toml when it is applied. It goes on the
-- runtimepath here as well, so Omarchy's live theme switch (which re-reads
-- this file) finds it without a restart.
local dir = vim.fn.expand("~/.config/omarchy/plugins/hanko.bar/assets/kaze/nvim")
if vim.fn.isdirectory(dir) == 1 then vim.opt.rtp:prepend(dir) end

return {
  {
    name = "hanko",
    dir = dir,
    lazy = false,
    priority = 1000,
  },
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "hanko",
    },
  },
}
