local color = {}

local classConstruct = require("classConstruct")

local floor, abs = math.floor, math.abs
local max, min = math.max, math.min


local min, max = math.min, math.max
function math.clamp(mi, ma, v)
  return max(mi, min(ma, v))
end
function math.lerp(x1, x2, n)
  return x1 + n*(x2 - x1)
end

local clamp = math.clamp
local lerp = math.lerp


-- ==============================
-- ======== Class Setup =========
-- ==============================


-- ----- Export Color Class -----

_G.color = color


-- ---- Auto-Generate Class -----

classConstruct.new("color", color)

local color_props = color.props
local color_mt = color.mt


-- ------- Class Metatable ------

local color_class_mt = {}
setmetatable(color, color_class_mt)

-- Allow for color(...) to be a shorcut for color.rgba(...)
color_class_mt.__call = function(t, ...)
  return color.rgba(...)
end

-- ==============================
-- ========== The Math ==========
-- ==============================


-- ----- Conversion Formulas ----

-- Converts a hue (0 - 360°), saturation (0 - 1), value (0 - 1) to a red, green, blue (0 - 1)
-- red, green, blue = convHsvToRgb(hue, saturation, value)
local function convHsvToRgb(h, s, v)
  local r, g, b

  local c = v*s
  local x = c*(1 - abs(h/60 % 2 - 1))
  local m = v - c

  if       0 <= h and h < 60  then r, g, b = c, x, 0
  elseif  60 <= h and h < 120 then r, g, b = x, c, 0
  elseif 120 <= h and h < 180 then r, g, b = 0, c, x
  elseif 180 <= h and h < 240 then r, g, b = 0, x, c
  elseif 240 <= h and h < 300 then r, g, b = x, 0, c
  elseif 300 <= h and h < 360 then r, g, b = c, 0, x
  end

  return (r + m)*255, (g + m)*255, (b + m)*255
end

-- Converts a red, green, blue (0 - 1) to a hue (0 - 360°), saturation (0 - 1), value (0 - 1)
-- red, green, blue = convHsvToRgb(hue, saturation, value)
local function convRgbToHsv(r, g, b)
  local h, s, v

  local cmax = max(r, g, b)
  local cmin = min(r, g, b)
  local delta = cmax - cmin

  if delta == 0 then
    h = 0
  elseif cmax == r then
    h = (g - b)/delta % 6
  elseif cmax == g then
    h = (b - r)/delta + 2
  else
    h = (r - g)/delta + 4
  end

  if cmax == 0 then
    s = 0
  else
    s = delta/cmax
  end

  v = cmax

  return h*60, s, v
end

local v256_map = {256^0, 256^1, 256^2, 256^3, 256^4}

-- Converts a red, green, blue, alpha (0 - 1) to a hex value
-- hex = convRgbaToHex(red, green, blue)
local function convRgbaToHex(r, g, b, a)
  return r*v256_map[4] + g*v256_map[3] + b*v256_map[2] + a*v256_map[1]
end

local function getHexValue(hex, type)
  -- return floor(hex/256^(4 - type)) - 256*floor(hex/256^(4 - type + 1))
  return floor(hex/v256_map[5 - type]) - 256*floor(hex/v256_map[6 - type])
end

-- Converts a hex value to a red, green, blue, alpha (0 - 1)
-- r, g, b, a = convRgbaToHex(hex)
local function convHexToRgba(hex)
  local r = getHexValue(hex, 1)/255
  local g = getHexValue(hex, 2)/255
  local b = getHexValue(hex, 3)/255
  local a = getHexValue(hex, 4)/255
  return r, g, b, a
end


-- -------- Constructors --------

-- Creates a color object from red, green, blue, alpha (0 - 1) values
-- color = color.rgba(red, green, blue, alpha)
function color.rgba(...)
  local c = {}

  local v = {...}
  if type(v[1]) == "table" then
    v = v[1]
  end

  -- If only one value is passed, assume its a hex value
  if v[1] and not (v[2] or v[3] or v[4]) then
    return color.hex(v[1])
  end

  for i = 1, 4 do
    if not v[i] then
      v[i] = 1  -- If a value is not set (ex. alpha) default it to 1.
    elseif v[i] > 1 then
      v[i] = v[i]/255  -- If a value is larger than 1, assume they are using 0-255 format (you really should instead use color.rgba255, but hey, this doesnt hurt anyone!)
    end
    v[i] = clamp(0, 1, v[i])
  end

  c.values = v
  c._props = {}

  c._props.r = v[1]
  c._props.g = v[2]
  c._props.b = v[3]
  c._props.a = v[4]

  setmetatable(c, color_mt)
  return c
