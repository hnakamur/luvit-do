local Do = require('../do')

local exports = {}

exports['test_parallel_array_arg'] = function(test, asserts)
  function action1(cb, eb)
    process.nextTick(function()
      cb(1)
    end)
  end

  function action2(cb, eb)
    process.nextTick(function()
      cb(2)
    end)
  end

  function callback(results)
    asserts.dequals(results, {1, 2})
    test.done()
  end

  function errback(err, ...)
    asserts.ok(false, 'errback is supposed not to be called.')
    test.done()
  end

  Do.parallel{
    action1,
    action2
  }(callback, errback)
end

exports['test_parallel_vararg'] = function(test, asserts)
  function action1(cb, eb)
    process.nextTick(function()
      cb(1)
    end)
  end

  function action2(cb, eb)
    process.nextTick(function()
      cb(2)
    end)
  end

  function callback(result1, result2)
    asserts.equals(result1, 1)
    asserts.equals(result2, 2)
    test.done()
  end

  function errback(err, ...)
    asserts.ok(false, 'errback is supposed not to be called.')
    test.done()
  end

  Do.parallel(
    action1,
    action2
  )(callback, errback)
end

return exports
