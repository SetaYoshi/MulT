local collider = {}

local classConstruct = require("mult/classConstruct")

local floor, abs, pi = math.floor, math.abs, math.pi
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


-- ----- Export Collider Class -----

_G.collider2d = collider


-- ---- Auto-Generate Class -----

classConstruct.new("collider", collider)

local collider_props = collider.props
local collider_mt = collider.mt


-- ------- Class Metatable ------

local collider_class_mt = {}
setmetatable(collider, collider_class_mt)

-- Allow for collider(...) to be a shorcut for collider.rgba(...)
collider_class_mt.__call = function(t, ...)
  return collider.rgba(...)
end

-- ==============================
-- ========== The Math ==========
-- ==============================


-- ----- Conversion Formulas ----
local function cross(x1, y1, x2, y2, x3, y3, x4, y4)
  return (x2 - x1)*(y4 - y3) - (y2 - y1)*(x4 - x3)
end
local function dist(x1, y1, x2, y2)
  return sqrt((x1 - x2)^2 + (y1 - y2)^2)
end
local function dist_sqr(x1, y1, x2, y2)
  return (x1 - x2)^2 + (y1 - y2)^2
end

local collFunc = {}
local function registerCollFunc(a, b, f)
  collFunc[a.."-"..b] = f
end

registerCollFunc('point', 'point', function(c1_x, c1_y, c2_x, c2_y)
  return (c1_x == c2_x) and (c1_y == c2_y)
end)

registerCollFunc('line', 'point', function(c1_x1, c1_y1, c1_x2, c2_y2, c2_x, c2_y)
  local i = dist(c1_x1, c1_y1, c2_x, c2_y)
  local j = dist(c1_x2, c2_y2, c2_x, c2_y)
  local k = dist(c1_x1, c1_y1, c1_x2, c2_y2)
  local l = 2 -- This is a buffer

  return (i + j >= k - l and i + j <= k + l)
end)

registerCollFunc('line', 'line', function(c1_x1, c1_y1, c1_x2, c2_y2, c2_x1, c2_y1, c2_x2, c2_y2)
  return (cross(c1_x1, c1_y1, c1_x2, c2_y2, c1_x2, c2_y2, c2_x1, c2_y1)*cross(c1_x1, c1_y1, c1_x2, c2_y2, c1_x2, c2_y2, c2_y1, c2_y2) < 0 
      and cross(c2_x1, c2_y1, c2_x2, c2_y2, c2_y1, c2_y2, c1_x1, c1_y1)*cross(c2_x1, c2_y1, c2_x2, c2_y2, c2_y1, c2_y2, c1_x2, c2_y2) <= 0)
end)

registerCollFunc('rect', 'point', function(c1_x, c1_y, c1_w, c1_h, c2_x, c2_y)
  return (c2_x >= c1_x and c2_x <= c1_x + c1_w and c2_y >= c1_y and c2_y <= c1_y + c1_h)
end
)

registerCollFunc('rect', 'line', function(c1_x1, c1_y1, c1_w, c1_h, c2_x1, c2_y1, c2_x2, c2_y2)
  return (rect_point(c1_x1, c1_y1, c1_w, c1_h, c2_x2, c2_x2)
	or       line_line(c2_x1, c2_x2, c2_x2, c2_y2, c1_x1, c1_y1, c1_x2, c1_y1)
	or       line_line(c2_x1, c2_x2, c2_x2, c2_y2, c1_x1, c1_y1, c1_x1, c1_y2)
	or       line_line(c2_x1, c2_x2, c2_x2, c2_y2, c1_x2, c1_y2, c1_x2, c1_y1)
	or       line_line(c2_x1, c2_x2, c2_x2, c2_y2, c1_x2, c1_y2, c1_x1, c1_y2))

end)

registerCollFunc('rect', 'rect', function(c1_x, c1_y, c1_w, c1_h, c2_x, c2_y, c2_w, c2_h)
  return (c1_x < (c2_x + c2_w) and (c1_x + c1_w) > c2_x and c1_y < (c2_y + c2_h) and (c1_y + c1_h) > c2_y)
end)

registerCollFunc('circle', 'point', function(c1_x, c1_y, c1_r, c2_x, c2_y)
  return (dist_sqr(c1_x, c1_y, c2_x, c2_y) < c1_r^2)
end)