end

-- Creates a color object from red, green, blue, alpha (0 - 255) values
-- color = color.rgba255(red, green, blue, alpha)
function color.rgba256(r, g, b, a)
  if r then r = r/255 end
  if g then g = g/255 end
  if b then b = b/255 end
  if a then a = a/255 end
  return color.rgb(r, g, b, a)
end

-- Creates a color object from a hue (0 - 360°), saturation (0 - 1), value (0 - 1), alpha (0 - 1)
-- color = color.hsva(hue, saturation, value, alpha)
function color.hsva(h, s, v, a)
  local r, g, b = convHsvToRgb(h % 360, clamp(0, 1, s), clamp(0, 1, v))
  local c = color.rgb(r, g, b, a)

  c._props.h = h
  c._props.s = s
  c._props.v = v

  return c
end

-- Creates a color object from red, green, blue (0 - 1) values. Assumes an alpha of 1
-- color = color.rgb(red, green, blue)
color.rgb = color.rgba

-- Creates a color object from red, green, blue (0 - 255) values. Assumes an alpha of 2255
-- color = color.rgb255(red, green, blue)
color.rgb256 = color.rgba256

-- Creates a color object from a hue (0 - 360°), saturation (0 - 1), value (0 - 1). Assumes an alpha of 1
-- color = color.hsv(hue, saturation, value)
color.hsv = color.hsva

-- Creates a color object from a hex value
-- color = color.hex(hex)
function color.hex(hex)
  local r, g, b, a = convHexToRgba(hex)
  local c = color.rgba(r, g, b, a)

  c._props.hex = hex

  return c
end






----------------------------
---------- Methods ---------
----------------------------


-- -------- Color Shifts --------

-- Returns a new color with a shifted red value. The value is clamped between (0 - 1)
-- color = color.shiftR(color, red_shift)
function color.shiftR(c, v)
  return color.rgba(c.r + v, c.g, c.b, c.a)
end

-- Returns a new color with a shifted green value. The value is clamped between (0 - 1)
-- color = color.shiftG(color, green_shift)
function color.shiftG(c, v)
  return color.rgba(c.r, c.g + v, c.b, c.a)
end

-- Returns a new color with a shifted blue value. The value is clamped between (0 - 1)
-- color = color.shiftB(color, green_shift)
function color.shiftB(c, v)
  return color.rgba(c.r, c.g, c.b, c.a)
end

-- Returns a new color with a shifted alpha value. The value is clamped between (0 - 1)
-- color = color.shiftA(color, alpha_shift)
function color.shiftA(c, v)
  return color.rgba(c.r, c.g, c.b + v, c.a)
end

-- Returns a new color with a shifted hue value. The value is wrapped between (0 - 360)
-- color = color.shiftH(color, alpha_shift)
function color.shiftH(c, v)
  return color.hsva(c.h + v, c.s, c.v, c.a)
end

-- Returns a new color with a shifted saturation value. The value is clamped between (0 - 1)
-- color = color.shiftS(color, saturation_shift)
function color.shiftS(c, v)
  return color.hsva(c.h, c.s + v, c.v, c.a)
end

-- Returns a new color with a shifted value value. The value is clamped between (0 - 1)
-- color = color.shiftV(color, value_shift)
function color.shiftV(c, v)
  return color.hsva(c.h, c.s, c.v + v, c.a)
end


-- -------- Blend Modes ---------

local function bl_alpha(x1, x2) return x2 + x1*(1 - x2) end
local function bl_over(x1, x2) return x2 end
local function bl_mult(x1, x2)  return x1*x2 end
local function bl_additive(x1, x2) return x1 + x2 end
local function bl_colorburn(x1, x2) return 1 - (1 - x2)/x1 end
local function bl_colordodge(x1, x2) return x2/(1 - x1) end
local function bl_reflect(x1, x2) return 0 end
local function bl_glow(x1, x2) return 0 end
local function bl_overlay(x1, x2) return (2*x1*x2 and x1 < 0.5) or 1 - 2*(1 - x1)*(1 - x2) end
local function bl_diff(x1, x2) return abs(x1 - x2) end
local function bl_negation(x1, x2) return 0 end
local function bl_lighten(x1, x2) return max(x1, x2) end
local function bl_darken(x1, x2) return min(x1, x2) end
local function bl_screen(x1, x2) return 1 - (1 - x1)*(1 - x2) end
local function bl_xor(x1, x2) return 0 end

