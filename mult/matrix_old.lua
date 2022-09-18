local matrix = {}

local min, max = math.min, math.max
local sin, sqrt = math.sin, math.sqrt
local random = math.random

-- Easy Access Matrix Properties
local props = {}
matrix.props = props

-- List of Matrix operations
local opers = {}
matrix.opers = opers

-- Metatables
matrix.mt = {}

local matrix_class_mt = {}
local matrix_mt = matrix.mt

matrix_mt.__name = "matrix"

matrix_mt.__index = function(t, k)
  if type(k) == "table" then
    return t.numberList[t.size[2]*(k[1] - 1) + k[2]]
  elseif type(k) == "number" then
    return matrix.getRow(t, k)
  elseif props[k] then
    return props[k](t)
  elseif matrix[k] then
    return matrix[k]
  end
end

matrix_mt.__newindex = function(t, k, v)
  if type(k) == "table" then
    if k[1] > t.size[1] or k[2] > t.size[2] then
      --RESHAPE
    end
    t.numberList[t.size[2]*(k[1] - 1) + k[2]] = v
  end
end

matrix_mt.__len = function(t)
  return matrix.length(t)
end

matrix_mt.__unm = function(t)
  return matrix.scale(t, -1)
end

matrix_mt.__tostring = function(t)
  return matrix.string(t)
end

matrix_mt.__eq = function(t1, t2)
  return matrix.isEqual(t1, t2)
end

matrix_mt.__lt = function(t1, t2)
  return matrix.isLessThan(t1, t2)
end

matrix_mt.__le = function(t1, t2)
  return matrix.isLessEqualThan(t1, t2)
end

matrix_class_mt.__call = function(t, ...)
  return matrix.new(...)
end

setmetatable(matrix, matrix_class_mt)


function matrix.new(...)
  local m = {}

  local x = {...}
  if type(x[1]) == "nil" then
    x[1] = {}
    x[1][1] = {}
  elseif type(x[1][1]) == "table" then
    x = x[1]
  end

  local a, b = #x, #(x[1])
  m.size = {a, b}
  m.numberList = {}

  for i = 1, a do
    for j = 1, b do
      table.insert(m.numberList, x[i][j])
    end
  end


  setmetatable(m, matrix_mt)
  return m
end


function matrix.zeros(i, j)
  local m = matrix()

  if type(i) == "table" then
    i, j = i[1], i[2]
  end

  for k = 1, i*j do
    m.numberList[k] = 0
  end

  m.size = {i, j}

  return m
end

function matrix.diag(v)
  if type(v) == "vector" then
    local n = #v
    local out = matrix.zeros(n, n)
    for i = 1, n do
      out.numberList[1 + (n + 1)*(i - 1)] = v.numberList[i]
    end
    return out
  end
end

function matrix.get(m, ai, af, ei, ef)
  if type(ai) == "table" then
    ai, af, ei, ef = ai[1], ai[2], af[1], af[2]
  end

  local out = matrix.zeros(af - ai + 1, ef - ei + 1)

  for i = ai, af do
    for j = ei, ef do
      out[{i - ai + 1, j - ei + 1}] = m[{i, j}]
    end
  end

  return out
end

function matrix.getRow(m, i)
  local n = m.size[2]
  local out = vector.zeros(n)

  for p = 1, n do
    out[p] = m[{i, p}]
  end

  return out
end

function matrix.getCol(m, j)
  local n = m.size[1]
  local out = vector.zeros(n)

  for q = 1, n do
    out[q] = m[{q, j}]
  end

  return out
end

function matrix.setRow(m, i, v)
  local n = m.size[2]
  local out = matrix.clone(m)

  for p = 1, n do
    out[{i, p}] = v.numberList[p]
  end

  return out
end

function matrix.setCol(m, j, v)
  local n = m.size[2]
  local out = table.clone(m)

  for q = 1, n do
    out[{q, j}] = v.numberList[q]
  end

  return out
end

function matrix.clone(m)
  local out = matrix.zeros(m.size)
  out.numberList = m.numberList
  return out
end

--------------------------------------------------
----------      OPERATIONS     -------------------
--------------------------------------------------
function opers.plus(m1, m2)
  local out = matrix.zeros(m1.size)

  for i = 1, #m1 do
    out.numberList[i] = m1.numberList[i] + m2.numberList[i]
  end

  return out
end

function opers.plus_scalar(m, n)
  local out = matrix.zeros(m.size)

  for i = 1, #m do
    out.numberList[i] = m.numberList[i] + n
  end

  return out
end

function opers.minus(m1, m2)
  local out = matrix.zeros(m1.size)

  for i = 1, #m1 do
    out.numberList[i] = m1.numberList[i] - m2.numberList[i]
  end

  return out
end

function opers.minus_scalar(m, n)
  local out = matrix.zeros(m.size)

  for i = 1, #m do
    out.numberList[i] = m.numberList[i] - n
  end

  return out
end

function opers.scale(m, n)
  local out = matrix.zeros(m.size)

  for i = 1, #m do
    out.numberList[i] = m.numberList[i]*n
  end

  return out
end

