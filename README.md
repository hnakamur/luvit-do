# `Do` it!

`Do` is a library that adds higher level abstraction and continuables.  What I mean by a continuable is explained by the following:

### Continuables

    function divide(a, b)
      return function(callback, errback)
        -- Use nextTick to prove that we're working asynchronously
        process.nextTick(function()
          if b == 0 then
            errback(Error:new("Cannot divide by 0"))
          else
            callback(a / b)
          end
        end)
      end
    end

`Do` expects async functions to not require the callback in the initial invocation, but instead return a continuable which can then be called with the `callback` and `errback`.  This is done by manually currying the function. The "continuable" is the partially applied version of the function returned by the outer function.  The body of the function won't be executed until you finish the application by attaching a callback.

    divide(100, 10)(function(result)
      print("the result is " .. dump(result))
    end, function(error)
      print("the error is " .. dump(error))
    end)

This style is extremely simple (doesn't require an external library like promises to use), and is fairly powerful.

 - The initial function can have variable arguments.
 - The continuable itself is portable until it's invoked by attaching callbacks.

## Higher-level operations

The `Do` library makes doing higher-level abstractions easy.  All of these helpers are themselves continuables so you can attach callbacks by calling the returned, curried function.

### Do.parallel(actions) {...}

Takes an array of actions and runs them all in parallel. You can either pass in an array of actions, or several actions as function arguments.

 - If you pass in an array, then the output will be an array of all the results
 - If you pass in separate arguments, then the output will have several arguments.
 
**Example:**

    -- Multiple arguments
    Do.parallel(
      FS.read("/etc/passwd"),
      FS.read(__filename)
    )(function(passwd, self)
      -- Do something
    end, errorHandler)

    -- Single argument
    local actions = {
      FS.read("/etc/passwd"),
      FS.read("__filename")
    }
    Do.parallel(actions)(function(results)
      -- Do something
    end, errorHandler)
 
### Do.chain(actions) {...}

Chains together several actions feeding the output of the first to the input of the second and the final output to the continuables callback.

**Example:**

    -- Multiple arguments
    Do.chain(
      FS.read(__filename),
      function(text)
        return FS.writeFile("newfile", text)
      end,
      function()
        return FS.stat("newfile")
      end
    )(function(stat)
      -- Do something
    end, errorHandler)

    -- Single argument
    local actions = {
      FS.readFile(__filename),
      function(text)
        return FS.writeFile("newfile", text)
      end,
      function()
        return FS.stat("newfile")
      end
    };
    Do.chain(actions)(function(stat)
      -- Do something
    end, errorHandler)

### Do.map(array, fn) {...}

Takes an array and does an array map over it using the async callback `fn`. The signature of `fn` is `function fn(item, callback, errback)` or any regular continuable.

**Example:**

    -- Direct callback filter
    local files = {'users.json', 'pages.json', 'products.json'}
    function loadFile(filename, callback, errback)
      FS.read(filename)(function(data)
        callback({filename, data})
      end, errback)
    end
    Do.map(files, loadFile)(function(contents)
      -- Do something
    end, errorHandler)
    
    -- continuable based filter
    local files = {'users.json', 'pages.json', 'products.json'}
    Do.map(files, FS.read)(function(contents)
      -- Do something
    end, errorHandler)

### Do.filter(array, fn) {...}

Takes an array and does an array filter over it using the async callback `fn`. The signature of `fn` is `function fn(item, callback, errback)` or any regular continuable.

**Example:**

    -- Direct callback filter
    local files = {'users.json', 'pages.json', 'products.json'}
    function isFile(filename, callback, errback)
      FS.stat(filename)(function(stat)
        callback(stat.is_file)
      end, errback)
    end
    Do.filter(files, isFile)(function(filtered_files)
      -- Do something
    end, errorHandler)

    -- Continuable based filter
    local files = {'users.json', 'pages.json', 'products.json'}
    function isFile(filename) return function(callback, errback)
      FS.stat(filename)(function(stat)
        callback(stat.is_file)
      end, errback)
    endend
    Do.filter(files, isFile)(function(filtered_files)
      -- Do something
    end, errorHandler)

### Do.filterMap(array, fn) {...}

Takes an array and does a combined filter and map over it.  If the result
of an item is undefined, then it's filtered out, otherwise it's mapped in.
The signature of `fn` is `function fn(item, callback, errback)` or any regular continuable.

**Example:**

    -- Direct callback filter
    local files = {'users.json', 'pages.json', 'products.json'}
    function checkAndLoad(filename, callback, errback)
      FS.stat(filename)(function(stat)
        if stat.is_file then
          loadFile(filename, callback, errback)
        else
          callback()
        end
      end, errback)
    end
    Do.filterMap(files, checkAndLoad)(function(filtered_files_with_data)
      -- Do something
    end, errorHandler)

    -- Continuable based filter
    local files = {'users.json', 'pages.json', 'products.json'}
    function checkAndLoad(filename)
      return function(callback, errback)
        FS.stat(filename)(function(stat)
          if stat.is_file then
            loadFile(filename, callback, errback)
          else
            callback()
          end
        end, errback)
      end
    end
    Do.filterMap(files, checkAndLoad)(function(filtered_files_with_data)
      -- Do something
    end, errorHandler)

## Using with luvit libraries

Do has a super nifty `Do.convert` function that takes a library and converts it to use Do style continuables.  For example, if you wanted to use `FS.readFile` and `FS.writeFile`, then you would do this:

    local FS = Do.convert(require('fs'), {'readFile', 'writeFile'})

Do will give you a copy of `fs` that has `readFile` and `writeFile` converted to Do style.  It's that easy!

### For library writers

All async functions in luvit follow a common interface:

    method(arg1, arg2, arg3, ..., callback)

Where `callback` is of the form:

    callback(err, result1, result2, ...)

This is done to keep luvit simple and to allow for interoperability between the various async abstractions like luvit continuables/fiber.

If you're writing a library, make sure to export all your async functions following the luvit interface.  Then anyone using your library can know what format to expect.

## Future TODOs

 - Write tests!
 - Make some sort of helper that makes it easy to call any function regardless of it's sync or async status.  This is tricky vs. promises since our return value is just a regular function, not an instance of something.

## Credits

 - Great thanks to [Tim Caswell](https://github.com/creationix) for [the `Do` library for node.js](https://github.com/creationix/do). This libray is a port of that to [luvit](https://github.com/luvit/luvit).

## License

Do is [licensed][] under the [MIT license][].

[MIT license]: http://opensource.org/licenses/MIT