registerCollFunc('circle', 'line', function(c1_x, c1_y, c1_r, c2_x1, c2_y1, c2_x2, c2_y2)
  if circ_point(c1_x, c1_y, c1_r, c2_x1, c2_y1) or circ_point(c1_x, c1_y, c1_r, lx2, ly2) then 
    return true 
  end

	local i = dist_sqr(c2_x1, c2_y1, c2_x2, ly2) 
	local j = cross(c2_x1, c2_y1, c1_x, c1_y, ly1, c2_x1, ly2, c2_x2)/i
	local k = c2_x1 + j*(c2_x2 - c2_x1)
	local l = c2_y1 + j*(c2_y2 - c2_y1)

	-- if not line_point(c2_x1, c2_y1, c2_x2, ly2, k, l) then return false end
	-- return (dist(k, l, c1_x, c1_y) <= c1_r)

  return ((line_point(c2_x1, c2_y1, c2_x2, ly2, k, l)) and (dist(k, l, c1_x, c1_y) <= c1_r))
end)

registerCollFunc('circle', 'rect', function(c1_x, c1_y, c1_r, c2_x1, c2_y1, c2_w, c2_h)
  local c2_x2, c2_y2 = c2_x1 + c2_w, c2_y1 + c2_h

	local i, j = c1_x, c1_y
  if c1_x < c2_x1 then
      i = c2_x1
  elseif c1_x > c2_x2 then
      i = c2_x2
  end 
  if c1_y < c2_y1 then
      j = c2_x2
  elseif c1_y > c2_y2 then
      j = c2_y2
  end 

  return (dist_sqr(c1_x, c1_y, i, j) < c1_r^2)
end)

registerCollFunc('circle', 'circle', function(c1_x, c1_y, c1_r, c2_x, c2_y, c2_r)
  return (dist_sqr(c1_x, c1_y, c2_x, c2_y) <= (c1_r + c2_r)^2) 
end
)

registerCollFunc('triangle', 'point', function(c1_x1, c1_y1, c1_x2, c1_y2, c1_x3, c1_y3, c2_x, c2_y)
	return (area_tri(c2_x, c2_y, c1_x2, c1_y2, c1_x3, c1_y3) + area_tri(c1_x1, c1_y1, c2_x, c2_y, c1_x3, c1_y3) + area_tri(c1_x1, c1_y1, c1_x2, c1_y2, c2_x, c2_y) - area_tri(c1_x1, c1_y1, c1_x2, c1_y2, c1_x3, c1_y3) <= 0)
end)

registerCollFunc('triangle', 'line', function(c1_x1, c1_y1, c1_x2, c1_y2, c1_x3, c2_x1, c2_y1, c2_x2, c2_y2)
  return (line_line(c2_x1, c2_y1, c2_x2, c2_y2, c1_x1, c1_y1, c1_x2, c1_y2) 
	     or line_line(c2_x1, c2_y1, c2_x2, c2_y2, c1_x2, c1_y2, c1_x3, c1_y3) 
	     or line_line(c2_x1, c2_y1, c2_x2, c2_y2, c1_x3, c1_y3, c1_x1, c1_y1) 
	     or tri_point(c1_x1, c1_y1, c1_x2, c1_y2, c1_x3, c1_y3, c2_x1, c2_y1))
	-- tri_point(c1_x1, c1_y1, c1_x2, c1_y2, c1_x3, c1_y3, c2_x2, c2_y2) 
	
end)

