--
-- Copyright (C) 2024 Andreas MATTHIAS
--
-- This file is part of Luals2dox.
--
-- Luals2dox is free software: you can redistribute it and/or modify it
-- under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
--
-- Luals2dox is distributed in the hope that it will be useful, but
-- WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
-- General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with Luals2dox. If not, see <https://www.gnu.org/licenses/>.

--- @mainpage
--- @include{doc} Readme.md

local cjson = require('cjson')
local fstring = require('F')

local fs
local has_luaposix = pcall(require, 'posix')
if has_luaposix then
   local posix = require('posix')
   fs = {
      realpath = posix.realpath,
      getcwd = posix.getcwd,
      lstat_mtime = function(file)
         return posix.sys.stat.lstat(file).st_mtime
         end,
      isfile = function(file)
         if not file then
            return false
         else
            local stat = posix.stat(file)
            return stat and stat.type == 'regular'
         end
      end,
   }
else
   local path = require('pl.path')
   fs = {
      realpath = path.abspath,
      getcwd = path.currentdir,
      lstat_mtime = function(file)
         return path.attrib(file).modification
      end,
      isfile = path.isfile,
   }
end


local lpeg = require('lpeg')
local ws = lpeg.S(' \n\t') ^ 0

_G.luals2dox = {}
_G.luals2dox._CBO_ = '{' -- curly brace open
_G.luals2dox._CBC_ = '}' -- curly brace close


---Evaluate f-string.
---@param str string # F-string.
---@return string
local function f(str)
   str = str:gsub('}}', '{luals2dox._CBC_}') -- replace '}}'
   str = str:gsub('{{', '{luals2dox._CBO_}') -- replace '{{'
   return fstring(str)
end


---Strip whitespace.
---@param str string
---@return string
local function trim(str)
   str = str:gsub('^%s*', '')      -- strip leading space (on first line)
   str = str:gsub('\n%s*', '\n')   -- strip leading space (on following lines)
   str = str:gsub('\n%s*\n', '\n') -- newline
   return str
end


---Sanitize type definitions.
---These substitutions are a hack. They trick the C++ parser of doxygen
---into believing that certain characters are part of a type name instead
---of having a special meaning in C++.
---@param str string
---@return string
local function sanitize_type(str)
   str = str:gsub(',', '‚')
   str = str:gsub(':', '→')
   str = str:gsub('%.', '::')
   str = str:gsub('|', ' ¦ ')
   str = str:gsub('%[', '❲')
   str = str:gsub('%]', '❳')
   str = str:gsub('%{', '❴')
   str = str:gsub('%}', '❵')
   return str
end


---Sanitize type name of an function argument.
---@param str string
---@return string
local function sanitize_arg_type(str)
   str = sanitize_type(str)
   return str
end


---Sanitize return type name of a function.
---@param str string
---@return string
local function sanitize_return_type(str)
   str = sanitize_type(str)
   return str
end


---This class represents a filter for Doxygen.
---
---It reads (filters) a Lua file and writes a pseudo C++ file to stdout.
---Hereby the information of LuaLS' `doc.json` file is used to create
---the C++ file.
---
---See @ref map.
--- @include{doc} flowcharts.dox
---
---@class Doxy
local Doxy = {}


---Constructor.
---@return Doxy | nil
function Doxy:new()
   local t = {}
   setmetatable(t, self)
   self.__index = self
   Doxy.init(t)
   if t.args['list_config'] then
      return nil
   end
   return t
end


---Initializer.
---@private
---@return nil
function Doxy:init()
   self.arg_parser = require('luals2dox.args')
   self.args = self.arg_parser:parse() --[[@as table]] ---CLI arguments
   self:set_json_file()
   self:load_json_file()
   if self.args['list_config'] then
      self:list_config()
      return
   end
   if self:getOS() == 'Windows' then
      self.file_scheme = '^file:///' --- File scheme
      self.device_null = 'null' --- Device null
   else
      self.file_scheme = '^file://'
      self.device_null = '/dev/null'
   end
   self:set_lua_file()
   self:update_json()
end


---Info message written to stderr.
---@param str string
---@return nil
function Doxy:info(str)
   io.stderr:write(string.format('luals2dox: Warning: %s\n', str))
end


---Return name of Operating System.
---@return string
function Doxy:getOS()
   if package.config:sub(1, 1) == '\\' then
      return 'Windows'
   else
      return io.popen('uname -s', 'r'):read()
   end
end


