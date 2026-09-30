local lockfile = vim.fn.stdpath "state" .. "/lazy-lock.json"
local seedfile = vim.fn.stdpath "state" .. "/lazy-lock.seed.json"
local pins = vim.fn.readfile(vim.fn.stdpath "config" .. "/lazy-lock.json")

if
  not vim.uv.fs_stat(lockfile)
  or not vim.uv.fs_stat(seedfile)
  or not vim.deep_equal(vim.fn.readfile(seedfile), pins)
then
  vim.fn.mkdir(vim.fn.stdpath "state", "p")
  vim.fn.writefile(pins, lockfile)
  vim.fn.writefile(pins, seedfile)
end

return {
  lockfile = lockfile,
  defaults = { lazy = true },
  install = { colorscheme = { "nvchad" } },

  ui = {
    icons = {
      ft = "",
      lazy = "󰂠 ",
      loaded = "",
      not_loaded = "",
    },
  },

  performance = {
    rtp = {
      disabled_plugins = {
        "2html_plugin",
        "tohtml",
        "getscript",
        "getscriptPlugin",
        "gzip",
        "logipat",
        "netrw",
        "netrwPlugin",
        "netrwSettings",
        "netrwFileHandlers",
        "matchit",
        "tar",
        "tarPlugin",
        "rrhelper",
        "spellfile_plugin",
        "vimball",
        "vimballPlugin",
        "zip",
        "zipPlugin",
        "tutor",
        "rplugin",
        "syntax",
        "synmenu",
        "optwin",
        "compiler",
        "bugreport",
        "ftplugin",
      },
    },
  },
}
