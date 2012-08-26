local dump = require('utils').dump
local string = require('string')
local table = require('table')

local exports = {}
-- Takes an array of actions and runs them all in parallel.
-- You can either pass in an array of actions, or several actions
-- as function arguments.
-- If you pass in an array, then the output will be an array of all the results
-- If you pass in separate arguments, then the output will have several arguments.
function exports.parallel(actions, ...)
  local arrayPassed = type(actions) == 'table'
  if not arrayPassed then
    actions = {actions, ...}
  end
  return function(callback, errback)
    local results = {}
    for i, action in ipairs(actions) do
      action(function(result)
        results[i] = result
        if i == #actions then
          if arrayPassed then
            callback(results)
          else
            callback(unpack(results))
          end
        end
      end, errback)
    end
  end
end

-- Chains together several actions feeding the output of the first to the
-- input of the second and the final output to the callback
function exports.chain(actions, ...)
  if type(actions) ~= 'table' then
    actions = {actions, ...}
  end
  return function(callback, errback)
    local pos = 1
    function loop(result)
      pos = pos + 1
      if pos > #actions then
        callback(result)
      else
        actions[pos](result)(loop, errback)
      end
    end
    actions[pos](loop, errback)
  end
end

-- Takes an array and does an array map over it using the async callback `fn`
-- The signature of `fn` is `function fn(item, callback, errback)`
function exports.map(array, fn)
  return function(callback, errback)
    local counter = #array
    local new_array = {}
    for index, item in ipairs(array) do
      local local_callback = function(result)
        new_array[index] = result
        counter = counter - 1
        if counter <= 0 then
          callback(new_array)
        end
      end
      local cont = fn(item, local_callback, errback)
      if type(conf) == 'function' then
        cont(local_callback, errback)
      end
    end
  end
end

-- Takes an array and does an array filter over it using the async callback `fn`
-- The signature of `fn` is `function fn(item, callback, errback)`
function exports.filter(array, fn)
  return function (callback, errback)
    local counter = #array
    local valid = {}
    for index, item in ipairs(array) do
      local local_callback = function(result)
        valid[index] = result
        counter = counter - 1
        if counter <= 0 then
          local result = {}
          for index, item in ipairs(array) do
            if valid[index] then
              result[#result + 1] = item
            end
          end
          callback(result)
        end
      end
      local cont = fn(item, local_callback, errback)
      if type(cont) == 'function' then
        cont(local_callback, errback)
      end
    end
  end
end

function getTableKeys(table)
  local keys = {}
  for key, _ in pairs(table) do
    keys[#keys + 1] = key
  end
  return keys
end

function filterArray(array, predicate)
  local keys = getTableKeys(array)
  table.sort(keys)
  local new_array = {}
  for _, key in ipairs(keys) do
    local item = array[key]
    if predicate(item) then
      new_array[#new_array + 1] = item
    end
  end
  return new_array
end

-- Takes an array and does a combined filter and map over it.  If the result
-- of an item is nil, then it's filtered out, otherwise it's mapped in.
-- The signature of `fn` is `function fn(item, callback, errback)`
function exports.filterMap(array, fn)
  return function (callback, errback)
    local counter = #array
    local new_array = {}
    for index, item in ipairs(array) do
      local local_callback = function(result)
        new_array[index] = result
        counter = counter - 1
        if counter <= 0 then
          callback(filterArray(new_array, function(item)
            return item ~= nil
          end))
        end
      end
      local cont = fn(item, local_callback, errback)
      if type(cont) == 'function' then
        cont(local_callback, errback)
      end
    end
  end
end

function indexOf(array, value)
  for i, v in ipairs(array) do
    if v == value then
      return i
    end
  end
  return -1
end

-- Takes any async lib that uses callback based signatures and converts
-- the specified names to continuable style and returns the new library.
function exports.convert(lib, names)
--  print("covnert lib=" .. dump(lib))
  local newlib = {}
  for name, fn in pairs(lib) do
    if indexOf(names, name) < 0 then
      newlib[name] = fn
    else
      newlib[name] = function(...)
        local args = {...}
        return function(callback, errback)
          args[#args + 1] = function(err, val)
            if err then
              errback(err)
            else
              callback(val)
            end
          end
          fn(unpack(args))
        end
      end
    end
  end
  return newlib
end

return exports