---Set lua file (`self.lua_file`) with error checking.
---@return nil
function Doxy:set_lua_file()
   if self.args['file.lua'] == '' then
      self.arg_parser:error("missing argument 'file.lua'")
   end
   self.lua_file = fs.realpath(self.args['file.lua']) --[[@as string]] --Lua file name.
   self.lua_file = self:windows_drive_letter_lowercase(self.lua_file)
   if not fs.isfile(self.lua_file) then
      self.arg_parser:error(string.format('Lua file \'%s\' not found.', self.args['file.lua']))
   end
end


---Convert first character of `file` to lowercase.
---
---The file name must be an absolute path.
---In Windows the first character is the drive letter.
---In Linux the first character is a slash.
---@param file string # File name
---@return string
function Doxy:windows_drive_letter_lowercase(file)
   return file and file:sub(1, 1):lower() .. file:sub(2)
end


---Set json file (`self.json_file`) with error checking.
---@return nil
function Doxy:set_json_file()
   self.json_file = fs.realpath(self.args['json']) --[[@as string]] --JSON file name.
   if not fs.isfile(self.json_file) then
      self.arg_parser:error(string.format('JSON file \'%s\' not found.', self.args['json']))
   end
end


---Load json file in `self.doc_json`.
---@return nil
function Doxy:load_json_file()
   local fd = io.open(self.json_file)
   if not fd then
      self.arg_parser:error(string.format('Cannot open file \'%s\'.', self.args['json']))
   end
   ---@diagnostic disable-next-line:need-check-nil
   local text = fd:read('*all')
   self.doc_json = cjson.decode(text) --[[@as table]] --JSON data.
end


---List config settings on CLI and exit.
---@return nil
function Doxy:list_config()
   self:print_config_item('Binary', self.args.lua_language_server)
   self:print_config_item('Working directory', fs.getcwd())
   self:print_config_item('JSON file', self.json_file)
   for _, section in ipairs(self.doc_json) do
      if section.type == 'luals.config' then
         self:print_config_item('JSON root path', section.DOC)
         return
      end
   end
   self.arg_parser:error('Section \'luals.config\' missing in JSON file.')
end


---Print an item of config settings.
---@param description string
---@param value string
---@return nil
function Doxy:print_config_item(description, value)
   print(string.format('%-20s %s', description .. ':', value))
end


---Update json file if currently processed lua-file is newer than json-file.
---@return nil
function Doxy:update_json()
   local stat_lua = fs.lstat_mtime(self.lua_file)
   local stat_json = fs.lstat_mtime(self.json_file)
   if stat_json < stat_lua then
      os.rename(self.json_file, 'doc.json') -- LuaLS expects 'doc.json'.
      local ok, state, errno =
         os.execute(string.format('%s --doc_update > %s',
                                  self.args.lua_language_server,
                                  self.device_null))
      if not ok then
         os.rename('doc.json', self.json_file)
         self.arg_parser:error(string.format(
            'Updating JSON file failed (%s, %s).', state, errno))
      end
      os.rename('doc.json', self.json_file)
      self:load_json_file()
   end
end


---Decode URL: Replace hex numbers with characters.
---@param url string # URL
---@return string # URL.
function Doxy:urldecode(url)
   local hex2ch = function(hex)
      return string.char(tonumber(hex, 16))
   end
   local decoded_url, _ = url:gsub('%%(%x%x)', hex2ch)
   return decoded_url
end


---Unescape `@` characters.
---@param str string # Escaped string.
---@return string # Unescaped string.
function Doxy:unescape(str)
   str = str:gsub('\\@', '@')
   return str
end


---Return formatted description.
---@param str string # Description.
---@return string # Description.
function Doxy:description(str)
   str = str or ''
   str = self:unescape(str)
   str = str:gsub('\n%s*\n', '\n~~~~~~\n')
   str = str:gsub('\n', '\n/// ')
   return str
end


local function final_clean(content)
   content = content:gsub('/// \n', '')
   content = content:gsub('~~~~~~', '')
   return content
end


---Create pseudo C++ code for file `lua_file`.
---@return string
function Doxy:render_file()
   local content = ''
   if self.args.all_files then
      content = '/// @file\n\n'
   end
   content = content .. self:copy_comment_blocks()
   for _, section in ipairs(self.doc_json) do
      content = content .. self:render_section(section)
   end
   return final_clean(content)
end


---Render a top level section of the JSON table.
---@param section table # Section of JSON table.
---@return string
function Doxy:render_section(section)
   local content = ''
   if section.type == 'type' then
      content = content .. self:render_section_type(section)
   elseif section.type == 'variable' then
      content = content .. self:render_section_variable(section)
   end
   return content
end


