local path = vim.env.PATH
require "nvchad.options"
vim.env.PATH = path

local o = vim.o

o.scrolloff = 4
o.expandtab = true
o.shiftwidth = 2
o.tabstop = 2
o.softtabstop = 2
o.relativenumber = true
o.whichwrap = ""
o.mouse = ""
