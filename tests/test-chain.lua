local Do = require('../do')

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

return exports
