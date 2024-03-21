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
local posix = require('posix')
local fstring = require('F')

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
   self:set_lua_file()
   self:update_json()
end


---Info message written to stderr.
---@param str string
---@return nil
function Doxy:info(str)
   io.stderr:write(string.format('luals2dox: Warning: %s\n', str))
end


---Set lua file (`self.lua_file`) with error checking.
---@return nil
function Doxy:set_lua_file()
   if self.args['file.lua'] == '' then
      self.arg_parser:error("missing argument 'file.lua'")
   end
   self.lua_file = posix.realpath(self.args['file.lua']) --[[@as string]] --Lua file name.
   if not self.lua_file then
      self.arg_parser:error(string.format('Lua file \'%s\' not found.', self.args['file.lua']))
   end
end


---Set json file (`self.json_file`) with error checking.
---@return nil
function Doxy:set_json_file()
   self.json_file = posix.realpath(self.args['json']) --[[@as string]] --JSON file name.
   if not self.json_file then
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
   self:print_config_item('Working directory', posix.getcwd())
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
   local stat_lua = posix.sys.stat.lstat(self.lua_file)
   local stat_json = posix.sys.stat.lstat(self.json_file)
   if stat_json.st_mtime < stat_lua.st_mtime then
      os.rename(self.json_file, 'doc.json') -- LuaLS expects 'doc.json'.
      local ok, state, errno =
         os.execute(string.format('%s --doc_update > /dev/null', self.args.lua_language_server))
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
   content = content .. self:copy_doxy_commands()
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


---Returns `true` if `file` is the currently processed lua file.
---@param file string # file name.
---@return boolean
function Doxy:is_current_lua_file(file)
   file = self:urldecode(file)
   file = file:gsub('^file://', '')
   file = posix.realpath(file)
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


---Copy commands (chunks) directly for lua file.
---
---This is for doxygen commands (markups) that are not included in the json file,
---but copied directly from the lua file.
---@return string
function Doxy:copy_doxy_commands()
   local fd = assert(io.open(self.lua_file, 'r'))
   local content = ''
   for _, cmd in ipairs({'@file', '@defgroup', '@addtogroup', '@mainpage'}) do
      content = content .. self:copy_doxy_command(fd, cmd)
   end
   fd:close()
   return content
end


---Copy doxygen command from lua file.
---@param fd file* # File descriptor.
---@param command string # Doxygen command.
---@return string
function Doxy:copy_doxy_command(fd, command)
   local content = ''
   local text
   local continue = false
   fd:seek('set')
   for line in fd:lines() do
      text, continue = self:copy_doxy_command_2(line, continue, command)
      content = content .. text
   end
   if content ~= '' then
      content = content .. '~~~~~~\n'
   end
   return trim(content)
end


--- Captures comment without comment sign "`---`".
local comment_pattern = (
   ws * lpeg.P('---') *
   ws * lpeg.C(lpeg.P(1) ^ 0))


---Helper function for copy_doxy_command_defgroup().
---@return string
---@return boolean
function Doxy:copy_doxy_command_2(line, continue, command)
   if not continue then
      local command_pattern = self:make_pattern(command)
      local capture = command_pattern:match(line)
      if capture then
         local content = f '/// {command}{capture}\n'
         return content, true
      else
         return '', false
      end
   else
      local capture = comment_pattern:match(line)
      if capture == '' then
         capture = '~~~~~~'
      end
      if capture then
         local content = f '/// {capture}\n'
         return content, true
      else
         return '', false
      end
   end
end


---Return lpeg pattern for doxygen command.
---@param command string # Doxygen command.
---@return Pattern
function Doxy:make_pattern(command)
   return (ws * lpeg.P('---') *
      ws * lpeg.P(command) *
      (ws * lpeg.C(lpeg.P(1) ^ 0)) ^ -1)
end


return Doxy
