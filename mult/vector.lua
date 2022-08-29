local vector = {}

local min, max = math.min, math.max
local sin, sqrt = math.sin, math.sqrt
local random = math.random

-- Easy Access Vector Properties
local props = {}
vector.props = props

-- List of Vector operations
local opers = {}
vector.opers = opers

-- List of Vector math-like operations
local cmath = {}
vector.cmath = cmath

-- Metatables
vector.mt = {}

local vector_class_mt = {}
local vector_mt = vector.mt

vector_mt.__name = "vector"

vector_mt.__index = function(t, k)
  if type(k) == "number" then
    return t.numberList[k]
  elseif props[k] then
    return props[k](t)
  elseif vector[k] then
    return vector[k]
  end
end

vector_mt.__newindex = function(t, k, v)
  if type(k) == "number" then
    if k > #t then
      vector.reshape(t, k)
    end
    t.numberList[k] = v
  end
end

vector_mt.__len = function(t)
  return vector.length(t)
end

vector_mt.__unm = function(t)
  return vector.scale(t, -1)
end

vector_mt.__tostring = function(t)
  return vector.string(t)
end

vector_mt.__eq = function(t1, t2)
  return vector.isEqual(t1, t2)
end

vector_mt.__lt = function(t1, t2)
  return vector.isLessThan(t1, t2)
end

vector_mt.__le = function(t1, t2)
  return vector.isLessEqualThan(t1, t2)
end

vector_class_mt.__call = function(t, ...)
  return vector.new(...)
end

setmetatable(vector, vector_class_mt)


function vector.new(...)
  local v = {}

  local x = {...}
  if type(x[1]) == "table" then
    x = x[1]
  end

  v.numberList = x
  v.column = false

  setmetatable(v, vector_mt)
  return v
end


function vector.zeros(n)
  local v = vector()
  for i = 1, n do
    v[i] = 0
  end
  return v
end

function vector.ones(n)
  local v = vector()
  for i = 1, n do
    v[i] = 1
  end
  return v
end

function vector.random(n)
  local v = vector()
  for i = 1, n do
    v[i] = random()
  end
  return v
end

