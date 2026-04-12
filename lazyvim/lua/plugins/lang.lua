-- Conditional language support: only configure LSPs for installed toolchains
local function has(cmd)
  return vim.fn.executable(cmd) == 1
end

local function angular_probe_path()
  local output = vim.fn.systemlist("npm root -g")
  if vim.v.shell_error == 0 and output[1] and output[1] ~= "" then
    return output[1]
  end
  return nil
end

local plugins = {}

-- Rust: rust-analyzer via LazyVim extra
if has("cargo") then
  table.insert(plugins, { import = "lazyvim.plugins.extras.lang.rust" })
end

-- Go: gopls via LazyVim extra
if has("go") then
  table.insert(plugins, { import = "lazyvim.plugins.extras.lang.go" })
end

-- TypeScript / JavaScript + Angular LSP
if has("node") then
  table.insert(plugins, { import = "lazyvim.plugins.extras.lang.typescript" })

  table.insert(plugins, {
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
  })
end

-- C# / .NET: Roslyn LSP
if has("dotnet") then
  table.insert(plugins, {
    "mason-org/mason.nvim",
    opts = {
      registries = {
        "github:mason-org/mason-registry",
        "github:Crashdummyy/mason-registry",
      },
    },
  })
  table.insert(plugins, {
    "seblyng/roslyn.nvim",
    ft = "cs",
    ---@module 'roslyn.config'
    ---@type RoslynNvimConfig
    opts = {},
  })
end

-- Treesitter: install parsers matching detected toolchains
table.insert(plugins, {
  "nvim-treesitter/nvim-treesitter",
  opts = function(_, opts)
    local parsers = {}
    local toolchain_parsers = {
      cargo = { "rust" },
      go = { "go", "gomod", "gosum" },
      node = { "javascript", "typescript", "tsx", "html", "css", "scss", "json", "jsonc" },
      dotnet = { "c_sharp" },
    }
    for cmd, langs in pairs(toolchain_parsers) do
      if has(cmd) then
        vim.list_extend(parsers, langs)
      end
    end
    opts.ensure_installed = opts.ensure_installed or {}
    for _, p in ipairs(parsers) do
      if not vim.tbl_contains(opts.ensure_installed, p) then
        table.insert(opts.ensure_installed, p)
      end
    end
  end,
})

return plugins
