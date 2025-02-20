require('busted.runner')({output = 'utfTerminal'})
assert:set_parameter('TableFormatLevel', -1)
print()

package.path = '../src/?/init.lua;../src/?.lua;' .. package.path

local helper = require('helper')

local pretty = require('pl.pretty')
local function pp(t)
   print(pretty.write(t))
end

-- Busted has read its CLI arguments already. So we remove
-- them because they would confuse luals2dox.
for idx = 1, #arg do
   arg[idx] = nil
end


local function test(cli_args)
   -- Reset arg.
   for i = 1, #arg do
      arg[i] = nil
   end
   -- Set up CLI arguments.
   for _, val in ipairs(cli_args) do
      arg[#arg + 1] = val
   end
   -- Mock error function of argparse.
   local args = require('luals2dox.args')
   getmetatable(args).error = function(self, msg) ---@diagnostic disable-line: unused-local
      error(msg)
   end
   -- Run luals2dox.
   local l2d = require('luals2dox')
   l2d:new()
end


describe('CLI arguments:', function()
   it('Lua file missing/not found', function()
      helper.remove_file('doc.json')
      helper.copy_file('json/doc.json', 'doc.json')
      assert.has_error(
         function() test({}) end,
         "missing argument 'file.lua'")
      assert.has_error(
         function() test({'file_does_not_exist.lua'}) end,
         "Lua file 'file_does_not_exist.lua' not found.")
   end)

   it('--list-config', function()
      helper.remove_file('doc.json')
      helper.copy_file('json/empty.json', 'doc.json')
      local print_stub = stub(_G, 'print')
      assert.has_no_error(
         function() test({'-l'}) end)
      assert.has_no_error(
         function() test({'--list-config'}) end)
      helper.remove_file('doc.json')
      helper.copy_file('json/doc.json', 'doc.json')
      assert.has_no_error(
         function() test({'-l'}) end)
      print_stub:revert()
   end)

   it('JSON file not found', function()
      helper.remove_file('doc.json')
      assert.has_error(
         function() test({'./var/var-01.lua'}) end,
         "JSON file './doc.json' not found.")
   end)

   it('Cannot open JSON file', function()
      local function test_here()
         helper.remove_file('doc.json')
         helper.copy_file('json/doc.json', 'doc.json')
         arg[1] = './var/var-01.lua'
         -- Mock error function of argparse.
         local args = require('luals2dox.args')
         ---@diagnostic disable-next-line: unused-local
         getmetatable(args).error = function(self, msg)
            error(msg)
         end
         -- Run luals2dox.
         local l2d = require('luals2dox')
         local doxy = assert(l2d:new())
         helper.remove_file('doc.json')
         doxy:load_json_file()
      end

      assert.has_error(
         function() test_here() end,
         "Cannot open file './doc.json'.")
   end)

   it('Update JSON file', function()
      -- For code coverage statistics we want to run the part of the code
      -- that updated `doc.json`. This is the only reason for this test.
      helper.remove_file('doc.json')
      helper.copy_file('json/doc.json', 'doc.json')
      local tmp_lua_file = 'tmp_file.lua'
      io.open(tmp_lua_file, 'w'):close()

      assert.has_no_error(
         function() test({tmp_lua_file}) end)
      helper.remove_file(tmp_lua_file)
   end)

   it('--lua-language-server', function()
      helper.remove_file('doc.json')
      helper.copy_file('json/doc.json', 'doc.json')
      local tmp_lua_file = 'var/tmp_file.lua'
      io.open(tmp_lua_file, 'w'):close()
      assert.error_matches(
         function()
            test({'--lua-language-server', 'wrong-luals-binary', tmp_lua_file})
         end,
         'Updating JSON file failed %(exit, %d+%).')
      helper.remove_file(tmp_lua_file)
   end)

   it('--all-files', function()
      -- See tests in test.lua
   end)
end)