registerCollFunc('triangle', 'rect', function(c1_x1, c1_y1, c1_x2, c1_y2, c1_x3, c1_y3, c2_x1, c2_y1, c2_w, c2_h)
  local c2_x2, c2_y2 = c2_x1 + c2_w, c2_y1 + c2_h

  return (line_line(c1_x1, c1_y1, c1_x2, c1_y2, c2_x1, c2_y1, c2_x2, c2_y1) 
	     or line_line(c1_x1, c1_y1, c1_x2, c1_y2, c2_x1, c2_y1, c2_x1, c2_y2) 
	     or line_line(c1_x1, c1_y1, c1_x2, c1_y2, c2_x2, c2_y1, c2_x2, c2_y2) 
	     or line_line(c1_x1, c1_y1, c1_x2, c1_y2, c2_x1, c2_y2, c2_x2, c2_y2) 

	     or line_line(c1_x3, c1_y3, c1_x2, c1_y2, c2_x1, c2_y1, c2_x2, c2_y1) 
	     or line_line(c1_x3, c1_y3, c1_x2, c1_y2, c2_x1, c2_y1, c2_x1, c2_y2) 
	     or line_line(c1_x3, c1_y3, c1_x2, c1_y2, c2_x2, c2_y1, c2_x2, c2_y2) 
	     or line_line(c1_x3, c1_y3, c1_x2, c1_y2, c2_x1, c2_y2, c2_x2, c2_y2) 

	     or line_line(c1_x1, c1_y1, c1_x3, c1_y3, c2_x1, c2_y1, c2_x2, c2_y1) 
	     or line_line(c1_x1, c1_y1, c1_x3, c1_y3, c2_x1, c2_y1, c2_x1, c2_y2) 
	     or line_line(c1_x1, c1_y1, c1_x3, c1_y3, c2_x2, c2_y1, c2_x2, c2_y2) 
	     or line_line(c1_x1, c1_y1, c1_x3, c1_y3, c2_x1, c2_y2, c2_x2, c2_y2) 

       or tri_point(c1_x1, c1_y1, c1_x2, c1_y2, c1_x3, c1_y3, c2_x1, c2_y1)	

       or rect_point(c2_x1, c2_y1, c2_w, c2_h, c1_x1, c1_y1)) 
      
  -- tri_point(tx1, ty1, tx2, ty2, tx3, ty3, rx + rw, ry)
  -- tri_point(tx1, ty1, tx2, ty2, tx3, ty3, rx, ry + rh)
  -- tri_point(tx1, ty1, tx2, ty2, tx3, ty3, rx + rw, ry + rh)
  -- rect_point(rx, ry, rw, rh, tx2, ty2)
	-- rect_point(rx, ry, rw, rh, tx3, ty3)
end )

registerCollFunc('triangle', 'circle', function(c1_x1, c1_y1, c1_x2, c1_y2, c1_x3, c1_y3, c2_x, c2_y, c2_r)
  if tri_point(c1_x1, c1_y1, c1_x2, c1_y2, c1_x3, c1_y3, c1_y3, c2_x, c2_y) 
	or circ_point(c2_x, c2_y, c2_r, c1_x1, c1_y1) 
	or circ_point(c2_x, c2_y, c2_r, c1_x2, c1_y2) 
	or circ_point(c2_x, c2_y, c2_r, c1_x3, c1_y3) then
    return true
  end

  local i, j, k, l, m, n

  i, j = c2_x  - c1_x1, c2_y  - c1_y1
	k, l = c1_x2 - c1_x1, c1_y2 - c1_y1
	m = i*k + j*l

	if m > 0 then  
		n = k^2 + l^2
		if m < n and abs(i^2 + j^2 - c2_r^2)*n <= m^2 then
      return true
    end
	end

	i, j = c2_x  - c1_x2, c2_y  - c1_y2
	k, l = c1_x3 - c1_x2, c1_y3 - c1_y2
	m = i*k + j*l

	if m > 0 then
		n = k^2 + l^2
		if m < n and abs(i^2 + j^2 - c2_r^2)*n <= m^2 then
      return true
    end
	end

	i, j = c2_x  - c1_x3, c2_y  - c1_y3
	k, l = c1_x1 - c1_x3, c1_y1 - c1_y3
	m = i*k + j*l

	if m > 0 then
		n = k^2 + l^2
		if m < n and abs(i^2 + j^2 - c2_r^2)*n <= m^2 then
      return true
    end
	end
end)

