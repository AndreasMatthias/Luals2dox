require('busted.runner')({output = 'utfTerminal'})
assert:set_parameter('TableFormatLevel', -1)
print()

local posix = require('posix')

local pretty = require('pl.pretty')
local function pp(t)
   print(pretty.write(t))
end

-- Busted has read its CLI arguments already. So we remove
-- them because they would confuse luals2dox.
for idx = 1, #arg do
   arg[idx] = nil
end


local function test(cli_args, json_file, do_print)
   -- Copy json file.
   posix.unlink('./doc.json')
   posix.link(json_file, './doc.json')
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
      assert.has_error(
         function() test({}, './json/doc.json') end,
         "missing argument 'file.lua'")
      assert.has_error(
         function() test({'file_does_not_exist.lua'}, './json/doc.json') end,
         "Lua file 'file_does_not_exist.lua' not found.")
   end)

   it('--list-config', function()
      local print_stub = stub(_G, 'print')
      assert.has_error(
         function() test({'-l'}, './json/empty.json') end,
         "Section 'luals.config' missing in JSON file.")
      assert.has_error(
         function() test({'--list-config'}, './json/empty.json') end,
         "Section 'luals.config' missing in JSON file.")
      assert.has_no_error(
         function() test({'-l'}, './json/doc.json') end)
      print_stub:revert()
   end)

   it('JSON file not found', function()
      assert.has_error(
         function() test({}, './does/not/exist/doc.json') end,
         "JSON file './doc.json' not found.")
   end)

   it('Cannot open JSON file', function()
      posix.unlink('./doc.json')
      local json_file = './json/access.json'
      io.open(json_file, 'w'):close()
      posix.chmod(json_file, '000')
      assert.has_error(
         function() test({}, './json/access.json') end,
         "Cannot open file './doc.json'.")
      posix.unlink(json_file)
   end)

   it('Update JSON file', function()
      -- For code coverage statistics we want to run the part of the code
      -- that updated `doc.json`. This is the only reason for this test.
      local tmp_lua_file = './var/_tmp_file.lua'
      posix.sleep(1)
      io.open('./var/_tmp_file.lua', 'w'):close()
      assert.has_no_error(
         function() test({tmp_lua_file}, './json/doc.json') end)
      posix.unlink(tmp_lua_file)
   end)

   it('--lua-language-server', function()
      local tmp_lua_file = './var/_tmp_file.lua'
      posix.sleep(1)
      io.open('./var/_tmp_file.lua', 'w'):close()
      assert.has_error(
         function()
            test({'--lua-language-server', 'wrong-binary', tmp_lua_file},
               './json/doc.json')
         end,
         string.format('Updating JSON file failed (exit, 127).'))
      posix.unlink(tmp_lua_file)
   end)

   it('--all-files', function()
      -- See tests in test.lua
   end)
end)
