-- This file is just a mess of examples of how to use the library.

local Do = require('./do')
local FS = require('fs')
local Timer = require('timer')
local dump = require('utils').dump
local string = require('string')
local table = require('table')

local FS = Do.convert(require('fs'), {"readFile", "stat", "readdir"})
local http = Do.convert(require('http'), {'cat'})

-- local sys = require('sys')

function debug(message, showHidden)
  print("DEBUG: " .. dump(message) .. ', ' .. dump(showHidden))
end
function showResults(...)
  print("results: " .. dump{...})
end
function showError(...)
  print("ERROR: " .. dump{...})
end

FS.readdir('.')(showResults, showError)

-- A very slow error to make sure that no success message is emitted if there
-- is an error anywhere.
function slowError()
  return function(callback, errback)
    Timer.setTimeout(500, function()
      errback("Yikes!")
    end)
  end
end

Do.parallel{
  function(cb, eb)
    print("f1")
    cb("param1")
  end,
  function(cb, eb)
    print("f2")
    cb("param2")
  end
}(showResults, showError)

Do.parallel(
  function(cb, eb)
    print("f1")
    cb("param1")
  end,
  function(cb, eb)
    print("f2")
    cb("param2")
  end
)(showResults, showError)

Do.parallel(
  FS.readFile(__filename),
  slowError()
)(showResults, showError)

Do.parallel(
  FS.readFile(__filename)
)(showResults, showError)

Do.parallel(
  Do.parallel({
    FS.readFile(__filename),
    FS.readFile(__filename)
  }),
  FS.readFile(__filename)
)(showResults, showError)

-- Filter callback that only let's files through by using stat
function onlyFiles(filename, callback, errback)
  FS.stat(filename)(function (stat)
    callback(stat.is_file)
  end, errback)
end

-- Filter that replaces a filename with the pair of filename and content
function markedRead(filename, callback, errback)
  FS.readFile(filename)(function (data)
    if #data < 10 then
      errback(filename .. " is too small!")
    else
      callback({filename, data})
    end
  end, errback)
end

function checkAndLoad(filename, callback, errback)
  FS.stat(filename)(function (stat)
    if stat.is_file then
      markedRead(filename, callback, errback)
    else
      callback()
    end
  end, errback)
end

local a = FS.readdir(__dirname)
print("a " .. dump(a))

function loaddir(path)
  return function (callback, errback)
    FS.readdir(path)(function(filenames)
      Do.filter(filenames, onlyFiles)(function(filenames)
        Do.map(filenames, markedRead)(callback, errback)
      end, errback)
    end, errback)
  end
end
loaddir(__dirname)(debug, showError)

function fastLoaddir(path)
  return function(callback, errback)
    FS.readdir(path)(function(filenames)
      Do.filterMap(filenames, checkAndLoad)(callback, errback)
    end, errback)
  end
end
fastLoaddir(__dirname)(debug, showError)


local function split(str, sep)
  local words = {}
  local word_start = 1
  while true do
    local first, last = string.find(str, sep, word_start)
    if first == nil then
      if word_start <= #str then
        words[#words + 1] = string.sub(str, word_start)
      end
      break
    end
    if first > word_start then
      words[#words + 1] = string.sub(str, word_start, first - 1)
    end
    word_start = last + 1
  end
  return words
end

local function filter(array, predicate)
  local filtered = {}
  for _, val in ipairs(array) do
    if predicate(val) then
      filtered[#filtered + 1] = val
    end
  end
  return filtered
end

function getKeywords(text)
  return function (callback, errback)
    Timer.setTimeout(0, function()
      local last
      local words = filter(table.sort(split(string.gsub(
        string.lower(text), '[^a-z ]', ''), ' ')),
        function(word)
          if last == word then
            return false
          end
          last = word
          return #word > 2
        end)
      callback(words)
    end)
  end
end

Do.chain(
  FS.readFile(__filename),
  getKeywords
)(debug, showError)

Do.chain(
  FS.readdir(__dirname),
  function(filenames)
    return Do.filterMap(filenames, checkAndLoad)
  end
)(debug, showError)

-- Use the new continuable style map
local files = {"example.lua", "README.md"}
Do.map(files, FS.readFile)(debug, showError)

function safeLoad(filename)
  return function (callback, errback)
    FS.stat(filename)(function (stat)
      if stat.is_file then
        FS.readFile(filename)(callback, errback)
      else
        callback()
      end
    end, errback)
  end
end

-- Use filterMap with new continuable based filter
FS.readdir(__dirname)(function (list)
  Do.filterMap(list, safeLoad)(debug, showError)
end, showError)