registerCollFunc('triangle', 'triangle', function(c1_x1, c1_y1, c1_x2, c1_y2, c1_x3, c1_y3, c2_x1, c2_y1, c2_x2, c2_y2, c2_x3, c2_y3)
  return (line_line(c1_x1, c1_y1, c1_x2, c1_y2, c2_x1, c2_y1, c2_x2, c2_y2) 
	     or line_line(c1_x1, c1_y1, c1_x2, c1_y2, c2_x2, c2_y2, c2_x3, c2_y3)
	     or line_line(c1_x1, c1_y1, c1_x2, c1_y2, c2_x3, c2_y3, c2_x1, c2_y1)

	     or line_line(c1_x2, c1_y2, c1_x3, c1_y3, c2_x1, c2_y1, c2_x2, c2_y2)
	     or line_line(c1_x2, c1_y2, c1_x3, c1_y3, c2_x2, c2_y2, c2_x3, c2_y3)
	     or line_line(c1_x2, c1_y2, c1_x3, c1_y3, c2_x3, c2_y3, c2_x1, c2_y1)

	     or line_line(c1_x3, c1_y3, c1_x1, c1_y1, c2_x1, c2_y1, c2_x2, c2_y2)
	     or line_line(c1_x3, c1_y3, c1_x1, c1_y1, c2_x2, c2_y2, c2_x3, c2_y3)
	     or line_line(c1_x3, c1_y3, c1_x1, c1_y1, c2_x3, c2_y3, c2_x1, c2_y1)

       or tri_point(c1_x1, c1_y1, c1_x2, c1_y2, c1_x3, c1_y3, c2_x1, c2_y1)
       or tri_point(c2_x1, c2_y1, c2_x2, c2_y2, c2_x3, c2_y3, c1_x1, c1_y1))

	-- if tri_point(t1x1, t1y1, t1x2, t1y2, t1x3, t1y3, t2x2, t2y2) then return -1
	-- if tri_point(t1x1, t1y1, t1x2, t1y2, t1x3, t1y3, t2x3, t2y3) then return -1
	-- if tri_point(t2x1, t2y1, t2x2, t2y2, t2x3, t2y3, t1x2, t1y2) then return -1
	-- if tri_point(t2x1, t2y1, t2x2, t2y2, t2x3, t2y3, t1x3, t1y3) then return -1
end)


-- -------- Constructors --------

function collider.point(...)
  local c = {}

  local v = {...}
  if type(v[1]) == "table" then
    v = v[1]
  end

  c.values = v
  c.type = 'point'

  return c
end

