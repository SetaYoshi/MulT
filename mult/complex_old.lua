local complex = {}

local min, max = math.min, math.max
local sqrt, atan2, ln, exp, abs = math.sqrt, math.atan2, math.log, math.exp, math.abs
local sin, cos = math.sin, math.cos
local sinh, cosh = math.sinh, math.cosh

-- Easy Access Complex Properties
local props = {}
complex.props = props

-- List of Complex operations
local opers = {}
complex.opers = opers

-- Metatables
complex.mt = {}

local complex_class_mt = {}
local complex_mt = complex.mt

complex_mt.__name = "complex"

complex_mt.__index = function(t, k)
  if type(k) == "number" then
    return t.numberList[k]
  elseif props[k] then
    return props[k](t)
  elseif complex[k] then
    return complex[k]
  end
end

complex_mt.__newindex = function(t, k, v)
  if k == "real" then
    t.numberList[1] = v
  elseif k == "imag" then
    t.numberList[2] = v
  end
end

complex_mt.__len = function(t)
  return complex.magnitude(t)
end

complex_mt.__unm = function(t1)
  return complex.scale(t1, -1)
end

complex_mt.__tostring = function(t)
  return complex.string(t)
end

complex_class_mt.__call = function(t, ...)
  return complex.new(...)
end

setmetatable(complex, complex_class_mt)


function complex.new(...)
  local c = {}

  local v = {...}
  if type(v[1]) == "table" then
    v = v[1]
  end

  c.numberList = {v[1], v[2]}

  setmetatable(c, complex_mt)
  return c
end

complex.i = complex(0, 1)

function complex.exp(c)
  local b = c.imag
  return exp(c.real)*complex(cos(b), sin(b))
end

function complex.sin(c)
  local a, b = c.real, c.imag
  return complex(sin(a)*cosh(b), cos(a)*sinh(b))
end

function complex.cos(c)
  local a, b = c.real, c.imag
  return complex(cos(a)*cosh(b), -sin(a)*sinh(b))
end

function complex.sqrt(c)
  local m = complex.magnitude(c)

  local a = c + m
  return sqrt(m)*a/complex.magnitude(a)
end

--------------------------------------------------
----------      OPERATIONS     -------------------
--------------------------------------------------
function opers.plus(c1, c2)
  return complex(c1.numberList[1] + c2.numberList[1], c1.numberList[2] + c2.numberList[2])
end

function opers.plus_number(c, n)
  return complex(c.numberList[1] + n, c.numberList[2])
end


function opers.minus(c1, c2)
  return complex(c1.numberList[1] - c2.numberList[1], c1.numberList[2] - c2.numberList[2])
end

function opers.minus_number(c, n)
  return complex(c.numberList[1] - n, c.numberList[2])
end

function opers.scale(c, n)
  return complex(c.numberList[1]*n, c.numberList[2]*n)
end

function opers.times(c1, c2)
  local a, b = c1.real, c1.imag
  local c, d = c2.real, c2.imag

  return complex(a*c - b*d, a*d + b*c)
end

function opers.divide(c1, c2)
  local a, b = c1.real, c1.imag
  local c, d = c2.real, c2.imag

  return complex(a*c + b*d, b*c - a*d)/(a^2 + b^2)
end

function opers.divide_scalar(c, n)
  return complex(c.real/n, c.imag/n)
end

function opers.divideM_scalar(c, n)
  return complex(n/c.real, n/c.imag)
end


function opers.power_scalar(c, n)
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

function opers.power(c1, c2)
  return complex.exp(ln(complex.magnitude(c1))*c2 + complex.i*complex.angle(c1)*c2)
end

--------------------------------------------------
----------      PROPERTIES     -------------------
--------------------------------------------------


function props.string(c)
  return c.numberList[1].." + "..c.numberList[2].."i"
end


function props.real(c)
  return c.numberList[1]
end

function props.imag(c)
  return c.numberList[2]
end

function props.conjugate(c)
  return complex(c.real, -c.imag)
end

function props.magnitude(c)
  return sqrt(c.real^2 + c.imag^2)
end

function props.reciprocal(c)
  return complex.conjugate(c)/(c.real^2 + c.imag^2)
end

function props.angle(c)
  return atan2(c.imag, c.real)
end



for k, v in pairs(opers) do
  complex[k] = v
end

for k, v in pairs(props) do
  complex[k] = v
end

local sqrt_raw = math.sqrt
function math.sqrt(x)
  if x < 0 then
    return complex(0, sqrt_raw(x))
  else
    return sqrt_raw(x)
  end
end


-- Export Complex class
_G.complex = complex
math.i = complex.i