function vector.concat(v1, v2)
  local v3 = vector()

  for i = 1, #v1 do
    v3[i] = v1[i]
  end
  for i = 1, #v1 do
    v3[#v3 + 1] = v2[i]
  end

  return v3
end

function vector.linspace(start, stop, n)
  n = n or 100

  local x = start
  local step = (stop - start)/(n - 1)

  local v = vector()
  for i = 1, n do
    v[#v + 1] = x
    x = x + step
  end

  return v
end


local c1 = function(stop) return function(x) return x <= stop end end
local c2 = function(stop) return function(x) return x >= stop end end

function vector.stepspace(start, stop, step)
  local step = step or 1

  local x = start
  local c
  if step > 0 then
    if start > stop then return vector() end
    c = c1(stop)
  else
    if start < stop then return vector() end
    c = c2(stop)
  end

  local v = vector()
  while c(x) do
    v[#v + 1] = x
    x = x + step
  end

  return v
end

function vector.get(v1, start, stop)
  local v2 = vector()

  for i = start, stop do
    v2[#v2 + 1] = v1[i]
  end

  return v2
end

function vector.emptyClone(v)
  local out = vector.zeros(vector.length(v))
  out.column = v.column
  return out
end

function vector.reshape(v, k)
  local list = {}
  local n = #v

  for i = 1, k do
    list[i] = (i <= n and v[i]) or 0
  end

  v.numberList = list
end

function vector.replicate(v, k)
  if k <= 1 then return v end

  for i = 2, k do
    v = vector.concat(v, v)
  end

  return v
end

function vector.shift(v, k)
  local n = vector.length(v)
  local out = vector.zeros(n)

  if k < 0 then
    for i = 1, (n + k) do
      out[i] = v.numberList[i - k]
    end
  elseif k > 0 then
    for i = 1 + k, n do
      out[i] = v.numberList[i - k]
    end
  else
    out.numberList = table.clone(v.numberList)
  end

  return out
end

function vector.shiftCirc(v, k)

end

--------------------------------------------------
----------      OPERATIONS     -------------------
--------------------------------------------------
function opers.plus(v1, v2)
  local out = vector()

  for i = 1, #v1 do
    out[i] = v1[i] + v2[i]
  end

  return out
end

function opers.plus_scalar(v, n)
  local out = vector()

  for i = 1, #v do
    out[i] = v[i] + n
  end

  return out
end

function opers.minus(v1, v2)
  local out = vector()

  for i = 1, #v1 do
    out[i] = v1[i] - v2[i]
  end

  return out
end

function opers.minus_scalar(v, n)
  local out = vector()

  for i = 1, #v do
    out[i] = v[i] - n
  end

  return out
end

function opers.scale(v, n)
  local out = vector()
  for i = 1, #v do
    out[i] = n*v[i]
  end
  return out
end

function opers.times(v1, v2)
  local out = vector()
  for i = 1, #v1 do
    out[i] = v1[i]*v2[i]
  end
  return out
end

function opers.dot(v1, v2)
  return vector.sum(vector.times(v1, v2))
end

function opers.cross(v1, v2)
  local a, b, c = v1[1], v1[2], v1[3]
  local d, e, f = v2[1], v2[2], v2[3]
  return vector.new(b*f - c*e, c*d - a*f, a*e - b*d)
end

function opers.divide(v1, v2)
  local out = vector.emptyClone(v1)
  for i = 1, #v1 do
    out[i] = v1[i]/v2[i]
  end
  return out
end

function opers.divide_scalar(v, n)
  return vector.scale(v, 1/n)
end

function opers.divideM_scalar(v, n)
  return vector.scale(vector.reciprocal(v), n)
end

function opers.power(v1, v2)
  local out = vector()
  for i = 1, #v1 do
    out[i] = v1[i]^v2[i]
  end
  return out
end

function opers.power_scalar(v1, n)
  local out = vector()
  for i = 1, #v1 do
    out[i] = v1[i]^n
  end
  return out
end

function opers.concat(v1, v2)
  local out = vector()

  local n1, n2 = vector.length(v1), vector.length(v2)
  vector.reshape(out, n1 + n2)

  for i = 1, n1 do
    out[i] = v1[i]
  end
  for i = 1, n2 do
    out[i + n1] = v2[i]
  end

  return out
end

function opers.isEqual(v1, v2)
  if vector.length(v1) ~= vector.length(v2) then
    return false
  end

  for i = 1, vector.length(v1) do
    if v1.numberList[i] ~= v2.numberList[i] then
      return false
    end
  end

  return true
end

function opers.isLessThan(v1, v2)
  if vector.length(v1) ~= vector.length(v2) then
    return false
  end

  for i = 1, vector.length(v1) do
    if v1.numberList[i] >= v2.numberList[i] then
      return false
    end
  end

  return true
end

function opers.isLessEqualThan(v1, v2)
  if vector.length(v1) ~= vector.length(v2) then
    return false
  end

  for i = 1, vector.length(v1) do
    if v1.numberList[i] > v2.numberList[i] then
      return false
    end
  end

  return true
end

--------------------------------------------------
----------      PROPERTIES     -------------------
--------------------------------------------------

function props.length(v)
  return #v.numberList
end

function props.isEmpty(v)
  return #v.numberList == 0
end

function props.string(v)
  local s = "["

  if #v ~= 0 then
    local n = #v
    for i = 1, n do
      s = s..tostring(v[i])

      if i ~= n then
        if v.column then
          s = s.."; "
        else
          s = s..", "
        end
      end
    end
  end

  s = s.."]"
  return s
end

function props.magnitude(v)
  local n = v.sum
  return sqrt(n)
end

function props.sum(v)
  local n = 0
  for i = 1, #v do
    n = n + v[i]
  end
  return n
end

function props.product(v)
  local out = v.numberList[1]
  for i = 2, vector.length(v) do
    out = out*v.numberList[i]
  end
  return out
end

function props.min(v)
  local n = v[1]
  for i = 2, #v do
    n = min(n, v[i])
  end
  return n
end

function props.max(v)
  local n = v[1]
  for i = 2, #v do
    n = max(n, v[i])
  end
  return n
end

function props.flip(v)
  local out = vector()
  for i = #v, 1, -1 do
    out[#out + 1] = v[i]
  end
  return out
end

function props.reciprocal(v)
  local out = vector.emptyClone(v)

  for i = 1, vector.length(out) do
    out.numberList[i] = 1/out.numberList[i]
  end

  return out
end

function props.transpose(v)
  local out = vector.zeros(vector.length(v))

  out.numberList = table.clone(v)
  out.column = not v.column

  return out
end



function props.matrix(v)
  local size
  local n = v.length
  if v.column then
    size = {n, 1}
  else
    size = {1, n}
  end

  local out = matrix.zeros(size)

  if v.column then
    for j = 1, n do
      out[{j, 1}] = v[j]
    end
  else
    for i = 1, n do
      out[{1, i}] = v[i]
    end
  end

  return out
end




for k, v in pairs(opers) do
  vector[k] = v
end

for k, v in pairs(props) do
  vector[k] = v
end

-- Export Vector class

_G.vector = vector