function collider.line(...)
  local c = {}

  local v = {...}
  if type(v[1]) == "table" then
    v = v[1]
  end

  local mode
  if type(v[1]) == "string" then
    mode = v[1]
    table.remove(v, 1)
  else
    mode = v[#v]
  end

  if not v[3] then
    v[1], v[2], v[3], v[4] = v[1].x, v[1].y, v[2].x, v[2].y
  elseif type(mode) ~= 'string' then
  elseif mode == 'size' then
    v[3], v[4] = v[1] + v[3], v[2] + v[4]
  elseif mode == 'polar' then
    v[3], v[4] = v[1] + v[3]*cos(v[4]), v[2] + v[3]*sin(v[4])
  elseif mode == 'polard' then
    v[3], v[4] = v[1] + v[3]*cosd(v[4]), v[2] + v[3]*sind(v[4])
  end

  c.values = v
  c.type = 'line'

  return c
end

function collider.rect(...)
  local c = {}

  local v = {...}
  if type(v[1]) == "table" then
    v = v[1]
  end

  local mode
  if type(v[1]) == "string" then
    mode = v[1]
    table.remove(v, 1)
  else
    mode = v[#v]
  end

  if type(mode) ~= 'string' then
  elseif mode == 'xyxy' then
    v[3], v[4] = v[1] - v[3], v[2] - v[4]
  elseif mode == 'centersize' then
    v[1], v[2] = v[1] - 0.5*v[3], v[2] - 0.5*v[4]
  end

  c.values = v
  c.type = 'rect'

  return c
end

function collider.circle(...)
  local c = {}

  local v = {...}
  if type(v[1]) == "table" then
    v = v[1]
  end

  c.values = v
  c.type = 'circle'

  return c
end

function collider.triangle(...)
  local c = {}

  local v = {...}
  if type(v[1]) == "table" then
    v = v[1]
  end

  local mode
  if type(v[1]) == "string" then
    mode = v[1]
    table.remove(v, 1)
  else
    mode = v[#v]
  end

  if not v[4] then
    v[1], v[2], v[3], v[4], v[5], v[6] = v[1].x, v[1].y, v[2].x, v[2].y, v[3].x, v[3].y
  elseif type(mode) ~= 'string' then
  elseif mode == 'size' then
    v[3], v[4], v[5], v[6] = v[1] + v[3], v[2] + v[4], v[1] + v[5], v[2] + v[6]
  end

  c.values = v
  c.type = 'triangle'

  return c
end

----------------------------
---------- Methods ---------
----------------------------


-- -------- Collider sss --------

function table.join(t1, t2)
  local t = {}
  for i = 1, #t1 do
    table.insert(t, t1[i])
  end
  for i = 1, #t2 do
    table.insert(t, t2[i])
  end
  return t
end

local typeSort = table.map{'point', 'line', 'rect', 'circle', 'triangle'}

function collider.collide(c1, c2)
  if typeSort[c1.type] < typeSort[c2.type] then
    c1, c2 = c2, c1 
  end
  print(c1.type, c2.type)
  return collFunc[c1.type.."-"..c2.type](table.unpack(table.join(c1.values, c2.values)))
end

function collider.translate(c, v)

end

function collider.scale(c, v)

end

function collider.rotate(c, v)

end


-- ------- Getter/Setters -------

local function reset(t)
  t._props = {}
end

local function getter_x1(c)
  return c.values[1]
end

local function getter_y1(c)
  return c.values[2]
end

local function getter_x2(c)
  return c.values[3]
end

local function getter_y2(c)
  return c.values[4]
end

local function getter_x3(c)
  return c.values[5]
end

local function getter_y3(c)
  return c.values[6]
end

local function getter_anchor(c)
  return c._anchor
end

local function setter_anchor(c, v)
  c._anchor = v
  aaaaaaaaaaaa()
end

-- local function getter_children(c, v)
--   if hasupdatedchild[v] then
--     updatechild()
--   end
--   return child
-- end


-- ------------ Misc ------------

local area_list = {}
function area_list.point(c)    return 0 end
function area_list.line(c)     return 0 end
function area_list.circle(c)   return pi*c.r^2 end
function area_list.triangle(c) return 0.5*abs(c.x1*(c.y2 - c.y3) + c.x2*(c.y3 - c.y1) + c.x3*(c.y1 - c.y2)) end
function area_list.rect(c)     return c.width*c.height end

function collider.area(c)
  return area_list[c.type](c)
end


local pi2 = pi*2

local perim_list = {}
function perim_list.point(c)    return 0 end
function perim_list.line(c)     return sqrt((c.x2 - c.x1)^2 + (c.y2 - c.y1)^2) end
function perim_list.circle(c)   return pi2*c.r end
function perim_list.triangle(c) return c.edges[1].perimeter + c.edges[2].perimeter + c.edges[3].perimeter end
function perim_list.rect(c)     return c.edges[1].perimeter + c.edges[2].perimeter + c.edges[3].perimeter + c.edges[4].perimeter end

function collider.perimeter(c)
  return perim_list[c.type](c)
end
-- Returns a string representation of the collider
-- collider = collider.string(collider)
function collider.string(c)
  return "<collider "..c.type..">"
end

-- Creates a new collider identical to the one passed
-- collider = collider.clone(collider)
function collider.clone(c)
  return collider.new()
end



-- ==============================
-- ======== Props Setup =========
-- ==============================

-- ----------- _Index -----------

-- When accessing the index of a collider, make it behave as if accessing r, g, b, a

function collider_props._index.getter(t, k)
  return t[indexproplist[k]]
end

function collider_props._index.setter(t, k, v)
  t[indexproplist[k]] = v
end

-- ---------- Register ----------

collider.registerprop{name = 'x1',      type = 'read-only',  getter = getter_x1}
collider.registerprop{name = 'y1',      type = 'read-only',  getter = getter_y1}
collider.registerprop{name = 'x2',      type = 'read-only',  getter = getter_x2}
collider.registerprop{name = 'y2',      type = 'read-only',  getter = getter_y2}
collider.registerprop{name = 'x3',      type = 'read-only',  getter = getter_x3}
collider.registerprop{name = 'y3',      type = 'read-only',  getter = getter_y3}

collider.registerprop{name = 'xy1',      type = 'read-only',  getter = getter_xy1}
collider.registerprop{name = 'xy2',      type = 'read-only',  getter = getter_xy2}
collider.registerprop{name = 'xy3',      type = 'read-only',  getter = getter_xy3}

collider.registerprop{name = 'anchor',  type = 'read-write', getter = getter_anchor, setter = setter_anchor}
collider.registerprop{name = 'string',  type = 'read-only'}
collider.registerprop{name = "collide", type = 'method'}

-- ---------- Aliases -----------

collider.registerpropAlias("x1", "x")
collider.registerpropAlias("y1", "y")
collider.registerpropAlias("x2", "width", "w")
collider.registerpropAlias("y2", "height", "h")
collider.registerpropAlias("x3", "radius", "r")

collider.registerpropAlias("xy1", "xy")
collider.registerpropAlias("xy2", "size")

-- ==============================
-- ======= Default colliders =======
-- ==============================
