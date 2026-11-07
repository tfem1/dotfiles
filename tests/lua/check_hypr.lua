-- Loads hypr/hyprland.lua with a fake `hl` API that records every call, then
-- prints one JSON object per call so tests/test_hypr.py can check the config.
-- Usage: lua5.4 tests/lua/check_hypr.lua <repo>/hypr

local root = assert(arg[1], "usage: check_hypr.lua <hypr dir>")
package.path = root .. "/?.lua;" .. package.path

-- Generated modules do not exist in the repository: stand-ins.
package.preload["theme"] = function() return true end
package.preload["shell"] = function() shellName = "desktop"; return true end

local calls = {}

local function encode(value)
  local kind = type(value)
  if kind == "string" then
    return '"' .. value:gsub('[%c"\\]', function(c) return string.format("\\u%04x", c:byte()) end) .. '"'
  elseif kind == "number" or kind == "boolean" then
    return tostring(value)
  elseif kind == "table" then
    local parts = {}
    if #value > 0 then
      -- Lists keep their order: argument positions matter.
      for _, v in ipairs(value) do parts[#parts + 1] = encode(v) end
      return "[" .. table.concat(parts, ",") .. "]"
    end
    for k, v in pairs(value) do parts[#parts + 1] = encode(tostring(k)) .. ":" .. encode(v) end
    table.sort(parts)
    return "{" .. table.concat(parts, ",") .. "}"
  elseif kind == "function" then
    return '"<function>"'
  end
  return "null"
end

-- hl.dsp.<path>(args) returns a description of the dispatcher it stands for.
local function dispatcher(path)
  return setmetatable({}, {
    __index = function(_, key) return dispatcher(path .. "." .. key) end,
    __call = function(_, args) return { dispatcher = path, args = args } end,
  })
end

hl = setmetatable({ dsp = dispatcher("dsp") }, {
  __index = function(_, name)
    return function(...)
      local args = { ... }
      calls[#calls + 1] = { call = name, args = args }
      if name == "on" and type(args[2]) == "function" then args[2]() end
    end
  end,
})

dofile(root .. "/hyprland.lua")

for _, entry in ipairs(calls) do
  print(encode(entry))
end
