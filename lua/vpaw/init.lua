local Plugin = require("vpaw.plugin")
local topological_sort = require("vpaw.topological_sort")

---@class vpaw
---@field install function Moin
local M = {}

---@param specs table<vpaw.PluginSpec>
function M.install(specs)
  local plugins = vim
    .iter(specs)
    :map(function(spec)
      return Plugin:new(spec)
    end)
    :totable()
  local order = topological_sort.topological_order(plugins)

  -- Set up hooks before first call to vim.pack.add. Autocommands won't work if
  -- not added before first call to vim.pack.add when installing from lockfile;
  -- see :h vim.pack-events
  ---@param plugin Plugin
  vim.iter(order):each(function(plugin)
    plugin:setup_hooks()
  end)

  -- Adding all plugins at once is the approach vim.pack.add is designed around; see
  -- https://echasnovski.com/blog/2026-03-13-a-guide-to-vim-pack.html#single-vim-pack-add
  local plugin_urls = vim
    .iter(order)
    :map(function(plugin)
      return plugin.url
    end)
    :totable()
  vim.pack.add(plugin_urls)

  vim.iter(order):each(function(plugin)
    plugin:enable()
  end)
end

return M
