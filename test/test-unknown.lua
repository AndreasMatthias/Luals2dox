require('busted.runner')({output = 'utfTerminal'})
print()

package.path = '../src/?/init.lua;../src/?.lua;' .. package.path

local helper = require('helper')
local cjson = require('cjson')

local function pp(t)
   local pretty = require('pl.pretty')
   print(pretty.write(t))
end

-- Busted has read its CLI arguments already. So we remove
-- them because they would confuse luals2dox.
for idx = 1, #arg do
   arg[idx] = nil
end

local path = require('pl.path')

local function make_json_file(content)
   -- Read JSON file
   local fd = assert(io.open('json/doc.json'))
   local json = cjson.decode(fd:read('*a'))
   fd:close()
   -- Append JSON data
   json[#json + 1] = content
   -- Write JSON file
   helper.remove_file('doc.json')
   fd = assert(io.open('doc.json', 'w'))
   fd:write(cjson.encode(json))
   fd:close()
end

local function set_arg()
   for i = 1, #arg do
      arg[i] = nil
   end
   arg[#arg + 1] = 'var/var-01.lua'
end

local function test(json, warning_msg)
   make_json_file(json)
   set_arg()
   local l2d = require('luals2dox')
   local sp = spy.on(l2d, 'info')
   local doc = assert(l2d:new())
   doc:render_file()
   assert.spy(sp).was.called_with(doc, warning_msg)
end


local function getOS()
   if package.config:sub(1, 1) == '\\' then
      return 'Windows'
   else
      return io.popen('uname -s', 'r'):read()
   end
end


local function fileURL(rel_path)
   if getOS() == 'Windows' then
      local cwd = path.abspath('.')
      cwd = cwd:sub(1, 1):lower() .. cwd:sub(2)
      cwd = cwd:gsub('\\', '/')
      return 'file:///' .. cwd .. '/' .. rel_path
   else
      local cwd = path.abspath('.')
      return 'file://' .. cwd .. '/./' .. rel_path
   end
end


describe('JSON file:', function()
   assert:set_parameter('TableFormatLevel', 0)

   it('Unknown section.defines.type', function()
      test(
         {
            ['defines'] = {
               {
                  ['file'] = fileURL('var/var-01.lua'),
                  ['type'] = 'XXX'
               }
            },
            ['type'] = 'type'
         },
         'Unknown section.defines.type: XXX')
   end)

   it('Unknown (doc.class) field.type', function()
      test(
         {
            ['defines'] = {
               {
                  ['file'] = fileURL('var/var-01.lua'),
                  ['type'] = 'doc.class'
               }
            },
            ['fields'] = {
               {
                  ['file'] = fileURL('var/var-01.lua'),
                  ['type'] = 'XXX'
               }
            },
            ['type'] = 'type'
         },
         'Unknown (doc.class) field.type: XXX')
   end)

   it('Unknown (setmethod) field.extends.type', function()
      test(
         {
            ['defines'] = {
               {
                  ['file'] = fileURL('var/var-01.lua'),
                  ['type'] = 'doc.class'
               }
            },
            ['fields'] = {
               {
                  ['file'] = fileURL('var/var-01.lua'),
                  ['type'] = 'setmethod',
                  ['extends'] = {
                     ['type'] = 'XXX'
                  }
               }
            },
            ['type'] = 'type'
         },
         'Unknown (setmethod) field.extends.type: XXX')
   end)

   it('Unknown (doc.field) field.extends.type', function()
      test(
         {
            ['defines'] = {
               {
                  ['file'] = fileURL('var/var-01.lua'),
                  ['type'] = 'doc.class'
               }
            },
            ['fields'] = {
               {
                  ['file'] = fileURL('var/var-01.lua'),
                  ['type'] = 'doc.field',
                  ['extends'] = {
                     ['type'] = 'XXX'
                  }
               }
            },
            ['type'] = 'type'
         },
         'Unknown (doc.field) field.extends.type: XXX')
   end)

   it('Enum (type)', function()
      test(
         {
            ['defines'] = {
               {
                  ['file'] = fileURL('var/var-01.lua'),
                  ['type'] = 'doc.enum'
               }
            },
            ['type'] = 'type'
         },
         'Enums not implemented.')
   end)

   it('Unknown definition.extends.type', function()
      test(
         {
            ['defines'] = {
               {
                  ['file'] = fileURL('var/var-01.lua'),
                  ['type'] = 'doc.class',
                  ['extends'] = {
                     {
                        ['type'] = 'XXX'
                     }
                  }
               }
            },
            ['fields'] = {
            },
            ['type'] = 'type'
         },
         'Unknown definition.extends.type: XXX')
   end)
end)
