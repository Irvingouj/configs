local function extend_unique(target, values)
  target = target or {}
  for _, value in ipairs(values) do
    if not vim.tbl_contains(target, value) then
      table.insert(target, value)
    end
  end
  return target
end

local function angular_probe_path()
  local output = vim.fn.systemlist("npm root -g")
  if vim.v.shell_error == 0 and output[1] and output[1] ~= "" then
    return output[1]
  end
  return nil
end

return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        angularls = {
          cmd = (function()
            local probe = angular_probe_path()
            if probe then
              return {
                "ngserver",
                "--stdio",
                "--tsProbeLocations",
                probe,
                "--ngProbeLocations",
                probe,
              }
            end
            return { "ngserver", "--stdio" }
          end)(),
          root_dir = function(fname)
            local util = require("lspconfig.util")
            return util.root_pattern("angular.json", "project.json", "nx.json", "package.json", ".git")(fname)
          end,
        },
      },
    },
  },
  -- Roslyn LSP for C# (same engine as VS Code)
  {
    "mason-org/mason.nvim",
    opts = {
      registries = {
        "github:mason-org/mason-registry",
        "github:Crashdummyy/mason-registry",
      },
    },
  },
  {
    "seblyng/roslyn.nvim",
    ft = "cs",
    ---@module 'roslyn.config'
    ---@type RoslynNvimConfig
    opts = {},
  },
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      opts.ensure_installed = extend_unique(opts.ensure_installed, {
        "c_sharp",
        "css",
        "html",
        "javascript",
        "json",
        "jsonc",
        "rust",
        "scss",
        "tsx",
        "typescript",
      })
    end,
  },
}
