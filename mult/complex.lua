local complex = {}

local classConstruct = require("mult/classConstruct")

local min, max = math.min, math.max
local sqrt, atan, ln, exp, abs = math.sqrt, math.atan, math.log, math.exp, math.abs
local sin, cos = math.sin, math.cos
local sinh, cosh = math.sinh, math.cosh


-- ==============================
-- ======== Class Setup =========
-- ==============================


-- ----- Export complex Class -----

_G.complex = complex


-- ---- Auto-Generate Class -----

classConstruct.new("complex", complex)

local complex_props = complex.props
local complex_mt = complex.mt


-- ------- Class Metatable ------

local complex_class_mt = {}
setmetatable(complex, complex_class_mt)

-- Allow for complex(...) to be a shorcut for complex.new(...)
complex_class_mt.__call = function(t, ...)
  return complex.new(...)
end

-- ==============================
-- ========== The Math ==========
-- ==============================


-- ----- Conversion Formulas ----

local function convRectToPolar(x, y)
  return sqrt(x^2 + y^2), atan(y, x)
end

local function convPolarToRect(mag, ang)
  return mag*cos(ang), mag*sin(ang)
end


-- -------- Constructors --------

-- Creates a complex object from a real and imaginary component
-- complex = complex.new(red, green, blue, alpha)
function complex.new(...)
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

  setmetatable(c, complex_mt)
  return c
end

function complex.polar(mag, ang)
  local x, y = convPolarToRect(mag, ang)
  local c = complex.new(x, y)

  c._props.magnitude = mag
  c._props.angle = ang

  return c
end


----------------------------
---------- Methods ---------
----------------------------


-- ------ Operations -------


function complex.plus_complex(c1, c2)
  return complex.new(c1.real + c2.real, c1.imag + c2.imag)
end

function complex.plus_number(c, n)
  return complex.new(c.values[1] + n, c.values[2])
end

function complex.plus(c, n)
  if type(n) == 'number' then
    return complex.plus_number(c, n)
  end
  return complex.plus_complex(c, n)
end


function complex.minus_complex(c1, c2)
  return complex.new(c1.real - c2.real, c1.real - c2.real)
end

function complex.minus_number(c, n)
  return complex.new(c.real - n, c.values[2])
end

function complex.minus(c, n)
  if type(n) == 'number' then
    return complex.minus_number(c, n)
  end
  return complex.minus_complex(c, n)
end


function complex.scale(c, n)
  if c.mag == 0 then
    return complex.polar(0, c.ang)
  end
  return complex.new(c.values[1]*n, c.values[2]*n)
end

function complex.rotate(c, n)
  return complex.polar(c.mag, c.ang + n)
end

function complex.times(c1, c2)
  local a, b = c1.real, c1.imag
  local c, d = c2.real, c2.imag

  return complex.new(a*c - b*d, a*d + b*c)
end

function complex.divide(c1, c2)
  local a, b = c1.real, c1.imag
  local c, d = c2.real, c2.imag

  return complex.new(a*c + b*d, b*c - a*d)/(a^2 + b^2)
end

function complex.divide_scalar(c, n)
  return complex.new(c.real/n, c.imag/n)
end

function complex.divideM_scalar(c, n)
  return complex.new(n/c.real, n/c.imag)
end


function complex.power_scalar(c, n)
  if n < 0 then
    return complex.power_scalar(complex.reciprocal(c), -n)
  else
    local out = c

    for i = 1, (n - 1) do
      out = vector.times(out, c)
    end

    return out
  end
end

function complex.power(c1, c2)
  return complex.exp(ln(c1.magnitude)*c2 + c1.angle*c2*complex.i)
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


local function getter_imag(c)
  return c.values[2]
end

local function setter_imag(c, v)
  c.values[2] = v
  reset(c)
end

local function getter_magnitude(c)
  local mag, ang = convRectToPolar(c.real, c.imag)

  c._props.magnitude = mag
  c._props.angle = ang

  return mag
end

local function setter_magnitude(c, v)
  local angle = c.angle

  if c.magnitude == 0 then
    c.real = v*cos(angle)
    c.imag = v*sin(angle)
  else
    local x = v/c.magnitude
    c.real = x*c.real
    c.imag = x*c.imag
  end

  reset(c)

  c._props.magnitude = v
  c._props.angle = angle
end

local function getter_angle(c)
  local mag, ang = convRectToPolar(c.real, c.imag)

  c._props.magnitude = mag
  c._props.angle = ang

  return ang
end

local function setter_angle(c, v)
  local mag = c.magn
  c.real = mag*cos(v)
  c.imag = mag*sin(v)

  reset(c)

  c._props.magnitude = mag
  c._props.angle = v
end

-- ------------ Misc ------------


function complex.magnitude(c)
  return c.magnitude
end

function complex.angle(c)
  return c.angle
end

function complex.conjugate(c)
  return complex(c.real, -c.imag)
end

function complex.reciprocal(c)
  return complex.conjugate(c)/(c.real^2 + c.imag^2)
end

-- Returns a string representation of the complex number "real + imag*i"
-- complex = complex.string(complex)
function complex.string(c)
  return c.real.." + "..c.imag.."*i"
end

-- Creates a new complex identical to the one passed
-- complex = complex.clone(complex)
function complex.clone(c)
  return complex.new(c.real, c.imag)
end

function complex.sign(c)
  return complex.divideM_scalar(c, c.magnitude)
end



-- ==============================
-- ======== Props Setup =========
-- ==============================

-- ----------- _index -----------

-- When accessing the index of a complex, make it behave as if accessing the real and imaginary component
function complex_props._index.getter(t, k)
  return t.values[k]
end

function complex_props._index.setter(t, k, v)
  t.values[k] = v
  reset(t)
end

-- ---------- Register ----------

complex.registerprop{name = 'real',       type = 'read-write', getter = getter_real,      setter = setter_real}
complex.registerprop{name = 'imag',       type = 'read-write', getter = getter_imag,      setter = setter_imag}
complex.registerprop{name = 'magnitude',  type = 'read-write', getter = getter_magnitude, setter = setter_magnitude}
complex.registerprop{name = 'angle',      type = 'read-write', getter = getter_angle,     setter = setter_angle}
complex.registerprop{name = 'string',     type = 'read-only'}

complex.registerprop{name = "reciprocal", type = 'method'}
complex.registerprop{name = "conjugate",  type = 'method'}
complex.registerprop{name = "scale",      type = 'method'}
complex.registerprop{name = "rotate",     type = 'method'}
complex.registerprop{name = "clone",      type = 'method'}


-- ---------- Aliases -----------

complex.registerpropAlias("real", "r")
complex.registerpropAlias("imag", "i", "imaginary")
complex.registerpropAlias("magnitude", "mag", "m")
complex.registerpropAlias("angle", "ang", "a")

complex.registerpropAlias("conjugate", "conj")


-- ==============================
-- ======= Default Values =======
-- ==============================

complex.i = complex(0, 1)