---Return `true` if `file` is the currently processed lua file.
---@param file string # file name.
---@return boolean
function Doxy:is_current_lua_file(file)
   file = self:urldecode(file)
   file = file:gsub(self.file_scheme, '')
   file = fs.realpath(file)
   if file == self.lua_file then
      return true
   else
      return false
   end
end


---Render a top level `type` section of the JSON table.
---@param section table # Section of JSON table.
---@return string
function Doxy:render_section_type(section)
   local content = ''
   for _, subsection in ipairs(section.defines) do
      if self:is_current_lua_file(subsection.file) then
         if subsection.type == 'doc.class' then
            content = content .. self:render_doc_class(section)
         elseif subsection.type == 'doc.enum' then
            self:info(string.format('Enums not implemented.'))
         else
            self:info(string.format('Unknown section.defines.type: %s',
               subsection.type))
         end
      end
   end
   return content
end


---Render one or more `doc.class` sections of the JSON table.
---@param section table # Section of JSON table.
---@return string
function Doxy:render_doc_class(section)
   local content = ''
   for idx, _ in ipairs(section.defines) do
      content = content .. self:render_doc_class_definition(section, idx)
   end
   return content
end


---Render a `doc.class` section of the JSON table.
---@param section table # Section of JSON table.
---@param idx integer # Index of `section` array.
---@return string
function Doxy:render_doc_class_definition(section, idx)
   local definition = section.defines[idx]
   if not self:is_current_lua_file(definition.file) then
      return ''
   end
   ---@diagnostic disable: unused-local
   local classname = section.name
   local parent = self:get_inherited_classes(definition)
   local desc = self:description(section.rawdesc)
   local fields = ''
   for _, field in ipairs(section.fields) do
      fields = fields .. self:render_doc_class_field(field)
   end
   ---@diagnostic enable: unused-local
   local content = trim(f [[
      ///
      /// @class {classname}
      ///
      /// @brief
      /// {desc}
      {parent.templates}
      class {classname}{parent.classes} {{
      ~~~~~~
      {fields}
      }};
      ~~~~~~
   ]])
   return content
end