local function color_mixer(b, x1, x2, a1, a2)
  local F1, F2 = 1 - a2, 1
  x2 = (1 - a1)*x2 + a1*clamp(0, 1, b(x1, x2))

  return a1*F1*x1 + a2*F2*x2
end

local function color_mix(b, c1, c2)
  local x1, x2 = c1.rgb, c2.rgb
  local a1, a2 = c1.a, c2.a

  local rn = color_mixer(b, x1[1], x2[1], a1, a2)
  local gn = color_mixer(b, x1[2], x2[2], a1, a2)
  local bn = color_mixer(b, x1[3], x2[3], a1, a2)
  local an = bl_alpha(a1, a2)

  return color.rgba(rn, gn, bn, an)
end

-- Returns two colors blended (normal/overlap)
-- color = color.over(color_backdrop, color_source)
function color.over(c1, c2)
  return color_mix(bl_over, c1, c2)
end

-- Returns two colors blended (multiply)
-- color = color.over(color_backdrop, color_source)
function color.multiply(c1, c2)
  return color_mix(bl_mult, c1, c2)
end

-- Returns two colors blended (additive)
-- color = color.over(color_backdrop, color_source)
function color.additive(c1, c2)
  return color_mix(bl_additive, c1, c2)
end

-- Returns two colors blended (color burn)
-- color = color.over(color_backdrop, color_source)
function color.colorBurn(c1, c2)
  return color_mix(bl_colorburn, c1, c2)
end

-- Returns two colors blended (color dodge)
-- color = color.over(color_backdrop, color_source)
function color.colorDodge(c1, c2)
  return color_mix(bl_colordodge, c1, c2)
end

-- Returns two colors blended (reflect)
-- color = color.over(color_backdrop, color_source)
function color.reflect(c1, c2)
  return color_mix(bl_reflect, c1, c2)
end

-- Returns two colors blended (glow)
-- color = color.over(color_backdrop, color_source)
function color.glow(c1, c2)
  return color_mix(bl_glow, c1, c2)
end

-- Returns two colors blended (overlay)
-- color = color.over(color_backdrop, color_source)
function color.overlay(c1, c2)
  return color_mix(bl_overlay, c1, c2)
end

-- Returns two colors blended (difference)
-- color = color.over(color_backdrop, color_source)
function color.difference(c1, c2)
  return color_mix(bl_diff, c1, c2)
end

-- Returns two colors blended (negation)
-- color = color.over(color_backdrop, color_source)
function color.negation(c1, c2)
  return color_mix(bl_negation, c1, c2)
end

-- Returns two colors blended (lighten)
-- color = color.over(color_backdrop, color_source)
function color.lighten(c1, c2)
  return color_mix(bl_lighten, c1, c2)
end

-- Returns two colors blended (darken)
-- color = color.over(color_backdrop, color_source)
function color.darken(c1, c2)
  return color_mix(bl_darken, c1, c2)
end

-- Returns two colors blended (screen)
-- color = color.over(color_backdrop, color_source)
function color.screen(c1, c2)
  return color_mix(bl_screen, c1, c2)
end

-- Returns two colors blended (xor)
-- color = color.over(color_backdrop, color_source)
function color.xor(c1, c2)
  return color_mix(bl_xor, c1, c2)
end

-- ------- Getter/Setters -------

local function reset(t)
  t._props = {}
end

local function getter_r(c)
  return c.values[1]
end

local function setter_r(c, v)
  c.values[1] = clamp(0, 1, v)
  reset(c)
end


local function getter_g(c)
  return c.values[2]
end

local function setter_g(c, v)
  c.values[2] = clamp(0, 1, v)
  reset(c)
end

local function getter_b(c)
  return c.values[3]
end

local function setter_b(c, v)
  c.values[3] = clamp(0, 1, v)
  reset(c)
end

local function getter_a(c)
  return c.values[4]
end

local function setter_a(c, v)
  c.values[4] = clamp(0, 1, v)
end

local function getter_h(c)
  local h, s, v = convRgbToHsv(c.r, c.g, c.b)

  c._props.h = h
  c._props.s = s
  c._props.v = v

  return h
end

local function setter_h(c, v)
  local h, s, v = v, c.s, c.v
  local r, g, b = convHsvToRgb(h, s, v)
  c.values[1] = r
  c.values[2] = g
  c.values[3] = b

  reset(c)

  c._props.h = h
  c._props.s = s
  c._props.v = v
