local raw_type = type
_G.type = function(x)
  local otype = raw_type(x)
  local mt = getmetatable(x)
  if  otype == "table" and mt and mt.__name then
    return mt.__name
  end
  return otype
end



local classList = {"vector", "complex", "matrix", "color"}
local classMap = {}

for k, v in ipairs(classList) do
  classMap[v] = _G[v]
end


local builtinMathFuncs = table.keys(math)

for k_, name in ipairs(builtinMathFuncs) do
  local raw_func = math[name]
  math[name] = function(...)
    local class = type(...)
    print(class)

    if class == "vector" then
      local t = {...}
      t=t[1]
      local l = t.numberList
      local v = vector.emptyClone(t)
      for i = 1, #l do
        v.numberList[i] = raw_func(t.numberList[i])
      end
      return v
    elseif class == "matrix" then
      local t = {...}
      t=t[1]
      local m = matrix.zeros(t.size)
      local l = t.numberList
      for i = 1, #l do
        m.numberList[i] = raw_func(t.numberList[i])
      end
      return m
    elseif class == "complex" and complex[name] then
      return complex[name](...)
    else
      return raw_func(...)
    end
  end
end



--------------------------------------------------
----------     METAMETHODS     -------------------
--------------------------------------------------

local meta_mt = {}

local meta = {}
local meta_MAP = {}

meta.__add = { -- + 
  {"vector", "vector",   function(v1, v2) return vector.plus(v1, v2)        end},
  {"vector", "number",   function(v, n)   return vector.plus_scalar(v, n)   end},
  {"number", "vector",   function(n, v)   return vector.plus_scalar(v, n)   end},
  {"complex", "complex", function(c1, c2) return complex.plus(c1, c2)       end},
  {"complex", "number",  function(c, n)   return complex.plus_number(c, n)  end},
  {"number", "complex",  function(n, c)   return complex.plus_number(c, n)  end},
  {"vector", "complex",  function(v, c)   return vector.plus_scalar(v, c)   end},
  {"complex", "vector",  function(c, v)   return vector.plus_scalar(v, c)   end},
  {"matrix", "matrix",   function(m1, m2) return matrix.plus(m1, m2)        end},
  {"matrix", "number",   function(m, n)   return matrix.plus_scalar(m, n)   end},
  {"number", "matrix",   function(n, m)   return matrix.plus_scalar(m, n)   end},
}

meta.__sub = { -- - 
  {"vector", "vector",   function(v1, v2) return vector.minus(v1, v2)          end},
  {"vector", "number",   function(v, n)   return vector.minus_scalar(v, n)     end},
  {"number", "vector",   function(n, v)   return vector.minus_scalar(-v, -n)   end},
  {"complex", "complex", function(c1, c2) return complex.minus(c1, c2)         end},
  {"complex", "number",  function(c, n)   return complex.minus_number(c, n)    end},
  {"number", "complex",  function(n, c)   return complex.minus_number(-c, -n)  end},
  {"vector", "complex",  function(v, c)   return vector.minus_scalar(v, c)     end},
  {"complex", "vector",  function(c, v)   return vector.minus_scalar(-v, -c)   end},
  {"matrix", "matrix",   function(m1, m2) return matrix.minus(m1, m2)          end},
  {"matrix", "number",   function(m, n)   return matrix.minus_scalar(m, n)     end},
  {"number", "matrix",   function(n, m)   return matrix.minus_scalar(-m, -n)   end},
}

meta.__mul = { -- *
  {"vector", "vector",   function(v1, v2) return vector.times(v1, v2)      end},
  {"vector", "number",   function(v, n)   return vector.scale(v, n)        end},
  {"number", "vector",   function(n, v)   return vector.scale(v, n)        end},
  {"complex", "complex", function(c1, c2) return complex.times(c1, c2)     end},
  {"complex", "number",  function(c, n)   return complex.scale(c, n)       end},
  {"number", "complex",  function(n, c)   return complex.scale(c, n)       end},
  {"vector", "complex",  function(v, c)   return vector.scale(v, c)        end},
  {"complex", "vector",  function(c, v)   return vector.scale(v, c)        end},
  {"matrix", "matrix",   function(m1, m2) return matrix.times(m1, m2)      end},
  {"matrix", "number",   function(m, n)   return matrix.scale(m, n)        end},
  {"number", "matrix",   function(n, m)   return matrix.scale(m, n)        end},
}

meta.__div = { -- /
  {"vector", "vector",   function(v1, v2) return vector.divide(v1, v2)      end},
  {"vector", "number",   function(v, n)   return vector.divide_scalar(v, n)   end},
  {"number", "vector",   function(v, n)   return vector.divideM_scalar(v, n)  end},
  {"complex", "complex", function(c1, c2) return complex.divide(c1, c2)     end},
  {"complex", "number",  function(c, n)   return complex.divide_scalar(c, n)       end},
  {"number", "complex",  function(n, c)   return complex.divideM_scalar(c, n)       end},
  {"vector", "complex",  function(v, c)   return vector.divide_scalar(v, c)        end},
  {"complex", "vector",  function(c, v)   return vector.divide_scalar(v, c)        end},

  {"matrix", "matrix",   function(m1, m2) return matrix.divide(m1, m2)      end},
  {"matrix", "number",   function(m, n)   return matrix.divide_scalar(m, n)        end},
  {"number", "matrix",   function(n, m)   return matrix.divideM_scalar(m, n)        end},
  {"matrix", "vector",   function(m, v)   return matrix.divide(m, v.matrix)  end},
  {"vector", "matrix",   function(v, m)   return matrix.divide(v.matrix, m)  end},
}

meta.__pow = { -- ^
  {"vector", "vector",   function(v1, v2) return vector.power(v1, v2)       end},
  {"vector", "number",   function(v, n)   return vector.power_scalar(v, n)  end},
  {"matrix", "matrix",   function(m1, m2) return matrix.power(m1, m2)       end},
  {"matrix", "number",   function(m, n)   return matrix.power_scalar(m, n)  end},
  {"complex", "number",  function(c, n)   return complex.power_scalar(c, n) end},
  {"complex", "complex", function(c1, c2) return complex.power(c1, c2)      end},
}

meta.__concat = { -- ..
  {"vector", "vector",   function(v1, v2) return vector.concat(v1, v2)     end},
}

meta.__bnot = { -- ~
  {"matrix", "matrix", function(m) return matrix.transpose(m) end},
  {"vector", "vector", function(v) return vector.transpose(v) end},
  {"complex", "complex", function (c) return complex.conjugate(c) end}
}

meta.__band = { -- &
  {"vector", "vector",   function(v1, v2) return matrix.mult(v1.matrix, v2.matrix)  end},
  {"matrix", "matrix",   function(m1, m2)   return matrix.mult(m1, m2)              end},
  {"matrix", "vector",   function(m, v)   return matrix.mult(m, v.matrix)           end},
  {"vector", "matrix",   function(v, m)   return matrix.mult(v.matrix, m)           end},
}

meta.__bor = { -- |
}


for k, v in pairs(meta) do
  meta_MAP[k] = {}
  for _, q in ipairs(v) do
    meta_MAP[k][q[1]..","..q[2]] = q[3]
  end

  meta_mt[k] = function(t1, t2)
    local m =  meta_MAP[k][type(t1)..","..type(t2)]
    if m then
      return m(t1, t2)
    end
  end

  for _, q in ipairs(classList) do
    _G[q].mt[k] = meta_mt[k]
  end
end