function opers.times(m1, m2)
  local out = matrix.zeros(m1.size)

  for i = 1, #m1 do
    out.numberList[i] = m1.numberList[i]*m2.numberList[i]
  end

  return out
end

function opers.mult_vector(m, v)
  local n = vector.length(v)
  local out = vector.zeros(n)

  for i = 1, n do
    out.numberList[i] = vector.dot(v.numberList, matrix.getRow(m, i))
  end

  return out
end

function opers.mult(m1, m2)
  local p, q = m1.size[1], m2.size[2]
  local out = matrix.zeros(p, q)

  for i = 1, p do
    for j = 1, q do
      out[{i, j}] = vector.dot(matrix.getRow(m1, i), matrix.getCol(m2, j))
    end
  end

  return out
end

function opers.power(m1, m2)
  local out = matrix.zeros(m1.size)

  for i = 1, #m1 do
    out.numberList[i] = m1.numberList[i]^m2.numberList[i]
  end

  return out
end

function opers.power_scalar(m, n)
  local out = matrix.zeros(m.size)
  for i = 1, #m do
    out.numberList[i] = m.numberList[i]^n
  end
  return out
end

function opers.concat(m1, m2)

end

function opers.isEqual(m1, m2)
  if matrix.length(m1) ~= matrix.length(m2) then
    return false
  end

  for i = 1, matrix.length(m1) do
    if m1.numberList[i] ~= m2.numberList[i] then
      return false
    end
  end

  return true
end

function opers.isLessThan(m1, m2)
  if matrix.length(m1) ~= matrix.length(m2) then
    return false
  end

  for i = 1, matrix.length(m1) do
    if m1.numberList[i] >= m2.numberList[i] then
      return false
    end
  end

  return true
end

function opers.isLessEqualThan(m1, m2)
  if matrix.length(m1) ~= matrix.length(m2) then
    return false
  end

  for i = 1, matrix.length(m1) do
    if m1.numberList[i] > m2.numberList[i] then
      return false
    end
  end

  return true
end


--------------------------------------------------
----------      PROPERTIES     -------------------
--------------------------------------------------
function props.length(m)
  return m.size[1]*m.size[2]
end

function props.string(m)
  local s = "{"

  if #m ~= 0 then
    for i = 1, #m do
      if i % m.size[2] == 1 then
        s = s.."\n  ["
      end

      s = s..tostring(m.numberList[i])

      if i % m.size[2] ~= 0 then
        s = s..", "
      else
        s = s.."]"
      end
    end
  end

  s = s.."\n}"
  return s
end

function props.T(m)
  local p, q = m.size[1], m.size[2]
  local out = matrix.zeros(q, p)

  for i = 1, p do
    for j = 1, q do
      out[{j, i}] = m[{i, j}]
    end
  end

  return out
end

function props.ef(m)

end

function props.rref(m)
  local p, q = m.size[1], m.size[2]
  local out = matrix.clone(m)

  -- for i = 

  return out
end

function matrix.determinant(m)
  if m.size[1] == 1 then
    return m.numberList[1]
  elseif m.size[1] == 2 then
    return m.numberList[1]*m.numberList[4] - m.numberList[2]*m.numberList[3]
  elseif m.size[1] == 3 then
    local a, b, c = m.numberList[1], m.numberList[2], m.numberList[3]
    local d, e, f = m.numberList[4], m.numberList[5], m.numberList[6]
    local g, h, i = m.numberList[7], m.numberList[8], m.numberList[9]
    return a*e*i + b*f*g + c*d*h - c*e*g - b*d*i - a*f*h
  else
    --AAAAAAA
  end
end

function matrix.adjugate(m)
  if m.size[1] == 1 then
    return matrix({{1}})
  elseif m.size[1] == 2 then
    return matrix({m.numberList[4], -m.numberList[2]}, {-m.numberList[3], m.numberList[1]})
  elseif m.size[1] == 3 then
    local a, b, c = m.numberList[1], m.numberList[2], m.numberList[3]
    local d, e, f = m.numberList[4], m.numberList[5], m.numberList[6]
    local g, h, i = m.numberList[7], m.numberList[8], m.numberList[9]

    local r, s, t = matrix({e, f}, {h, i}), matrix({}, {}), matrix({}, {})
    local u, v, w = matrix({}, {}), matrix({}, {}), matrix({}, {})
    local x, y, z = matrix({}, {}), matrix({}, {}), matrix({}, {})

    r, s, t = matrix.determinant(r), matrix.determinant(s), matrix.determinant(t)
    u, v, w = matrix.determinant(u), matrix.determinant(v), matrix.determinant(w)
    x, y, z = matrix.determinant(x), matrix.determinant(y), matrix.determinant(z)

    return matrix({r, -s, t}, {-u, v, -w}, {x, -y, z})
  else
    --AAAAAAA
  end
end

function matrix.reciprocal(m)
  return 1/matrix.determinant(m)*matrix.adjugate(m)
end



for k, v in pairs(opers) do
  matrix[k] = v
end

for k, v in pairs(props) do
  matrix[k] = v
end

-- Export Matrix class
_G.matrix = matrix
