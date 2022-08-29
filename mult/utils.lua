local utils = {}

local min, max = math.min, math.max
function math.clamp(mi, ma, v)
  return max(mi, min(ma, v))
end

local raw_print = print
function print(...)
  local x = {...}
  for _, v in ipairs(x) do
    raw_print(v)
  end
end


local ticList = {}
local ticQuery = {}
local ticID = 1

function utils.tic()
  local t = {
    x = os.clock(),
    id = ticID
  }

  ticList[ticID] = t
  table.insert(ticQuery, ticID)

  ticID = ticID + 1

  return t.id
end

function utils.toc(id)
  local t
  if id then
    for k, v in ipairs(ticQuery) do
      if v == id then
        t = ticList[v]
      end
    end
  else
    t = ticList[ticQuery[#ticQuery]]
    table.remove(ticQuery, #ticQuery)
  end

  local x = (t.x - os.clock())
  print("Elapsed Time: "..(os.clock() - t.x).."s")

  return x
end

_G.utils = utils
