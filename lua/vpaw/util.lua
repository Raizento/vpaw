local M = {}

--- Try to get the plugin name from a given url
---@param url string
---@return string url
function M.get_main_module_from_url(url)
  -- https://github.com/nvim-telescope/telescope.nvim -> telescope.nvim
  local last_part = string.match(url, "([^/]+)/*$")

  -- telescope.nvim -> telescope
  local base = string.match(last_part, "([^%.]+)")
  return string.lower(base)
end

function M.get_plugin_name_from_url(url)
  -- https://github.com/nvim-telescope/telescope.nvim -> telescope.nvim
  return string.match(url, "([^/]+)/*$")
end

---Get default setup for plugins which don't have a setup function configured
---@param plugin_name string
---@param opts table
---@return function
function M.default_setup(plugin_name, opts)
  return function()
    local success, module = pcall(function()
      return require(plugin_name)
    end)

    -- Some plugins (like friendly snippets) aren't lua and will error when trying to require them
    -- If they are not lua, exit early since we also cannot set them up
    if not success then
      return
    end

    -- Plugins like e.g. plenary might "shadow" their setup index
    -- using a metatable; use rawget to get the actual function
    local setup = rawget(module, "setup")

    -- Need to make sure that setup it actually a function
    -- E.g. JDTLS' setup entry is a table
    if setup ~= nil and type(setup) == "function" then
      setup(opts)
    end
  end
end

---@param event "PackChanged" | "PackChangedPre"
---@param kind "install" | "update" | "delete"
---@param name string
---@param hook function
function M.setup_hook(event, kind, name, hook)
  local id = vim.api.nvim_create_augroup("raizento." .. event .. ".hooks", { clear = false })
  vim.api.nvim_create_autocmd({
    event,
  }, {
    group = id,
    callback = function(ev)
      local _name, _kind = ev.data.spec.name, ev.data.kind

      if _name == name and _kind == kind then
        if not ev.data.active then
          vim.cmd.packadd(name)
        end
        hook()
      end
    end,
  })
end

return M
