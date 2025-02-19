require('busted.runner')({output = 'utfTerminal'})
assert:set_parameter('TableFormatLevel', -1)
print()

package.path = '../src/?/init.lua;../src/?.lua;' .. package.path

local helper = require('helper')

local function pp(t)
   local pretty = require('pl.pretty')
   print(pretty.write(t))
end

-- Busted has read its CLI arguments already. So we remove
-- them because they would confuse luals2dox.
for idx = 1, #arg do
   arg[idx] = nil
end

local say = require('say')
local diff = require('diff') -- https://bitbucket.org/spilt/luadiffer
local lfs = require('lfs')

local checking_file = ''

assert['strings_equal'] = nil
local function strings_equal(_, argument)
   local actual = argument[1]
   local expected = argument[2]
   local ok, err = pcall(function() assert.are_same(expected, actual) end)
   if ok then
      return true
   else
      print(err)
      print(string.format('\027[1;34mDiff: expected->actual (%s)\027[1;0m', checking_file))
      diff(expected, actual):print()
      return false
   end
end

say:set('assertion.string_equal.positive', 'Expected objects to be the same.')
assert:register('assertion', 'strings_equal', strings_equal,
   'assertion.strings_equal.positive',
   'assertion.strings_equal.negative')


-- Copy json file.
os.remove('doc.json')
helper.copy_file('json/doc.json', 'doc.json')


---@param lua_filename string # Lua file name.
---@param cli_args? table # CLI arguments.
local function set_args(lua_filename, cli_args)
   cli_args = cli_args or {}
   -- Reset arg.
   for i = 1, #arg do
      arg[i] = nil
   end
   -- Set up CLI arguments.
   for _, val in ipairs(cli_args) do
      arg[#arg + 1] = val
   end
   arg[#arg + 1] = lua_filename
end

---@param lua_filename string # Lua file name.
---@param cli_args? table # CLI arguments.
local function check_file(lua_filename, cli_args)
   cli_args = cli_args or {}
   set_args(lua_filename, cli_args)
   local cpp_filename = lua_filename:gsub('.lua', '.cpp')
   local cpp_file = io.open(cpp_filename, 'r')
   checking_file = cpp_filename
   if not cpp_file then
      error(string.format('Internal Error: File `%s` not found.', cpp_filename))
   end
   local l2d = require('luals2dox')
   local doc = l2d:new()
   local actual = doc:render_file() ---@diagnostic disable-line: need-check-nil
   local expected = cpp_file:read('*all')
   assert.strings_equal(actual, expected)
end


describe('Variables:', function()
   it('Simple Types', function()
      check_file('var/var-01.lua')
      check_file('var/var-02.lua')
      check_file('var/var-03.lua')
   end)
   it('Arrays', function()
      check_file('var/arr-01.lua')
      check_file('var/arr-02.lua')
   end)
   it('Dictionaries', function()
      check_file('var/dict-01.lua')
      check_file('var/dict-02.lua')
   end)
   it('Unions. #skip', function()
      check_file('var/union-01.lua') --TODO
   end)
end)

describe('Functions:', function()
   it('Arguments', function()
      check_file('func/func-args-01.lua')
      check_file('func/func-args-02.lua')
   end)
   it('Returns', function()
      check_file('func/func-rets-01.lua')
   end)
   it('Async', function()
      check_file('func/func-async-01.lua')
   end)
   it('Deprecated', function()
      check_file('func/func-depr-01.lua')
   end)
end)

describe('Classes:', function()
   it('Simple', function()
      check_file('class/class-01.lua')
      check_file('class/class-02.lua')
      check_file('class/class-03.lua')
      check_file('class/class-04.lua')
      check_file('class/class-05.lua')
      check_file('class/class-06.lua')
      check_file('class/class-07.lua')
   end)
   it('Access', function()
      check_file('class/class-access-01.lua')
      check_file('class/class-access-02.lua')
   end)
   it('Deprecated', function()
      check_file('class/class-depr-01.lua')
   end)
   it('Derived', function()
      check_file('class/class-derived-01.lua')
      check_file('class/class-derived-02.lua')
   end)
end)

describe('Generic:', function()
   it('Simple types', function()
      check_file('generic/generic-01.lua')
      check_file('generic/generic-02.lua')
      check_file('generic/generic-03.lua')
   end)
end)

describe('Misc:', function()
   it('Simple types', function()
      check_file('misc/m01.lua')
   end)
end)

describe('CLI arguments:', function()
   it('--all-files', function()
      check_file('misc/m02.lua', {'-a'})
      check_file('misc/m02.lua', {'--all-files'})
      check_file('misc/m03.lua', {})
   end)
end)
