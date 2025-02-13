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

local argparse = require('argparse')

---Parser for CLI arguments.
---@class ArgParser
---@field option fun(self, string):ArgParser # Option.
---@field argument fun(self, string):ArgParser # Argument.
---@field description fun(self, string):ArgParser # Description.
---@field args fun(self, integer):ArgParser # Number of arguments.
---@field default fun(self, any):ArgParser # Default value.
---@field hidden fun(self, boolean):ArgParser # Hide option.
---@field show_default fun(self, boolean):ArgParser # Show default value.
---@field parse fun(self):table # Parse arguments.
---@field error fun(self, string):nil # Error message.
local ArgParser = argparse()
   :name('luals2dox')
   :description('Doxygen filter for lua files composed with LuaLS annotations.')
   :epilog('For more info, see http://github.com/AndreasMatthias/Luals2dox')

ArgParser:option('-a --all-files')
   :description('Document all files. This adds @file to each file.')
   :args(0)
   :default(false)

ArgParser:option('-j --json')
   :description('LuaLS JSON file.')
   :args(1)
   :default('./doc.json')
   :hidden(true)

ArgParser:option('--with-index')
   :description('Include documentation of "__index".')
   :args(0)
   :hidden(true)
   :default(false)

ArgParser:option('-l --list-config')
   :description('List configuration.')
   :args(0)
   :default(false)

ArgParser:option('--lua-language-server')
   :description('Path of lua-language-server')
   :args(1)
   :default('lua-language-server')

ArgParser:argument('file.lua')
   :description('Input file name.')
   :default('')
   :show_default(false)

return ArgParser