end

local function getter_s(c)
  local h, s, v = convRgbToHsv(c.r, c.g, c.b)

  c._props.h = h
  c._props.s = s
  c._props.v = v

  return s
end

local function setter_s(c, v)
  local h, s, v = c.h, v, c.v
  local r, g, b = convHsvToRgb(h, s, v)
  c.values[1] = r
  c.values[2] = g
  c.values[3] = b

  reset(c)

  c._props.h = h
  c._props.s = s
  c._props.v = v
end

local function getter_v(c)
  local h, s, v = convRgbToHsv(c.r, c.g, c.b)

  c._props.h = h
  c._props.s = s
  c._props.v = v

  return v
end

local function setter_v(c, v)
  local h, s, v = c.h, c.s, v
  local r, g, b = convHsvToRgb(h, s, v)
  c.values[1] = r
  c.values[2] = g
  c.values[3] = b

  reset(c)

  c._props.h = h
  c._props.s = s
  c._props.v = v
end



local function getter_rgb(c)
  return {c.values[1], c.values[2], c.values[3]}
end

local function getter_rgba(c)
  return {c.values[1], c.values[2], c.values[3], c.values[4]}
end

local function setter_rgb(c, v)
  c.values[1] = v[1]
  c.values[2] = v[2]
  c.values[3] = v[3]
  reset(c)
end

local function setter_rgba(c, v)
  c.values[1] = v[1]
  c.values[2] = v[2]
  c.values[3] = v[3]
  c.values[4] = v[4]
  reset(c)
end

local function getter_hsv(c)
  return {c.h, c.s, c.v}
end

local function getter_hsva(c)
  return {c.h, c.s, c.v, c.a}
end

local function setter_hsv(c, v)
  local h, s, v = v[1], v[2], v[3]
  local r, g, b = convHsvToRgb(h, s, v)
  c.values[1] = r
  c.values[2] = g
  c.values[3] = b

  reset(c)

  c._props.h = h
  c._props.s = s
  c._props.v = v
end

local function setter_hsva(c, v)
  local h, s, v = v[1], v[2], v[3]
  local r, g, b = convHsvToRgb(h, s, v)
  c.values[1] = r
  c.values[2] = g
  c.values[3] = b
  c.values[4] = v[4]

  reset(c)

  c._props.h = h
  c._props.s = s
  c._props.v = v
end


local function getter_hex(c)
  return convRgbaToHex(c.r, c.g, c.b, c.a)
end

local function setter_hex(c, v)
  local r, g, b, a = convHexToRgba(v)
  c.values[1] = r
  c.values[2] = g
  c.values[3] = b
  c.values[4] = a

  reset(c)

  c._props.hex = v
end


-- ------------ Misc ------------

-- Returns a string representation of the color
-- color = color.string(color)
function color.string(c)
  local val = c.values

  local hexString = string.format("#%02X%02X%02X%02X", floor(255*val[1]), floor(255*val[2]), floor(255*val[3]), floor(255*val[4]))
  -- local rgbaString = "["..c.r.." "..c.g.." "..c.b.." "..c.a.."]"
  -- local hsvString = "["..c.h.." "..c.s.." "..c.v.." "..c.a.."]"
  -- local fixedString = "["..floor(255*val[1]).." "..floor(255*val[2]).." "..floor(255*val[3]).." "..floor(255*val[4]).."]"

  return hexString --.."\n"..rgbaString.."\n"..hsvString.."\n"..fixedString
end

-- Returns an interpolated (0 - 1) color between two colors
-- color = color.lerp(color1, color2, interp_value)
function color.lerp(c1, c2, n)
  return color.rgba(lerp(c1.r, c2.r, n), lerp(c1.g, c2.g, n), lerp(c1.b, c2.b, n), lerp(c1.a, c2.a, n))
end

-- Creates a new color identical to the one passed
-- color = color.clone(color)
function color.clone(c)
  return color.rgba(c.r, c.g, c.b, c.a)
end



-- ==============================
-- ======== Props Setup =========
-- ==============================

-- ----------- _Index -----------

-- When accessing the index of a color, make it behave as if accessing r, g, b, a
local indexproplist = {'r', 'g', 'b', 'a', 'h', 's', 'v'}

function color_props._index.getter(t, k)
  return t[indexproplist[k]]
end

function color_props._index.setter(t, k, v)
  t[indexproplist[k]] = v
end

-- ---------- Register ----------

