local matrix = {}

local classConstruct = require("mult/classConstruct")

local min, max = math.min, math.max
local sqrt, atan, ln, exp, abs = math.sqrt, math.atan, math.log, math.exp, math.abs
local sin, cos = math.sin, math.cos
local sinh, cosh = math.sinh, math.cosh


-- ==============================
-- ======== Class Setup =========
-- ==============================


-- ----- Export Matrix Class -----

_G.matrix = matrix
_G.vector = matrix

-- ---- Auto-Generate Class -----

classConstruct.new("matrix", matrix)

local matrix_props = matrix.props
local matrix_mt = matrix.mt


-- ------- Class Metatable ------

local matrix_class_mt = {}
setmetatable(matrix, matrix_class_mt)

-- Allow for matrix(...) to be a shorcut for matrix.new(...)
matrix_class_mt.__call = function(t, ...)
  return matrix.new(...)
end

-- ==============================
-- ========== The Math ==========
-- ==============================


-- ----- Conversion Formulas ----

local function tableToMatrix(t)
  local x = t
  return matrix(x)
end

local function convRectToPolar(x, y)
  return sqrt(x^2 + y^2), atan(y, x)
end


-- -------- Constructors --------

-- Creates a matrix object from a real and imaginary component
-- matrix = matrix.new(red, green, blue, alpha)
function matrix.new(...)
  local c = {}

  local v = {...}
  if type(v[1]) == "table" then
    v = v[1]
  end

  v[1] = v[1] or 0
  v[2] = v[2] or 0  -- Default components to 0 if left blank

  c.values = v
  c._props = {}

  c._props.real = v[1]
  c._props.imag = v[2]

  setmetatable(c, matrix_mt)
  return c
end


----------------------------
---------- Methods ---------
----------------------------


-- ------ Operations -------


function matrix.plus_matrix(c1, c2)
  return matrix.new(c1.real + c2.real, c1.imag + c2.imag)
end

function matrix.plus_number(c, n)
  return matrix.new(c.values[1] + n, c.values[2])
end

function matrix.plus(c, n)
  if type(n) == 'number' then
    return matrix.plus_number(c, n)
  end
  return matrix.plus_matrix(c, n)
end


function matrix.minus_matrix(c1, c2)
  return matrix.new(c1.real - c2.real, c1.real - c2.real)
end

function matrix.minus_number(c, n)
  return matrix.new(c.real - n, c.values[2])
end

function matrix.minus(c, n)
  if type(n) == 'number' then
    return matrix.minus_number(c, n)
  end
  return matrix.minus_matrix(c, n)
end


function matrix.scale(c, n)
  if c.mag == 0 then
    return matrix.polar(0, c.ang)
  end
  return matrix.new(c.values[1]*n, c.values[2]*n)
end

function matrix.rotate(c, n)
  return matrix.polar(c.mag, c.ang + n)
end

function matrix.times(c1, c2)
  local a, b = c1.real, c1.imag
  local c, d = c2.real, c2.imag

  return matrix.new(a*c - b*d, a*d + b*c)
end

function matrix.divide(c1, c2)
  local a, b = c1.real, c1.imag
  local c, d = c2.real, c2.imag

  return matrix.new(a*c + b*d, b*c - a*d)/(a^2 + b^2)
end

function matrix.divide_scalar(c, n)
  return matrix.new(c.real/n, c.imag/n)
end

function matrix.divideM_scalar(c, n)
  return matrix.new(n/c.real, n/c.imag)
end


function matrix.power_scalar(c, n)
  if n < 0 then
    return matrix.power_scalar(matrix.reciprocal(c), -n)
  else
    local out = c

    for i = 1, (n - 1) do
      out = vector.times(out, c)
    end

    return out
  end
end

function matrix.power(c1, c2)
  return matrix.exp(ln(c1.magnitude)*c2 + c1.angle*c2*matrix.i)
end




-- ------- Getter/Setters -------

local function reset(t)
  t._props = {}
end

local function getter_real(c)
  return c.values[1]
end

local function setter_real(c, v)
  c.values[1] = v
  reset(c)
end



-- ------------ Misc ------------


function matrix.magnitude(c)
  return c.magnitude
end

function matrix.angle(c)
  return c.angle
end




-- ==============================
-- ======== Props Setup =========
-- ==============================

-- ----------- _index -----------

-- When accessing the index of a matrix, make it behave as if accessing the real and imaginary component
function matrix_props._index.getter(t, k)
  return t.values[k]
end

function matrix_props._index.setter(t, k, v)
  t.values[k] = v
  reset(t)
end

-- ---------- Register ----------

matrix.registerprop{name = 'real',       type = 'read-write', getter = getter_real,      setter = setter_real}
matrix.registerprop{name = 'string',     type = 'read-only'}

matrix.registerprop{name = "clone",      type = 'method'}


-- ---------- Aliases -----------

matrix.registerpropAlias("real", "r")


-- ==============================
-- ======= Default Values =======
-- ==============================

-- ------ Common Directions ------

-- matrix.right2d = matrix({0, 1})
-- matrix.left2d  = matrix({-1, 0})
-- matrix.up2d    = matrix({0, 1})
-- matrix.down2d  = matrix({0, -1})

-- matrix.right3d  = matrix({0, 1, 0})
-- matrix.left3d   = matrix({-1, 0, 0})
-- matrix.up3d     = matrix({0, 1, 0})
-- matrix.down3d   = matrix({0, -1, 0})
-- matrix.foward3d = matrix({0, 0, 1})
-- matrix.back3d   = matrix({0, 0, -1})

-- -- Aliases
-- matrix.right  = matrix.right3d
-- matrix.left   = matrix.left3d
-- matrix.up     = matrix.up3d
-- matrix.down   = matrix.down3d
-- matrix.foward = matrix.foward3d
-- matrix.back   = matrix.back3d

-- -- ------ Identity Matrixes ------

-- matrix.I2d = matrix.diag{1, 1}
-- matrix.I3d = matrix.diag{1, 1, 1}
-- matrix.I4d = matrix.diag{1, 1, 1, 1}

-- -- Aliases
-- matrix.I = matrixI3d