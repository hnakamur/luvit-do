local Do = require('../do')

local dump = require('utils').dump
local string = require('string')
local FS = Do.convert(require('fs'),
                      {"mkdir", "rmdir", "stat", "truncate", "unlink",
                       "writeFile"})
local Path = require('path')
local Module = require('module')

local exports = {}

exports['test_chain_array_arg'] = function(test, asserts)
  function action1(cb, eb)
    process.nextTick(function()
      cb(1)
    end)
  end

  function action2(result)
    return function(cb, eb)
      process.nextTick(function()
        cb{result, 2}
      end)
    end
  end

  function callback(results)
    asserts.dequals(results, {1, 2})
    test.done()
  end

  function errback(err, ...)
    asserts.ok(false, 'errback is supposed not to be called.')
    test.done()
  end

  Do.chain{
    action1,
    action2
  }(callback, errback)
end

exports['test_chain_vararg'] = function(test, asserts)
  function action1(cb, eb)
    process.nextTick(function()
      cb(1)
    end)
  end

  function action2(result)
    return function(cb, eb)
      process.nextTick(function()
        cb{result, 2}
      end)
    end
  end

  function callback(results)
    asserts.dequals(results, {1, 2})
    test.done()
  end

  function errback(err, ...)
    asserts.ok(false, 'errback is supposed not to be called.')
    test.done()
  end

  Do.chain(
    action1,
    action2
  )(callback, errback)
end

exports['test_chain_fs'] = function(test, asserts)
  local dir = Path.join('tmp')
  local file = Path.join(dir, 'truncate-file.txt')
  local data = string.rep('x', 1024 * 16)

  function callback(results)
    test.done()
  end

  function debug(results)
    return function(callback, errback)
      print("debug results=" .. dump(results))
      callback(results)
    end
  end

  function errback(err, ...)
    print('errback called ' .. dump(err))
    asserts.ok(false, 'errback is supposed not to be called.')
    test.done()
  end

  Do.chain{
    FS.mkdir(dir, '0777'),
    function()
      return FS.writeFile(file, data)
    end,
    function()
      return FS.stat(file)
    end,
    function(stat)
      asserts.equals(stat.size, 1024 * 16)
      return function(cb, eb)
        cb()
      end
    end,
    function()
      return FS.truncate(file, 1024)
    end,
    function()
      return FS.stat(file)
    end,
    function(stat)
      asserts.equals(stat.size, 1024)
      return function(cb, eb)
        cb()
      end
    end,
    function()
      return FS.truncate(file, 0)
    end,
    function()
      return FS.stat(file)
    end,
    function(stat)
      asserts.equals(stat.size, 0)
      return function(cb, eb)
        cb()
      end
    end,
    function()
      return FS.unlink(file)
    end,
    function()
      return FS.rmdir(dir)
    end
  }(callback, errback)
end

return exports
