#!/usr/bin/env lua
--
-- Copyright (C) 2024-2025 Andreas MATTHIAS
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

local l2d = require('luals2dox')
local doc = l2d:new()
if not doc then
   return
end
local content = doc:render_file()
print(content)
