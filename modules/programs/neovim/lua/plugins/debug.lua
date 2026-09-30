return {
  {
    "mfussenegger/nvim-dap",
    config = function()
      local dap = require "dap"
      dap.adapters.codelldb = {
        type = "server",
        port = "${port}",
        executable = {
          command = "codelldb",
          args = { "--port", "${port}" },
        },
      }
      for _, language in ipairs { "c", "cpp", "rust" } do
        dap.configurations[language] = {
          {
            name = "Launch",
            type = "codelldb",
            request = "launch",
            program = function()
              return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/", "file")
            end,
            cwd = "${workspaceFolder}",
            stopOnEntry = false,
          },
        }
      end
    end,
  },
  { "mason-org/mason.nvim", enabled = false },
  {
    "rcarriga/nvim-dap-ui",
    dependencies = { "mfussenegger/nvim-dap", "nvim-neotest/nvim-nio" },
    config = function()
      require "configs.nvim-dap-ui"
    end,
  },
}