---Get inherited classes
---@param definition table # Section of JSON table.
---@return table
function Doxy:get_inherited_classes(definition)
   if not definition.extends then
      return {
         ['templates'] = '',
         ['classes'] = ''
      }
   end
   local templates = {}
   local derived = {}
   for _, super in ipairs(definition.extends) do
      if super.type == 'doc.extends.name' then
         derived[#derived + 1] = super.view
      elseif super.type == 'doc.type.table' then
         local template = super.fields[1].view:match('<(.*)>')
         local index_type = super.fields[1].name.view
         templates[#templates + 1] = template
         derived[#derived + 1] = string.format('Table<%s, %s>', index_type, template)
      else
         self:info(string.format('Unknown definition.extends.type: %s',
            super.type))
      end
   end
   local templates_str = ''
   if next(templates) then
      templates_str = 'template <typename ' .. table.concat(templates, ', typename ') .. '>'
   end
   local classes_str = ''
   if next(derived) then
      classes_str = ' : public ' .. table.concat(derived, ', public ')
   end
   return {
      ['templates'] = templates_str,
      ['classes'] = classes_str
   }
end


---Render a field of a `doc.class`.
---@param field table # Section of JSON table.
---@return string
function Doxy:render_doc_class_field(field)
   if not self:is_current_lua_file(field.file) then
      return ''
   end
   if field.type == 'setmethod' then
      return self:render_setmethod(field)
   elseif field.type == 'setfield' then
      return self:render_setfield(field)
   elseif field.type == 'doc.field' then
      return self:render_doc_field(field)
   else
      self:info(string.format('Unknown (doc.class) field.type: %s',
         field.type))
      return ''
   end
end


---Render field `setmethod`.
---@param field table # Section of JSON table.
---@return string
function Doxy:render_setmethod(field)
   if field.extends.type == 'function' then
      return self:render_class_method(field)
   else
      self:info(string.format('Unknown (setmethod) field.extends.type: %s',
         field.extends.type))
      return ''
   end
end


---Render a class method.
---@param field table # Section of JSON table.
---@return string
function Doxy:render_class_method(field)
   ---@diagnostic disable: unused-local
   local name = field.name
   local desc = self:description(field.rawdesc)
   local args = self:get_args(field.extends.args)
   local returns = self:get_returns(field.extends.returns)
   local deprecated = field.deprecated and '@deprecated' or ''
   local async = field.async and '@async' or ''
   local access = field.visible
   local template_def = ''
   if next(args.templates) then
      template_def = string.format('template <typename %s>',
         table.concat(args.templates, ', typename '))
   end
   ---@diagnostic enable: unused-local
   local content = trim(f [[
      /// {async}
      /// {deprecated}
      /// @brief
      /// {desc}
      {args.description}
      {returns.description}
      {access}:
      {template_def}
      {returns.list}{name}{args.list};
      ~~~~~~
   ]])
   return content
end


---Render section `doc.field`.
---@param field table # Section of JSON table.
---@return string
function Doxy:render_doc_field(field)
   if field.extends.type == 'doc.type' then
      return self:render_doc_field_variable(field)
   else
      self:info(string.format('Unknown (doc.field) field.extends.type: %s',
         field.extends.type))
      return ''
   end
end


---Render a variable of a `doc.field`.
---@param field table # Section of JSON table.
---@return string
function Doxy:render_doc_field_variable(field)
   return self:render_setfield_variable(field)
end


---Render a `setfield`.
---@param field table # Section of JSON table.
---@return string
function Doxy:render_setfield(field)
   if field.extends.type == 'function' then
      return self:render_setfield_function(field)
   else
      return self:render_setfield_variable(field)
   end
end


---Render a function of a `setfield`.
---@param field table # Section of JSON table.
---@return string
function Doxy:render_setfield_function(field)
   ---@diagnostic disable: unused-local
   local name = field.name
   local desc = self:description(field.rawdesc)
   local args = self:get_args(field.extends.args)
   local returns = self:get_returns(field.extends.returns)
   local deprecated = field.extends.deprecated and '@deprecated' or ''
   local async = field.extends.async and '@async' or ''
   local access = field.visible or ''
   local template_def = ''
   if next(args.templates) then
      template_def = string.format('template <typename %s>',
         table.concat(args.templates, ', typename '))
   end
   ---@diagnostic enable: unused-local
   local content = trim(f [[
      /// {async}
      /// {deprecated}
      /// @brief
      /// {desc}
      {args.description}
      {returns.description}
      {access}:
      {template_def}
      {returns.list}{name}{args.list};
      ~~~~~~
   ]])
   return content
end


---Render a variable of a `setfield`.
---@param field table # Section of JSON table.
---@return string
function Doxy:render_setfield_variable(field)
   ---@diagnostic disable: unused-local
   local name = field.name
   local fieldtype = sanitize_arg_type(field.extends.view)
   local desc = self:description(field.rawdesc)
   local access = field.visible
   ---@diagnostic enable: unused-local
   if not self.args.with_index and name == '__index' then
      return ''
   end
   local content = trim(f [[
   /// @brief
   /// {desc}
   {access}:
   {fieldtype} {name};
   ~~~~~~
   ]])
   return content
end


---Render a top level `variable` section.
---@param section table # Section of JSON table.
---@return string
function Doxy:render_section_variable(section)
   local content = ''
   for _, subsection in ipairs(section.defines) do
      if self:is_current_lua_file(subsection.file) then
         if subsection.type == 'setglobal' then
            content = content .. self:render_setglobal(subsection, section.name)
            -- elseif subsection.type == 'doc.enum' then
            --    content = content .. self:render_doc_enum(subsection, section.name)
         end
      end
   end
   return content
end


---Render a `setglobal` section.
---@param section table # Section of JSON table.
---@param name string # Name of function or variable.
function Doxy:render_setglobal(section, name)
   local extype = section.extends.type
   if extype == 'function' then
      return self:render_function(section, name)
   else
      -- variables
      return self:render_variable(section, name)
   end
end


---Render a `setglobal` function.
---@param section table # Section of JSON table
---@param name string # Function name.
---@return string
function Doxy:render_function(section, name)
   ---@diagnostic disable: unused-local
   local func_name = name
   local extends = section.extends
   local desc = self:description(extends.rawdesc)
   local args = self:get_args(extends.args)
   local returns = self:get_returns(extends.returns)
   local deprecated = extends.deprecated and '@deprecated' or ''
   local async = extends.async and '@async' or ''
   local template_def = ''
   if next(args.templates) then
      template_def = string.format('template <typename %s>',
         table.concat(args.templates, ', typename '))
   end
   ---@diagnostic enable: unused-local
   local content = trim(f [[
      /// {async}
      /// {deprecated}
      /// @brief
      /// {desc}
      {args.description}
      {returns.description}
      {template_def}
      {returns.list}{func_name}{args.list};
      ~~~~~~
   ]])
   return content
end


---Render function arguments.
---@param args table # Section of JSON table.
---@return table
function Doxy:get_args(args)
   local description = ''
   local args_list = ''
   local templates = {}
   -- local generic_list = {}
   if args then
      local tmp = {}
      for _, arg in ipairs(args) do
         local res = self:get_arg(arg)
         if res then
            description = description .. res.description
            tmp[#tmp + 1] = res.arg
            templates[#templates + 1] = res.template
         end
      end
      args_list = '(' .. table.concat(tmp, ', ') .. ')'
   end
   return {
      ['description'] = description,
      ['list'] = args_list,
      ['templates'] = templates
   }
end


---Render one function argument.
---@param arg table # Section of JSON table.
---@return table | nil
function Doxy:get_arg(arg)
   local name = arg.name
   if not name then
      name = arg.type --variable args `...` do not have a name.
   end
   local argtype = sanitize_arg_type(arg.view)
   ---@diagnostic disable:unused-local
   local desc = arg.rawdesc or ''
   ---@diagnostic enable:unused-local
   if name ~= 'self' then
      local template, typedef = self:get_template_parameter(argtype)
      return {
         ['description'] = f '/// @param {name} ({typedef}) {desc}\n',
         ['arg'] = string.format('%s %s', typedef, name),
         ['template'] = template
      }
   else
      return nil
   end
end


---Render function return values.
---@param returns table # Section of JSON table.
---@return table
function Doxy:get_returns(returns)
   local description = ''
   local args_list = ''
   if returns then
      local args = {}
      for _, param in ipairs(returns) do
         local res = self:get_return(param)
         description = description .. res.description
         args[#args + 1] = res.arg
      end
      -- Here table.concat() uses a "low single comma quotation mark" instead
      -- of a "comma". This is a hack because "comma" has a special meaning
      -- for the C++ parser of doxygen.
      args_list = '(' .. table.concat(args, '‚ ') .. ') '
   end
   return {
      ['description'] = description,
      ['list'] = args_list
   }
end


---Render one function return value.
---@param ret table # Section of JSON table.
---@return table
function Doxy:get_return(ret)
   ---@diagnostic disable: unused-local
   local view = ''
   local _ = nil
   if ret.view then
      _, view = self:get_template_parameter(ret.view)
   end
   local desc = ret.rawdesc or ''
   ---@diagnostic enable: unused-local
   local description = f '/// @returns ({view}) {desc}\n'
   if view:match('^fun%(') then
      view = 'function'
   end
   return {
      ['description'] = sanitize_return_type(description),
      ['arg'] = sanitize_return_type(view)
   }
end


---Return template parameter and argument type of `arg`.
---
---This function basically reshuffles the type definition as follow.
---  * `<T>` => `T, T`
---  * `<T>[]` => `T, T[]`
---  * `integer` => `nil, integer`
---
---@param arg string # Argument type.
---@return string | nil # Template parameter.
---@return string # Argument type.
function Doxy:get_template_parameter(arg)
   local template, postfix = arg:match('^<(.*)>(.*)')
   if template then
      arg = template .. (postfix or '')
   end
   return template, arg
end


---Render a `setglobal` variable.
---@param section table # Section of JSON table.
---@param name string # Variable name.
---@return string
function Doxy:render_variable(section, name)
   local extends = section.extends
   ---@diagnostic disable: unused-local
   local var_name = name
   local vartype = sanitize_arg_type(extends.view)
   local desc = self:description(extends.rawdesc)
   ---@diagnostic enable: unused-local
   local content = trim(f [[
      /// @brief
      /// {desc}
      {vartype} {name};
      ~~~~~~
      ]])
   return content
end


--- Captures comment without comment sign "`---`".
local comment_pattern = (
   ws * lpeg.P('---') *
   ws * lpeg.C(lpeg.P(1) ^ 0))


---Copy comment blocks.
---
---Comment blocks are one or more comment lines that start and
---end with a blank line. For the very first comment block of
---a file the starting blank line is optional.
function Doxy:copy_comment_blocks()
   local function is_blank(line)
      return line:match('^%s*$')
   end
   local fd = assert(io.open(self.lua_file, 'r'))
   local content = ''
   local block = ''
   local block_started = true
   for line in fd:lines() do
      if block_started then
         local comment = comment_pattern:match(line)
         if comment then
            ---comment line
            if comment == '' then
               block = block .. '/// ~~~~~~\n'
            else
               block = block .. f '/// {comment}\n'
            end
         elseif is_blank(line) then
            ---blank line
            if block ~= '' then
               content = content .. block .. '~~~~~~\n'
            end
            block = ''
         else
            ---code line
            block = ''
            block_started = false
         end
      elseif is_blank(line) then
         block_started = true
      end
   end
   content = content .. block -- If EOF follows comment block immediately.
   return content
end


return Doxy
