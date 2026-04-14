local util = require("vpaw.util")

---@class vpaw.Plugin
---@field spec vpaw.PluginSpec
---@field has_dependencies boolean
---@field plugin_name string
local Plugin = {}
Plugin.__index = Plugin

---@param spec vpaw.PluginSpec
function Plugin:new(spec)
  vim.validate("spec", spec, "table", "Spec cannot be empty")

  local url = spec.url or ""
  if url == "" then
    error("Plugin URL cannot be empty!", 2)
  end

  local name = spec.name or util.get_main_module_from_url(spec.url)

  local dependencies = spec.dependencies or {}
  local has_dependencies = #dependencies ~= 0

  local opts = spec.opts or {}
  local keys = spec.keys or {}
  local setup = spec.setup or util.default_setup(name, opts)
  local hooks = spec.hooks or {}

  ---@type vpaw.PluginSpec
  local plugin_spec = {
    url = url,
    name = name,
    opts = opts,
    dependencies = dependencies,
    keys = keys,
    setup = setup,
    hooks = hooks,
  }

  local plugin = {
    spec = plugin_spec,
    plugin_name = util.get_plugin_name_from_url(url),
    has_dependencies = has_dependencies,
  }

  setmetatable(plugin, self)
  self.__index = Plugin

  return plugin
end

function Plugin:setup_hooks()
  local pre = self.spec.hooks.pre or {}
  for hook_kind, hooks in pairs(pre) do
    for _, hook in pairs(hooks) do
      util.setup_hook("PackChangedPre", hook_kind, self.spec.name, hook)
    end
  end

  local after = self.spec.hooks.after or {}
  for hook_kind, hooks in pairs(after) do
    for _, hook in pairs(hooks) do
      util.setup_hook("PackChanged", hook_kind, self.spec.name, hook)
    end
  end
end

function Plugin:enable()
  self.spec.setup()

  local keys = self.spec.keys or {}
  for _, mapping in pairs(keys) do
    ---@diagnostic disable-next-line: param-type-mismatch
    vim.keymap.set(unpack(mapping))
  end
end

return Plugin
