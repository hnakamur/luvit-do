local string = require('string')
local Do = require('../do')

local exports = {}

exports['test_filterMap'] = function(test, asserts)
  function checkNumberAndIncrement(val, cb, eb)
    process.nextTick(function()
      if type(val) == 'number' then
        cb(val + 1)
      else
        cb()
      end
    end)
  end

  function callback(results)
    asserts.dequals(results, {2, 5})
    test.done()
  end

  function errback(err, ...)
    asserts.ok(false, 'errback is supposed not to be called.')
    test.done()
  end

  Do.filterMap({1, 'a', 4}, checkNumberAndIncrement)(callback, errback)
end

return exports
