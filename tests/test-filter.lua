local string = require('string')
local Do = require('../do')

local exports = {}

exports['test_filter'] = function(test, asserts)
  function isLower(str, cb, eb)
    process.nextTick(function()
      cb(string.lower(str) == str)
    end)
  end

  function callback(results)
    asserts.dequals(results, {'a', 'c'})
    test.done()
  end

  function errback(err, ...)
    asserts.ok(false, 'errback is supposed not to be called.')
    test.done()
  end

  Do.filter({'a', 'B', 'c'}, isLower)(callback, errback)
end

return exports