color.registerprop{name = 'r',      type = 'read-write', getter = getter_r,    setter = setter_r}
color.registerprop{name = 'g',      type = 'read-write', getter = getter_g,    setter = setter_g}
color.registerprop{name = 'b',      type = 'read-write', getter = getter_b,    setter = setter_b}
color.registerprop{name = 'a',      type = 'read-write', getter = getter_a,    setter = setter_a}
color.registerprop{name = 'h',      type = 'read-write', getter = getter_h,    setter = setter_h}
color.registerprop{name = 's',      type = 'read-write', getter = getter_s,    setter = setter_s}
color.registerprop{name = 'v',      type = 'read-write', getter = getter_v,    setter = setter_v}

color.registerprop{name = 'rgb',    type = 'read-write', getter = getter_rgb,  setter = setter_rgb}
color.registerprop{name = 'rgba',   type = 'read-write', getter = getter_rgba, setter = setter_rgba}
color.registerprop{name = 'hsv',    type = 'read-write', getter = getter_hsv,  setter = setter_hsv}
color.registerprop{name = 'hsva',   type = 'read-write', getter = getter_hsva, setter = setter_hsva}
color.registerprop{name = 'hex',    type = 'read-write', getter = getter_hex,  setter = setter_hex}
color.registerprop{name = 'string', type = 'read-only'}

color.registerprop{name = "shiftR", type = 'method'}
color.registerprop{name = "shiftG", type = 'method'}
color.registerprop{name = "shiftB", type = 'method'}
color.registerprop{name = "shiftA", type = 'method'}
color.registerprop{name = "shiftH", type = 'method'}
color.registerprop{name = "shiftS", type = 'method'}
color.registerprop{name = "shiftV", type = 'method'}

color.registerprop{name = "lerp",       type = 'method'}
color.registerprop{name = "clone",      type = 'method'}
color.registerprop{name = "over",       type = 'method'}
color.registerprop{name = "multiply",   type = 'method'}
color.registerprop{name = "additive",   type = 'method'}
color.registerprop{name = "colorBurn",  type = 'method'}
color.registerprop{name = "colorDodge", type = 'method'}
color.registerprop{name = "reflect",    type = 'method'}
color.registerprop{name = "glow",       type = 'method'}
color.registerprop{name = "overlay",    type = 'method'}
color.registerprop{name = "difference", type = 'method'}
color.registerprop{name = "negation",   type = 'method'}
color.registerprop{name = "lighten",    type = 'method'}
color.registerprop{name = "darken",     type = 'method'}
color.registerprop{name = "screen",     type = 'method'}
color.registerprop{name = "xor",        type = 'method'}


-- ---------- Aliases -----------

color.registerpropAlias("r", "red")
color.registerpropAlias("g", "green")
color.registerpropAlias("b", "blue")
color.registerpropAlias("a", "alpha")
color.registerpropAlias("h", "hue")
color.registerpropAlias("s", "saturation", "sat")
color.registerpropAlias("v", "value", "val")
color.registerpropAlias("string", "hexString")

color.registerpropAlias("shiftR", "shiftRed")
color.registerpropAlias("shiftG", "shiftGreen")
color.registerpropAlias("shiftB", "shiftBlue")
color.registerpropAlias("shiftA", "shiftAlpha")
color.registerpropAlias("shiftH", "shiftHue")
color.registerpropAlias("shiftS", "shiftSaturation", "shiftSat")
color.registerpropAlias("shiftV", "shiftValue", "shiftVal")


-- ==============================
-- ======= Default Colors =======
-- ==============================

-- --------- Grayscale ----------

color.white  = color(0xFFFFFFFF)
color.silver = color(0xC0C0C0FF)
color.gray   = color(0x808080FF)
color.iron   = color(0xa9a9a9FF)
color.black  = color(0x000000FF)

-- -------- Basic Colors --------

color.red    = color(0xFF0000FF)
color.orange = color(0xFFA500FF)
color.yellow = color(0xFFFF00FF)
color.green  = color(0x00FF00FF)
color.blue   = color(0x0000FFFF)
color.purple = color(0x800080FF)

-- -------- Fancy Colors --------

color.maroon = color(0x800000FF)
color.olive  = color(0x808000FF)
color.lime   = color(0x00FF00FF)
color.aqua   = color(0x00FFFFFF)
color.teal   = color(0x008080FF)
color.navy   = color(0x000080FF)
color.pink   = color(0xFF00FFFF)
color.violet = color(0x9B26B6FF)
