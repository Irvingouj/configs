-- Copilot: loads only when GitHub Copilot auth is detected on this machine
local function copilot_authenticated()
  local paths = {
    vim.fn.expand("$LOCALAPPDATA/github-copilot/hosts.json"),
    vim.fn.expand("$LOCALAPPDATA/github-copilot/apps.json"),
    vim.fn.expand("~/.config/github-copilot/hosts.json"),
    vim.fn.expand("~/.config/github-copilot/apps.json"),
  }
  for _, path in ipairs(paths) do
    if (vim.uv or vim.loop).fs_stat(path) then
      return true
    end
  end
  return false
end

if not copilot_authenticated() then
  return {}
end

return {
  { import = "lazyvim.plugins.extras.ai.copilot" },
}
