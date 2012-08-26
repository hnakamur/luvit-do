local string = require('string')
local Do = require('../do')

local exports = {}

exports['test_map'] = function(test, asserts)
  function lower(str, cb, eb)
    process.nextTick(function()
      cb(string.lower(str))
    end)
  end

  function callback(results)
    asserts.dequals(results, {'a', 'b'})
    test.done()
  end

  function errback(err, ...)
    asserts.ok(false, 'errback is supposed not to be called.')
    test.done()
  end

  Do.map({'A', 'B'}, lower)(callback, errback)
end

return exports
