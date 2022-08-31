local lib = {}





function lib.new(className, classTable)
  -- --------- Properties ---------

  local props = {}
  classTable.props = props

  props._index = {}

  -- Register a class property
  -- registerprop{
  --   name = Name of the property
  --   type = How this property should behave: 'read-only', 'read-write', 'method'
  --   getter = Function that returns the value (optional)
  --   setter = Function that defines how to set that value (optional)
  -- }
  function classTable.registerprop(t)
    props[t.name] = t
  end

  -- Register an alias to a property
  -- registerpropAlias('PropName', 'MyAlias1', 'MyAlias2', ...)
  function classTable.registerpropAlias(name, ...)
    local isMethod = (props[name].type == 'method')

    for _, v in ipairs({...}) do
      props[v] = props[name]

      -- Add the method function to the class, just to be consistent
      if isMethod then
        classTable[v] = props[name].getter or classTable[name]
      end
    end
  end


  -- ------- Class Metatable ------

  classTable.mt = {}
  local classTable_mt = classTable.mt


  -- Define a class name for type(...) compatibility
  classTable_mt.__name = className

  -- Define what data you can access out of the class
  classTable_mt.__index = function(t, k)

    -- If index is a number, use special '_index' prop
    if type(k) == 'number' then
      return props._index.getter(t, k)
    end

    if not props[k] then return end  -- Only allows access to props values

    -- If the prop is a method, then return the function
    if  props[k].type == 'method' then
      return props[k].getter or classTable[props[k].name]  -- If the getter doesnt exist, assume its part of the class (is thiz needed? Can be just: classTable[props[k].name])

      -- Otherwise, return the intended value
    else
      -- If prop value does not exists, calculate it and save it
      if not t._props[k] then
        local f = props[k].getter or classTable[props[k].name]  -- If the getter doesnt exist, assume its part of the class
        local x = f(t)

        -- Save the result to avoid recalculating everytime
        t._props[k] = x
      end

      return t._props[k]
    end
  end

  -- Define what data you can write into the class
  classTable_mt.__newindex = function(t, k, v)

    -- If index is a number, use special '_index' prop
    if type(k) == 'number' then
      props._index.setter(t, k, v)
    end

    -- If it is a prop then do what is specified
    if props[k] then
      props[k].setter(t, v)

      -- Otherwise allow the user to store its own user data
    else
      rawset(t, k, v)
    end
  end

  -- Define what string to use for print(...) (etc)
  classTable_mt.__tostring = function(t)
    return t.string
  end

end

return lib
