local insert = table.insert

function table.clone(org)
  return {table.unpack(org)}
end

function table.keys(t)
  local keys = {}

  for k in pairs(t) do
    insert(keys, k)
  end

  return keys
end

function table.string(t)
  local s = "{\n"

  for k, v in pairs(t) do
      s = s.."  ["..tostring(k).."] = "..tostring(v).."\n"
  end

  s = s.."}"
  return s
end

function table.map(t)
  local out = {}
  for k, v in pairs(t) do
    out[v] = k
  end
  return out
end

local tostring_raw = tostring
function tostring(t)
  if type(t) == "table" then
    return table.string(t)
  end
  return tostring_raw(t)
end
